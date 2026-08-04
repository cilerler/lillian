# Background Service Pattern

Extends `WorkerBackgroundService<TSettings>` for scheduled/continuous background work.

## File Structure

```
{Organization}.{Product}.Modules.{ModuleName}/{ComponentName}/{ServiceName}/
├── Abstractions/                    # Public contract
│   ├── Events/
│   ├── Interfaces/
│   ├── Models/
│   ├── Requests/
│   └── Responses/
├── Api/                             # optional — if HTTP endpoints exposed
├── Clients/                         # External HTTP dependencies
├── Configuration/
│   └── {ServiceName}Settings.cs     # Extends WorkerBackgroundServiceSettings
├── Contracts/                       # Internal interfaces
│   └── I{ServiceName}.cs
├── Exceptions/
├── Extensions/
│   └── StartupExtensions.cs
├── Internals/                       # Internal helpers
├── Mappers/
├── Models/                          # Internal entities/DTOs
├── Observability/
│   └── Grafana/
│       └── dashboard.json
├── Resources/                       # optional — embedded resource files (SQL, templates, etc.)
│   └── SQL/
├── Validators/
├── Constants.cs
├── {ServiceName}Service.cs          # Core business logic
├── {ServiceName}Worker.cs           # Extends WorkerBackgroundService<{ServiceName}Settings>
└── {ServiceName}HealthCheck.cs
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

> **Warning -- Continuous mode**: When `ScheduleCronExpression` is null/empty (continuous mode), the loop has no built-in delay between iterations. Always set `DelayBetweenExecutions` to a non-zero value (e.g., `"00:00:01"`) to prevent tight-loop CPU spinning.

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
            CronExpression.Parse(expression, CronFormat.IncludeSeconds);
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
using System.Text.Json.Serialization;
using System.Threading;
using Cronos;
using MyOrganization.Extensions.Hosting.Validators;

namespace MyOrganization.Extensions.Hosting;

public class WorkerBackgroundServiceSettings
{
    public const string ConfigurationSectionName = nameof(WorkerBackgroundService<WorkerBackgroundServiceSettings>);
    public static readonly string FeatureFlag = ConfigurationSectionName;

    [JsonIgnore]
    public bool Enabled { get; set; }
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
    public TimeSpan ShutdownTimeout { get; set; } = TimeSpan.FromSeconds(30);

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

            var expression = CronExpression.Parse(ScheduleCronExpression!, CronFormat.IncludeSeconds);
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

        using var timeoutCts = new CancellationTokenSource(_settings.ShutdownTimeout);

        try
        {
            var completedTask = await Task.WhenAny(_executingTask, Task.Delay(_settings.ShutdownTimeout, CancellationToken.None));

            if (completedTask == _executingTask)
            {
                await _executingTask; // Propagate exceptions if any
                _logger.LogInformation("Work completed gracefully.");
            }
            else
            {
                _logger.LogWarning(
                    "Shutdown timeout ({ShutdownTimeout}) exceeded. Work may be incomplete.",
                    _settings.ShutdownTimeout);
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

## Settings.cs

```csharp
namespace {Organization}.{Product}.Modules.{ModuleName}.{ComponentName}.{ServiceName}.Configuration;

public class {ServiceName}Settings : WorkerBackgroundServiceSettings
{
    public new const string ConfigurationSectionName = nameof({ServiceName});
    public new static readonly string FeatureFlag = ConfigurationSectionName;

    // Add service-specific settings here
}
```

## HealthCheck.cs

```csharp
namespace {Organization}.{Product}.Modules.{ModuleName}.{ComponentName}.{ServiceName};

public class {ServiceName}HealthCheck : IHealthCheck
{
    private readonly {ServiceName}Worker _worker;
    private readonly {ServiceName}Settings _settings;

    public {ServiceName}HealthCheck({ServiceName}Worker worker, IOptions<{ServiceName}Settings> options)
    {
        _worker = worker;
        _settings = options.Value;
    }

    public Task<HealthCheckResult> CheckHealthAsync(
        HealthCheckContext context,
        CancellationToken cancellationToken = default)
    {
        // Hard timeout check - no successful completion in X time
        if (_settings.HealthHardTimeout.HasValue)
        {
            var timeSinceLastSuccess = DateTime.UtcNow - _worker.GetLastSuccessfulCompletion();
            if (timeSinceLastSuccess > _settings.HealthHardTimeout.Value)
            {
                return Task.FromResult(HealthCheckResult.Unhealthy(
                    $"No successful completion in {timeSinceLastSuccess:g}."));
            }
        }

        // Degraded check - last execution took significantly longer than average
        var average = _worker.GetAverageExecutionDuration();
        if (average.HasValue)
        {
            var lastDuration = _worker.GetLastExecutionDuration();
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

## Worker.cs and Service.cs

> **Separation of concerns**: Worker handles scheduling, retries, concurrency, and health. Service handles business logic. This makes business logic testable without standing up a hosted service, and lets you swap the trigger (cron, queue, HTTP) without touching business logic.

### {ServiceName}Service.cs

```csharp
namespace {Organization}.{Product}.Modules.{ModuleName}.{ComponentName}.{ServiceName};

using {Organization}.{Product}.Modules.{ModuleName}.{ComponentName}.{ServiceName}.Contracts;

public class {ServiceName}Service : I{ServiceName}
{
    private readonly ILogger<{ServiceName}Service> _logger;
    private readonly IDistributedTracing _tracer;
    private readonly Meter _meter;
    private readonly Counter<long> _itemsProcessed;

    public {ServiceName}Service(
        ILogger<{ServiceName}Service> logger,
        IDistributedTracing distributedTracing,
        IMeterFactory meterFactory)
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

        _itemsProcessed = _meter.CreateCounter<long>(
            Constants.Metrics.ItemsProcessed, "items", "Items processed");
    }

    public async Task<bool> CheckForNewDataAsync(CancellationToken cancellationToken)
    {
        // Check if there is new data to process
        var items = await GetPendingItemsAsync(cancellationToken);
        return items.Count > 0;
    }

    public async Task ProcessAsync(CancellationToken cancellationToken)
    {
        using var activity = _tracer.StartActivity("ProcessBatch", ActivityKind.Internal);

        try
        {
            var items = await GetPendingItemsAsync(cancellationToken);
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
            _logger.LogError(ex, "Batch failed");
            throw;
        }
    }
}
```

### {ServiceName}Worker.cs

```csharp
namespace {Organization}.{Product}.Modules.{ModuleName}.{ComponentName}.{ServiceName};

using {Organization}.{Product}.Modules.{ModuleName}.{ComponentName}.{ServiceName}.Configuration;
using {Organization}.{Product}.Modules.{ModuleName}.{ComponentName}.{ServiceName}.Contracts;

public class {ServiceName}Worker : WorkerBackgroundService<{ServiceName}Settings>
{
    private readonly I{ServiceName} _service;

    public {ServiceName}Worker(
        ILogger<{ServiceName}Worker> logger,
        IDistributedTracing distributedTracing,
        IMeterFactory meterFactory,
        IOptions<{ServiceName}Settings> options,
        IEnumerable<IHealthCheck> healthChecks,
        I{ServiceName} service)
        : base(logger, distributedTracing, meterFactory, options, healthChecks)
    {
        _service = service;
    }

    public override async Task DoWorkAsync(CancellationToken cancellationToken)
    {
        var hasData = await _service.CheckForNewDataAsync(cancellationToken);
        IdleCycle = !hasData;
        if (IdleCycle) return;

        await _service.ProcessAsync(cancellationToken);
    }
}
```

## StartupExtensions.cs

```csharp
namespace {Organization}.{Product}.Modules.{ModuleName}.{ComponentName}.{ServiceName}.Extensions;

using {Organization}.{Product}.Modules.{ModuleName}.{ComponentName}.{ServiceName}.Contracts;

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

        services.AddSingleton<I{ServiceName}, {ServiceName}Service>();
        services.AddSingleton<{ServiceName}Worker>();
        services.AddHostedService(sp => sp.GetRequiredService<{ServiceName}Worker>());
        services.AddHealthChecks()
            .AddCheck<{ServiceName}HealthCheck>("{ServiceName}", tags: ["ready"]);

        return services;
    }

    public static WebApplication Map{ServiceName}(this WebApplication app)
    {
        ArgumentNullException.ThrowIfNull(app);

        if (app.Configuration.GetFeatureFlag<{ServiceName}Settings>())
            app.Map{ServiceName}Api();

        return app;
    }
}
```

> **Registration notes**: The worker must be exposed to the host via `AddHostedService` — the host only starts hosted services registered as `IHostedService` (the `IHostedLifecycleService` hooks are discovered through that same registration). The `AddSingleton<{ServiceName}Worker>()` + factory pair ensures the host and any other consumers share one worker instance. `I{ServiceName}` is registered as **singleton** because the singleton worker consumes it via constructor injection and the base class does not create DI scopes. If the service needs scoped dependencies (e.g., a `DbContext`), register it scoped instead and have the worker inject `IServiceScopeFactory` and resolve `I{ServiceName}` from a new scope inside each `DoWorkAsync` execution.

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
    "ShutdownTimeout": "00:00:30"
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
| `HealthDegradedThresholdMultiplier` | Last duration > avg x multiplier = degraded |
| `HealthHardTimeout` | Max time since last success before unhealthy |
| `ShutdownTimeout` | Graceful shutdown timeout, `TimeSpan` (default `00:00:30`) |

## K8s Deployment Notes

Ensure pod spec aligns with `ShutdownTimeout`:

```yaml
spec:
  terminationGracePeriodSeconds: 35  # Slightly more than ShutdownTimeout
  containers:
    - name: worker
      lifecycle:
        preStop:
          exec:
            command: ["sleep", "5"]  # Allow load balancer to drain
```
