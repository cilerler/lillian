# Standard Service Pattern

## File Structure

```
Services/{ServiceName}/
├── Abstractions/                    # Public contract — crosses module boundary
│   ├── Events/
│   │   └── {Name}Event.cs
│   ├── Interfaces/
│   │   └── I{ServiceName}.cs        # Only when externally consumed
│   ├── Models/
│   │   └── {Name}.cs                # Enums, value objects, shared DTOs
│   ├── Requests/
│   │   └── {Name}Request.cs
│   └── Responses/
│       └── {Name}Response.cs
├── Api/                             # optional — if HTTP endpoints exposed
│   ├── {ServiceName}Api.cs          # Route group definition
│   └── {Verb}Endpoint.cs            # One file per endpoint
├── Clients/                         # External HTTP dependencies
│   ├── I{ExternalApi}Client.cs
│   └── {ExternalApi}Client.cs
├── Configuration/
│   └── {ServiceName}Settings.cs
├── Contracts/                       # Internal interfaces
│   └── I{ServiceName}.cs           # Default: internal (move to Abstractions/Interfaces/ if externally consumed)
├── Docs/                            # Service-scoped documentation (optional)
├── Exceptions/
│   └── {Name}Exception.cs
├── Extensions/
│   └── StartupExtensions.cs
├── Internals/                       # Internal helper implementations
│   └── {Name}.cs                    # Repository, UnitOfWork, Decorator, etc.
├── Mappers/
│   └── {Name}Mapper.cs
├── Models/                          # Internal entities/DTOs only
│   └── {Name}.cs
├── Observability/
│   └── Grafana/
│       └── dashboard.json
├── Resources/                       # optional — embedded resource files (SQL, templates, etc.)
│   └── SQL/
│       ├── {Name}.sql
│       ├── ResourceLoader.cs        # Lazy loader for embedded resources
│       └── Constants.cs             # Resource file name constants
├── Validators/
│   └── {Name}Attribute.cs
├── Constants.cs                     # Includes Metrics nested class
├── {ServiceName}Service.cs          # Core business logic
├── {ServiceName}Worker.cs           # optional — if background/cron
└── {ServiceName}HealthCheck.cs      # optional — if health monitoring needed
```

## Contracts/I{ServiceName}.cs

> **Placement rule**: `I{ServiceName}.cs` defaults to `Contracts/` (internal). Move to `Abstractions/` only when other modules or external consumers need to reference it.

```csharp
namespace {Organization}.{Product}.Services.{ServiceName}.Contracts;

public interface I{ServiceName}
{
    Task<TResult> DoWorkAsync(CancellationToken cancellationToken);
}
```

## Abstractions/Requests/{Name}Request.cs

```csharp
namespace {Organization}.{Product}.Services.{ServiceName}.Abstractions.Requests;

public record Process{ServiceName}Request(string Id, string Data);
```

## Abstractions/Responses/{Name}Response.cs

```csharp
namespace {Organization}.{Product}.Services.{ServiceName}.Abstractions.Responses;

public record {ServiceName}Response(string Id, string Result, DateTime ProcessedAt);
```

## Abstractions/Events/{Name}Event.cs

```csharp
namespace {Organization}.{Product}.Services.{ServiceName}.Abstractions.Events;

public record {ServiceName}CompletedEvent(string Id, DateTime CompletedAt);
```

## Constants.cs

```csharp
namespace {Organization}.{Product}.Services.{ServiceName};

public static class Constants
{
    public const string DefaultValue = "default";
    
    public static class Metrics
    {
        public const string ActiveRequests = "active_requests";
        public const string OperationTotal = "operation_total";
        public const string OperationDuration = "operation_duration_seconds";
    }
}
```

## Configuration/{ServiceName}Settings.cs

> **Rules for default values in Settings classes:**
>
> - **Never** set hardcoded defaults for properties of type `string` or `DateTime`. These are **domain values** (URLs, hostnames, credentials, queue/topic/vhost/exchange names, resource names, paths, header names, API keys, schema names, timestamps) and must live in `appsettings.json` (or environment variables / user-secrets). Declare them with `= null!;` and `[Required]`, or make them nullable (`string?` / `DateTime?`) when the missing state is a valid runtime scenario the code explicitly handles.
> - **OK** to set defaults for **operational** properties of type `TimeSpan`, `int`, `long`, `byte`, `double`, `decimal`, `float`, `bool`, or `enum` — timeouts, retry counts, batch sizes, polling intervals, feature toggles, log levels. These are tuning knobs with sensible cross-environment defaults, not values that change per deployment.
> - **Exception for strings/DateTime:** a default is acceptable *only* if the value is a genuine universal constant that is not environment-specific (e.g. a format string used for serialization) — in which case prefer declaring it as a `const` rather than a property default when possible.
> - **Connection strings follow the `ConnectionString`/`ConnectionStringKey` pattern:** the Settings property holds the *key* (e.g. `"MsSqlConnection"`), not the URL itself. The actual URL lives under the top-level `ConnectionStrings` section in `appsettings.json` and is resolved at use-site via `IConfiguration.GetConnectionString(settings.ConnectionStringKey)`. This keeps the connection-string catalog consistent across services and makes environment-specific overrides straightforward. Apply the same `*ConnectionStringKey` pattern for any URL or endpoint (management URLs, cache endpoints, SMTP servers, etc.), not just databases.

```csharp
namespace {Organization}.{Product}.Services.{ServiceName}.Configuration;

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

Internal entities and domain objects. Public DTOs (requests, responses) belong in `Abstractions/`.

```csharp
namespace {Organization}.{Product}.Services.{ServiceName}.Models;

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

using {Organization}.{Product}.Services.{ServiceName}.Abstractions.Responses;
using {Organization}.{Product}.Services.{ServiceName}.Models;

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

## {ServiceName}Service.cs

```csharp
namespace {Organization}.{Product}.Services.{ServiceName};

using {Organization}.{Product}.Services.{ServiceName}.Abstractions.Responses;
using {Organization}.{Product}.Services.{ServiceName}.Configuration;
using {Organization}.{Product}.Services.{ServiceName}.Contracts;
using {Organization}.{Product}.Services.{ServiceName}.Exceptions;
using {Organization}.{Product}.Services.{ServiceName}.Mappers;
using {Organization}.{Product}.Services.{ServiceName}.Models;

public class {ServiceName}Service : I{ServiceName}
{
    private readonly ILogger<{ServiceName}Service> _logger;
    private readonly IDistributedTracing _tracer;
    private readonly Meter _meter;
    private readonly {ServiceName}Settings _settings;

    private readonly UpDownCounter<int> _activeRequests;
    private readonly Counter<long> _operationCounter;
    private readonly Histogram<double> _operationDuration;

    public {ServiceName}Service(
        ILogger<{ServiceName}Service> logger,
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

        _activeRequests = _meter.CreateUpDownCounter<int>(
            Constants.Metrics.ActiveRequests, "requests", "Active requests");
        _operationCounter = _meter.CreateCounter<long>(
            Constants.Metrics.OperationTotal, "operations", "Total operations");
        _operationDuration = _meter.CreateHistogram<double>(
            Constants.Metrics.OperationDuration, "s", "Operation duration");
    }

    public async Task<TResult> DoWorkAsync(CancellationToken cancellationToken)
    {
        var stopwatch = Stopwatch.StartNew();
        using var activity = _tracer.StartActivity("DoWork", ActivityKind.Internal);
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

## {ServiceName}Worker.cs

See `background-service.md` for the Worker pattern and the `WorkerBackgroundService` base class. Worker owns lifecycle/scheduling. Service owns business logic. Worker calls Service, never the reverse.

## {ServiceName}HealthCheck.cs

See `health-check.md` for the health check pattern and registration.

## Clients/

See `dependencies.md` for the typed HTTP client pattern (interface, implementation, and registration). Registration stays in `Extensions/StartupExtensions.cs` using `AddHttpClient<>`.

## Internals/{Name}.cs

Internal helper implementations such as Repository, UnitOfWork, Decorator, Observer, and similar patterns. Their interfaces go in `Contracts/`.

```csharp
namespace {Organization}.{Product}.Services.{ServiceName}.Internals;

internal class DataSanitizer : IDataSanitizer
{
    public string Sanitize(string input) => input.Trim().ToLowerInvariant();
}
```

## Observability/Grafana/dashboard.json

Per-service Grafana dashboard JSON. See observability skill for dashboard template standards.

## Resources/SQL/

Embedded SQL resource files, loaded lazily at runtime. Avoids inline SQL in C# code.

SQL files must be set as **Embedded Resource** in the `.csproj`:

```xml
<ItemGroup>
  <EmbeddedResource Include="Resources\SQL\*.sql" />
</ItemGroup>
```

### Resources/SQL/Constants.cs

```csharp
namespace {Organization}.{Product}.Services.{ServiceName}.Resources.SQL;

public static class Constants
{
    public const string SelectForUpdate = "SelectForUpdate.sql";
}
```

### Resources/SQL/ResourceLoader.cs

```csharp
namespace {Organization}.{Product}.Services.{ServiceName}.Resources.SQL;

public static class ResourceLoader
{
    private const string ResourcePrefix = $"{nameof(Resources)}.SQL";
    
    private static readonly Lazy<string> _selectForUpdate = new(() =>
        AssemblyReference.Assembly.GetEmbeddedResourceContent(Constants.SelectForUpdate, ResourcePrefix));
    
    public static string SelectForUpdate => _selectForUpdate.Value;
}
```

Usage in `Service.cs`:

```csharp
using {Organization}.{Product}.Services.{ServiceName}.Resources.SQL;

var sql = ResourceLoader.SelectForUpdate;
```

For other resource types (email templates, XML schemas, etc.), add subfolders under `Resources/`:

```
Resources/
├── SQL/
├── Templates/
└── Schemas/
```

## Extensions/StartupExtensions.cs

```csharp
namespace {Organization}.{Product}.Services.{ServiceName}.Extensions;

using {Organization}.{Product}.Services.{ServiceName}.Configuration;
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

        services.AddScoped<I{ServiceName}, {ServiceName}Service>();

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
