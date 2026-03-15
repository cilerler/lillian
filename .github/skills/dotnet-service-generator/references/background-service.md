# Background Service Pattern

Extends `WorkerBackgroundService<TSettings>` for scheduled/continuous background work.

## File Structure

```
Services/{ServiceName}/
├── Contracts/
│   └── I{ServiceName}.cs       # Optional - if interface needed
├── Models/                      # DTOs, records
├── Validators/                  # Custom validation attributes
├── Exceptions/                  # Custom exceptions
├── Constants.cs
├── Settings.cs                  # Extends WorkerBackgroundServiceSettings
├── Service.cs                   # Extends WorkerBackgroundService<TSettings>
├── HealthCheck.cs
└── StartupExtensions.cs
```

## Features

| Feature | Behavior |
|---------|----------|
| Schedule | Cron, continuous, or one-shot |
| Idle Backoff | Configurable delay when `IdleCycle = true` (no data), `TimeSpan.Zero` = disabled |
| Delay Between Executions | Fixed delay between consecutive executions, `TimeSpan.Zero` = disabled |
| Health | `IHealthCheck` - unhealthy if degraded or no completion in X time |
| Retry | Optional, exponential + jitter, configurable count (default 3) |
| Concurrency | Skips if previous run still executing |
| Startup | Fail fast - validates injected `IHealthCheck[]` before first execution |
| Shutdown | Graceful with configurable timeout for K8s |
| Observability | Base provides protected meter/tracer, derived adds service-specific metrics |

## Required Extensions

### ScheduleValidationAttribute.cs

```csharp
using System;
using System.ComponentModel.DataAnnotations;
using Cronos;
namespace MyOrganization.Extensions.Hosting.Validators;

[AttributeUsage(AttributeTargets.Property | AttributeTargets.Field, AllowMultiple = false)]
public sealed class ScheduleValidationAttribute : ValidationAttribute
{
    public bool AllowEmpty { get; set; } = false;

    protected override ValidationResult? IsValid(object? value, ValidationContext validationContext)
    {
        var expression = value?.ToString();

        if (string.IsNullOrWhiteSpace(expression))
        {
            return AllowEmpty
                ? ValidationResult.Success
                : new ValidationResult("Schedule expression is required unless continuous mode is intended.");
        }

        try
        {
            CronExpression.Parse(expression);
            return ValidationResult.Success;
        }
        catch
        {
            return new ValidationResult(ErrorMessage ?? "Invalid cron expression.");
        }
    }
}
```

## WorkerBackgroundServiceSettings

```csharp
using System;
using System.Threading;
using Cronos;
using MyOrganization.Extensions.Hosting.Validators;

namespace MyOrganization.Extensions.Hosting;

public class WorkerBackgroundServiceSettings
{
    public const string ConfigurationSectionName = nameof(WorkerBackgroundService<WorkerBackgroundServiceSettings>);
    public static readonly string FeatureFlag = ConfigurationSectionName;

    public bool Enabled { get; internal set; }
    public bool RunOnce { get; set; }
    public bool RunImmediately { get; set; }

    [ScheduleValidation(AllowEmpty = true, ErrorMessage = "Invalid schedule expression.")]
    public string? ScheduleCronExpression { get; set; }

    // Retry settings
    public bool RetryEnabled { get; set; } = false;
    public int RetryCount { get; set; } = 3;
    public int RetryBaseDelaySeconds { get; set; } = 1;

    // Health settings
    public int HealthSampleSize { get; set; } = 5;
    public double HealthDegradedThresholdMultiplier { get; set; } = 2.0;
    public TimeSpan? HealthHardTimeout { get; set; }

    // Shutdown settings
    public int ShutdownTimeoutSeconds { get; set; } = 30;

    // Delay settings
    public TimeSpan DelayBetweenExecutions { get; set; } = TimeSpan.Zero;

    // Idle backoff settings
    public TimeSpan IdleBackoffDuration { get; set; } = TimeSpan.Zero;

    public bool RunContinuously => string.IsNullOrWhiteSpace(ScheduleCronExpression);

    public TimeSpan NextOccurrence
    {
        get
        {
            if (!Enabled || RunOnce) return Timeout.InfiniteTimeSpan;
            if (RunContinuously) return TimeSpan.Zero;

            var expression = CronExpression.Parse(ScheduleCronExpression!);
            var next = expression.GetNextOccurrence(DateTimeOffset.UtcNow, TimeZoneInfo.Local);
			if (next == null) throw new InvalidOperationException("Failed to calculate the next occurrence from the cron expression.");
            return next == DateTimeOffset.MinValue ? Timeout.InfiniteTimeSpan : (DateTimeOffset)next - DateTimeOffset.UtcNow;
        }
    }
}
```

## WorkerBackgroundService Base Class

```csharp
namespace MyOrganization.Extensions.Hosting;

public abstract class WorkerBackgroundService<TSettings> : IHostedLifecycleService, IDisposable
    where TSettings : WorkerBackgroundServiceSettings
{
#pragma warning disable IDE1006
    protected readonly ILogger _logger;
    protected readonly IDistributedTracing _tracer;
    protected readonly Meter _meter;
    protected readonly TSettings _settings;
#pragma warning restore IDE1006

    private readonly IEnumerable<IHealthCheck> _healthChecks;
    private readonly CancellationTokenSource _cancellationTokenSource = new();
    private readonly SemaphoreSlim _executionLock = new(1, 1);
    private readonly object _statisticsLock = new ();

    // Health tracking (thread-safe via _statisticsLock)
    private readonly Queue<double> _executionDurations = new();
    private double _lastExecutionDuration;
    private DateTime _lastSuccessfulCompletion = DateTime.UtcNow;

    // Metrics
    private readonly UpDownCounter<int> _activeExecutions;
    private readonly Counter<long> _executionTotal;
    private readonly Counter<long> _executionSuccess;
    private readonly Counter<long> _executionFailed;
    private readonly Counter<long> _executionSkipped;
    private readonly Counter<long> _retryTotal;
    private readonly Histogram<double> _executionDuration;

    private Task? _executingTask;

    protected WorkerBackgroundService(
        ILogger<WorkerBackgroundService<TSettings>> logger,
        IDistributedTracing distributedTracing,
        IMeterFactory meterFactory,
        IOptions<TSettings> options,
        IEnumerable<IHealthCheck> healthChecks)
    {
        _logger = logger;
        _tracer = distributedTracing;
        _meter = meterFactory.Create(new MeterOptions(Startup.AssemblyName)
        {
            Version = Startup.AssemblyVersion,
            Tags = new TagList
            {
                { "code.namespace", GetType().Namespace },
                { "code.class", GetType().Name }
            }
        });
        _settings = options.Value;
        _healthChecks = healthChecks;

        var serviceName = JsonNamingPolicy.SnakeCaseLower.ConvertName(GetType().Name);
        _activeExecutions = _meter.CreateUpDownCounter<int>(
            $"app_{serviceName}_active", "executions", "Currently active executions across instances");
        _executionTotal = _meter.CreateCounter<long>(
            $"app_{serviceName}_total", "executions", "Total execution attempts");
        _executionSuccess = _meter.CreateCounter<long>(
            $"app_{serviceName}_success", "executions", "Successful executions");
        _executionFailed = _meter.CreateCounter<long>(
            $"app_{serviceName}_failed", "executions", "Failed executions");
        _executionSkipped = _meter.CreateCounter<long>(
            $"app_{serviceName}_skipped", "executions", "Skipped (previous still running)");
        _retryTotal = _meter.CreateCounter<long>(
            $"app_{serviceName}_retries", "retries", "Total retry attempts");
        _executionDuration = _meter.CreateHistogram<double>(
            $"app_{serviceName}_duration_seconds", "s", "Execution duration");
    }

    protected bool IdleCycle { get; set; }

    public abstract Task DoWorkAsync(CancellationToken cancellationToken);

    #region IHostedLifecycleService

    public async Task StartingAsync(CancellationToken cancellationToken)
    {
        _logger.LogDebug("Service starting. Validating dependencies.");

        foreach (var check in _healthChecks)
        {
            var result = await check.CheckHealthAsync(new HealthCheckContext(), cancellationToken);
            if (result.Status == HealthStatus.Unhealthy)
            {
                throw new InvalidOperationException($"Startup health check failed: {result.Description}");
            }
        }

        _logger.LogDebug("All health checks passed.");
    }

    public Task StartedAsync(CancellationToken cancellationToken)
    {
        if (!_settings.Enabled)
        {
            _logger.LogInformation("Service {ServiceName} is disabled.", GetType().Name);
            return Task.CompletedTask;
        }

        _executingTask = RunScheduleLoopAsync(_cancellationTokenSource.Token);
        return Task.CompletedTask;
    }

    public async Task StoppingAsync(CancellationToken cancellationToken)
    {
        _logger.LogInformation("SIGTERM received. Initiating graceful shutdown.");
        await _cancellationTokenSource.CancelAsync();

        if (_executingTask is null)
        {
            return;
        }

        var timeout = TimeSpan.FromSeconds(_settings.ShutdownTimeoutSeconds);
        using var timeoutCts = new CancellationTokenSource(timeout);

        try
        {
            var completedTask = await Task.WhenAny(_executingTask, Task.Delay(timeout, CancellationToken.None));

            if (completedTask == _executingTask)
            {
                await _executingTask; // Propagate exceptions if any
                _logger.LogInformation("Work completed gracefully.");
            }
            else
            {
                _logger.LogWarning(
                    "Shutdown timeout ({TimeoutSeconds}s) exceeded. Work may be incomplete.",
                    _settings.ShutdownTimeoutSeconds);
            }
        }
        catch (OperationCanceledException)
        {
            _logger.LogInformation("Shutdown completed via cancellation.");
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error during shutdown.");
        }
    }

    public Task StoppedAsync(CancellationToken cancellationToken)
    {
        _logger.LogInformation("Service stopped.");
        return Task.CompletedTask;
    }

    public Task StartAsync(CancellationToken cancellationToken) => Task.CompletedTask;
    public Task StopAsync(CancellationToken cancellationToken) => Task.CompletedTask;

    #endregion

    #region Execution

    private async Task RunScheduleLoopAsync(CancellationToken cancellationToken)
    {
        // Yield to ensure the loop runs asynchronously and doesn't block StartedAsync
        await Task.Yield();
        
        var mode = _settings.RunContinuously ? "continuous" : $"schedule: {_settings.ScheduleCronExpression}";
        _logger.LogInformation("Service running in {Mode} mode.", mode);

        var isFirstExecution = true;
        while (!cancellationToken.IsCancellationRequested)
        {
            var shouldExecute = !isFirstExecution || _settings.RunImmediately || _settings.RunContinuously;
            if (shouldExecute)
            {
                IdleCycle = false;
                await ExecuteWorkAsync(cancellationToken);
            }
            else
            {
                _logger.LogInformation("Skipping initial execution (RunImmediately=false).");
            }

            isFirstExecution = false;

            if (cancellationToken.IsCancellationRequested) break;

            // Apply idle backoff if no data was found
            if (IdleCycle && _settings.IdleBackoffDuration > TimeSpan.Zero)
            {
                _logger.LogDebug("Idle cycle detected. Backing off for {Duration}.", _settings.IdleBackoffDuration);
                try
                {
                    await Task.Delay(_settings.IdleBackoffDuration, cancellationToken);
                }
                catch (TaskCanceledException)
                {
                    break;
                }
            }

            if (cancellationToken.IsCancellationRequested) break;

            // Apply artificial delay between executions if configured
            if (_settings.DelayBetweenExecutions > TimeSpan.Zero)
            {
                _logger.LogDebug("Waiting {Delay} before next execution.", _settings.DelayBetweenExecutions);
                try
                {
                    await Task.Delay(_settings.DelayBetweenExecutions, cancellationToken);
                }
                catch (TaskCanceledException)
                {
                    break;
                }
            }

            if (cancellationToken.IsCancellationRequested) break;

            var delay = _settings.NextOccurrence;
            if (delay == Timeout.InfiniteTimeSpan)
            {
                _logger.LogInformation("No further executions scheduled.");
                break;
            }

            if (delay > TimeSpan.Zero)
            {
                _logger.LogInformation("Next execution in {Delay}.", delay);
                try
                {
                    await Task.Delay(delay, cancellationToken);
                }
                catch (TaskCanceledException)
                {
                    break;
                }
            }
        }
    }

    private async Task ExecuteWorkAsync(CancellationToken cancellationToken)
    {
        if (!await _executionLock.WaitAsync(0, cancellationToken))
        {
            _logger.LogWarning("Skipping execution - previous run still in progress.");
            _executionSkipped.Add(1);
            return;
        }

        var stopwatch = Stopwatch.StartNew();
        _activeExecutions.Add(1);
        _executionTotal.Add(1);

        try
        {
            using (_logger.BeginScope("{ExecutionId}", Guid.NewGuid()))
            {
                _logger.LogDebug("Starting execution.");

                await ExecuteWithRetryAsync(cancellationToken);

                stopwatch.Stop();
                RecordSuccess(stopwatch.Elapsed.TotalSeconds);
                _logger.LogDebug("Execution completed in {Duration:F2}s.", stopwatch.Elapsed.TotalSeconds);
            }
        }
        catch (OperationCanceledException)
        {
            _logger.LogInformation("Execution cancelled.");
        }
        catch (Exception ex)
        {
            stopwatch.Stop();
            RecordFailure(stopwatch.Elapsed.TotalSeconds);
            _logger.LogError(ex, "Execution failed after retries.");
        }
        finally
        {
            _activeExecutions.Add(-1);
            _executionLock.Release();
        }
    }

    private async Task ExecuteWithRetryAsync(CancellationToken cancellationToken)
    {
        var maxAttempts = _settings.RetryEnabled ? _settings.RetryCount + 1 : 1;

        for (var attempt = 1; attempt <= maxAttempts; attempt++)
        {
            try
            {
                await DoWorkAsync(cancellationToken);
                return;
            }
            catch (OperationCanceledException)
            {
                throw;
            }
            catch (Exception ex) when (attempt < maxAttempts)
            {
                _retryTotal.Add(1);
                var delay = CalculateBackoffWithJitter(attempt);
                _logger.LogWarning(
                    ex,
                    "Attempt {Attempt}/{Max} failed. Retrying in {DelayMs}ms.",
                    attempt,
                    maxAttempts,
                    delay.TotalMilliseconds);
                await Task.Delay(delay, cancellationToken);
            }
        }
    }

    private TimeSpan CalculateBackoffWithJitter(int attempt)
    {
        const double JitterFactor = 0.5;
        var baseDelay = _settings.RetryBaseDelaySeconds * Math.Pow(2, attempt - 1);
        var jitter = Random.Shared.NextDouble() * JitterFactor * baseDelay;
        return TimeSpan.FromSeconds(baseDelay + jitter);
    }

    #endregion

    #region Health Tracking

    private void RecordSuccess(double elapsedSeconds)
    {
        _executionSuccess.Add(1);
        _executionDuration.Record(elapsedSeconds);

        lock (_statisticsLock)
        {
            _lastExecutionDuration = elapsedSeconds;
            _executionDurations.Enqueue(elapsedSeconds);
            while (_executionDurations.Count > _settings.HealthSampleSize)
            {
                _executionDurations.Dequeue();
            }
            _lastSuccessfulCompletion = DateTime.UtcNow;
        }
    }

    private void RecordFailure(double elapsedSeconds)
    {
        _executionFailed.Add(1);
        _executionDuration.Record(elapsedSeconds);

        lock (_statisticsLock)
        {
            _lastExecutionDuration = elapsedSeconds;
        }
    }

    public double? GetAverageExecutionDuration()
    {
        lock (_statisticsLock)
        {
            return _executionDurations.Count > 0 ? _executionDurations.Average() : null;
        }
    }

    public double GetLastExecutionDuration()
    {
        lock (_statisticsLock)
        {
            return _lastExecutionDuration;
        }
    }

    public DateTime GetLastSuccessfulCompletion()
    {
        lock (_statisticsLock)
        {
            return _lastSuccessfulCompletion;
        }
    }

    #endregion

    public void Dispose()
    {
        _cancellationTokenSource.Dispose();
        _executionLock.Dispose();
		_meter.Dispose();
        GC.SuppressFinalize(this);
    }
}
```

## HealthCheck.cs for Background Service

```csharp
namespace {Organization}.{Product}.Services.{ServiceName};

public class {ServiceName}HealthCheck : IHealthCheck
{
    private readonly {ServiceName} _service;
    private readonly {ServiceName}Settings _settings;

    public {ServiceName}HealthCheck({ServiceName} service, IOptions<{ServiceName}Settings> options)
    {
        _service = service;
        _settings = options.Value;
    }

    public Task<HealthCheckResult> CheckHealthAsync(
        HealthCheckContext context,
        CancellationToken cancellationToken = default)
    {
        // Hard timeout check - no successful completion in X time
        if (_settings.HealthHardTimeout.HasValue)
        {
            var timeSinceLastSuccess = DateTime.UtcNow - _service.GetLastSuccessfulCompletion();
            if (timeSinceLastSuccess > _settings.HealthHardTimeout.Value)
            {
                return Task.FromResult(HealthCheckResult.Unhealthy(
                    $"No successful completion in {timeSinceLastSuccess:g}."));
            }
        }

        // Degraded check - last execution took significantly longer than average
        var average = _service.GetAverageExecutionDuration();
        if (average.HasValue)
        {
            var lastDuration = _service.GetLastExecutionDuration();
            var threshold = average.Value * _settings.HealthDegradedThresholdMultiplier;

            if (lastDuration > threshold)
            {
                return Task.FromResult(HealthCheckResult.Degraded(
                    $"Last execution ({lastDuration:F2}s) exceeded threshold ({threshold:F2}s). Average: {average:F2}s"));
            }
        }

        return Task.FromResult(HealthCheckResult.Healthy());
    }
}
```

## Derived Service Example

```csharp
namespace {Organization}.{Product}.Services.{ServiceName};

public class {ServiceName} : WorkerBackgroundService<{ServiceName}Settings>
{
    private readonly Counter<long> _itemsProcessed;

    public {ServiceName}(
        ILogger<{ServiceName}> logger,
        IDistributedTracing distributedTracing,
        IMeterFactory meterFactory,
        IOptions<{ServiceName}Settings> options,
        IEnumerable<IHealthCheck> healthChecks)
        : base(logger, distributedTracing, meterFactory, options, healthChecks)
    {
        var serviceName = JsonNamingPolicy.SnakeCaseLower.ConvertName(GetType().Name);
        _itemsProcessed = _meter.CreateCounter<long>(
            $"app_{serviceName}_items_processed", "items", "Items processed");
    }

    public override async Task DoWorkAsync(CancellationToken cancellationToken)
    {
        using var activity = _tracer.StartActivity("DoWork");
        activity.SetTag("service.name", nameof({ServiceName}));

        try
        {
            _logger.LogInformation("Processing batch");

            // Implementation - check cancellation frequently
            var items = GetItems();

            // Signal the base class when there's no data to process.
            // If IdleBackoffDuration is configured, the base class will
            // automatically delay before the next execution.
            IdleCycle = items.Count == 0;
            if (IdleCycle) return;

            var processed = 0;
            foreach (var item in items)
            {
                cancellationToken.ThrowIfCancellationRequested();
                await ProcessItemAsync(item, cancellationToken);
                processed++;
            }

            _itemsProcessed.Add(processed);
            activity.SetStatus(ActivityStatusCode.Ok);
            _logger.LogInformation("Batch completed. Processed {Count} items.", processed);
        }
        catch (OperationCanceledException)
        {
            activity.SetStatus(ActivityStatusCode.Error, "Cancelled");
            throw;
        }
        catch (Exception ex)
        {
            activity.SetStatus(ActivityStatusCode.Error, ex.Message);
            activity.SetTag("exception.type", ex.GetType().FullName);
            activity.SetTag("exception.message", ex.Message);
            _logger.LogError(ex, "Batch failed");
            throw;
        }
    }
}
```

## StartupExtensions.cs

```csharp
namespace {Organization}.{Product}.Services.{ServiceName};

public static class StartupExtensions
{
    public static IServiceCollection Add{ServiceName}(
        this IServiceCollection services,
        Action<{ServiceName}Settings>? setupAction = null)
    {
        ArgumentNullException.ThrowIfNull(services);

        services.EnsureServicesRegistered(
            typeof(IDistributedTracing),
            typeof(IMeterFactory));

        services.AddOptions<{ServiceName}Settings>()
            .BindConfiguration({ServiceName}Settings.ConfigurationSectionName)
            .Configure<IConfiguration>((settings, config) =>
            {
                settings.Enabled = config.GetFeatureFlag<{ServiceName}Settings>();
            })
            .ValidateDataAnnotations()
            .ValidateOnStart();

        if (setupAction is not null)
        {
            services.Configure(setupAction);
        }

        services.AddSingleton<{ServiceName}>();
        services.AddSingleton<IHostedLifecycleService>(sp => sp.GetRequiredService<{ServiceName}>());
        services.AddHealthChecks()
            .AddCheck<{ServiceName}HealthCheck>("{ServiceName}", tags: ["ready"]);

        return services;
    }
}
```

## Configuration

```json
{
  "FeatureManagement": {
    "{ServiceName}": true
  },
  "{ServiceName}": {
    "RunOnce": false,
    "RunImmediately": true,
    "ScheduleCronExpression": "*/5 * * * *",
    "RetryEnabled": true,
    "RetryCount": 3,
    "RetryBaseDelaySeconds": 1,
    "DelayBetweenExecutions": "00:00:00",
    "IdleBackoffDuration": "00:00:30",
    "HealthSampleSize": 5,
    "HealthDegradedThresholdMultiplier": 2.0,
    "HealthHardTimeout": "01:00:00",
    "ShutdownTimeoutSeconds": 30
  }
}
```

| Setting | Description |
|---------|-------------|
| `ScheduleCronExpression` | Cron expression, null/empty = continuous |
| `RunOnce` | Execute once then stop |
| `RunImmediately` | Execute on startup |
| `RetryEnabled` | Enable exponential backoff + jitter |
| `RetryCount` | Max retry attempts (default 3) |
| `RetryBaseDelaySeconds` | Base delay for backoff (default 1) |
| `DelayBetweenExecutions` | Fixed delay between executions, `00:00:00` = disabled |
| `IdleBackoffDuration` | Delay when `IdleCycle = true`, `00:00:00` = disabled |
| `HealthSampleSize` | Rolling sample size for average calculation |
| `HealthDegradedThresholdMultiplier` | Last duration > avg × multiplier = degraded |
| `HealthHardTimeout` | Max time since last success before unhealthy |
| `ShutdownTimeoutSeconds` | Graceful shutdown timeout (default 30) |

## K8s Deployment Notes

Ensure pod spec aligns with `ShutdownTimeoutSeconds`:

```yaml
spec:
  terminationGracePeriodSeconds: 35  # Slightly more than ShutdownTimeoutSeconds
  containers:
    - name: worker
      lifecycle:
        preStop:
          exec:
            command: ["sleep", "5"]  # Allow load balancer to drain
```
