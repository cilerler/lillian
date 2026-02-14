# Standard Service Pattern

## File Structure

```
Services/{ServiceName}/
├── Contracts/
│   └── I{ServiceName}.cs
├── Models/                # DTOs, records, entities
├── Validators/            # Custom validation attributes
├── Exceptions/            # Custom exceptions
├── Mappers/               # Object mapping
├── Constants.cs
├── Settings.cs
├── Service.cs
├── HealthCheck.cs         # If needed
├── StartupExtensions.cs
└── Api.cs                 # If API exposed
```

## Contracts/I{ServiceName}.cs

```csharp
namespace {Organization}.{Product}.Services.{ServiceName}.Contracts;

public interface I{ServiceName}
{
    Task<TResult> DoWorkAsync(CancellationToken cancellationToken);
}
```

## Constants.cs

```csharp
namespace {Organization}.{Product}.Services.{ServiceName};

public static class Constants
{
    public const string DefaultValue = "default";
}
```

## Settings.cs

```csharp
namespace {Organization}.{Product}.Services.{ServiceName};

public class {ServiceName}Settings
{
    public const string ConfigurationSectionName = nameof({ServiceName});
    public static readonly string FeatureFlag = ConfigurationSectionName;
    
    public bool Enabled { get; internal set; }
    
    // Connection string pattern (if needed)
    public string ConnectionString { get; internal set; } = null!;
    
    [Required]
    public string ConnectionStringKey { get; set; } = null!;
    
    // Use custom validators for complex validation
    [Required]
    [NoNumericCharacters]  // Custom validator example
    public string ApiKey { get; set; } = null!;
    
    [Required]
    [Range(1, 100)]
    public int MaxRetries { get; set; } = 3;
}
```

## Validators/{Name}Attribute.cs

Custom validation attributes for Settings properties:

```csharp
namespace {Organization}.{Product}.Services.{ServiceName}.Validators;

[AttributeUsage(AttributeTargets.Property | AttributeTargets.Field | AttributeTargets.Parameter, AllowMultiple = false)]
public sealed class NoNumericCharactersAttribute : ValidationAttribute
{
    public NoNumericCharactersAttribute() 
        : base("The field {0} must not contain numeric characters.")
    {
    }

    protected override ValidationResult? IsValid(object? value, ValidationContext validationContext)
    {
        if (value is null or "")
        {
            return ValidationResult.Success;
        }

        if (value is string stringValue && !stringValue.Any(char.IsDigit))
        {
            return ValidationResult.Success;
        }

        var errorMessage = FormatErrorMessage(validationContext.DisplayName);
        return new ValidationResult(errorMessage, [validationContext.MemberName!]);
    }
}
```

Common validators for Settings:
- `[NoNumericCharacters]` - String must not contain digits
- `[ValidUrl]` - Must be valid URL format
- `[ValidConnectionString]` - Must parse as connection string
- `[ScheduleValidation]` - Must be valid cron expression

## Models/{Name}.cs

DTOs, records, and entities:

```csharp
namespace {Organization}.{Product}.Services.{ServiceName}.Models;

public record {ServiceName}Request(string Id, string Data);

public record {ServiceName}Response(string Id, string Result, DateTime ProcessedAt);

public record {ServiceName}Item
{
    public required string Id { get; init; }
    public required string Name { get; init; }
    public DateTime CreatedAt { get; init; } = DateTime.UtcNow;
}
```

## Exceptions/{Name}Exception.cs

```csharp
namespace {Organization}.{Product}.Services.{ServiceName}.Exceptions;

public class {ServiceName}Exception : Exception
{
    public string? ErrorCode { get; }

    public {ServiceName}Exception(string message, string? errorCode = null) 
        : base(message)
    {
        ErrorCode = errorCode;
    }

    public {ServiceName}Exception(string message, Exception innerException, string? errorCode = null) 
        : base(message, innerException)
    {
        ErrorCode = errorCode;
    }
}

public class {ServiceName}NotFoundException : {ServiceName}Exception
{
    public {ServiceName}NotFoundException(string id) 
        : base($"Resource '{id}' not found.", "NOT_FOUND")
    {
    }
}

public class {ServiceName}ValidationException : {ServiceName}Exception
{
    public IReadOnlyList<string> Errors { get; }

    public {ServiceName}ValidationException(IEnumerable<string> errors) 
        : base("Validation failed.", "VALIDATION_ERROR")
    {
        Errors = errors.ToList().AsReadOnly();
    }
}
```

## Mappers/{Name}Mapper.cs

```csharp
namespace {Organization}.{Product}.Services.{ServiceName}.Mappers;

public static class {ServiceName}Mapper
{
    public static {ServiceName}Response ToResponse(this {ServiceName}Item item)
    {
        return new {ServiceName}Response(
            item.Id,
            item.Name,
            item.CreatedAt);
    }

    public static IEnumerable<{ServiceName}Response> ToResponses(this IEnumerable<{ServiceName}Item> items)
    {
        return items.Select(ToResponse);
    }
}
```

## Service.cs

```csharp
namespace {Organization}.{Product}.Services.{ServiceName};

using {Organization}.{Product}.Services.{ServiceName}.Contracts;
using {Organization}.{Product}.Services.{ServiceName}.Exceptions;
using {Organization}.{Product}.Services.{ServiceName}.Mappers;
using {Organization}.{Product}.Services.{ServiceName}.Models;

public class {ServiceName} : I{ServiceName}
{
    private readonly ILogger<{ServiceName}> _logger;
    private readonly IDistributedTracing _tracer;
    private readonly Meter _meter;
    private readonly {ServiceName}Settings _settings;

    private readonly UpDownCounter<int> _activeRequests;
    private readonly Counter<long> _operationCounter;
    private readonly Histogram<double> _operationDuration;

    public {ServiceName}(
        ILogger<{ServiceName}> logger,
        IDistributedTracing distributedTracing,
        IMeterFactory meterFactory,
        IOptions<{ServiceName}Settings> options)
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

        var serviceName = GetType().Name.ToSnakeCase();
        _activeRequests = _meter.CreateUpDownCounter<int>(
            $"app_{serviceName}_active", "requests", "Active requests");
        _operationCounter = _meter.CreateCounter<long>(
            $"app_{serviceName}_total", "operations", "Total operations");
        _operationDuration = _meter.CreateHistogram<double>(
            $"app_{serviceName}_duration_seconds", "s", "Operation duration");
    }

    public async Task<TResult> DoWorkAsync(CancellationToken cancellationToken)
    {
        var stopwatch = Stopwatch.StartNew();
        using var activity = _tracer.StartActivity("DoWork");
        activity.SetTag("service.name", nameof({ServiceName}));

        using (_logger.BeginScope("{TraceId}, {SpanId}", activity.TraceId, activity.SpanId))
        {
            _activeRequests.Add(1);
            _operationCounter.Add(1);

            try
            {
                _logger.LogInformation("Starting operation");

                // Implementation
                await Task.Delay(1, cancellationToken);

                activity.SetStatus(ActivityStatusCode.Ok);
                _logger.LogInformation("Operation completed");

                return default!;
            }
            catch (Exception ex)
            {
                activity.SetStatus(ActivityStatusCode.Error, ex.Message);
                activity.SetTag("exception.type", ex.GetType().FullName);
                activity.SetTag("exception.message", ex.Message);
                activity.SetTag("exception.stacktrace", ex.StackTrace);
                _logger.LogError(ex, "Operation failed");
                throw;
            }
            finally
            {
                _activeRequests.Add(-1);
                stopwatch.Stop();
                _operationDuration.Record(stopwatch.Elapsed.TotalSeconds);
            }
        }
    }
}
```

## StartupExtensions.cs

```csharp
namespace {Organization}.{Product}.Services.{ServiceName};

using {Organization}.{Product}.Services.{ServiceName}.Contracts;

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

        services.AddScoped<I{ServiceName}, {ServiceName}>();

        return services;
    }
}
```

## Service Lifetime Guidelines

- **Singleton**: HttpClient wrappers, caching, background services
- **Scoped**: Database operations, request-specific state, DbContext
- **Transient**: Lightweight stateless, factory-created instances
