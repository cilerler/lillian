# Optional Dependencies

Patterns for optional service dependencies. Add to constructor after core dependencies (ILogger, IDistributedTracing, IMeterFactory, IOptions) in alphabetical order.

## Clients/ — External HTTP API Wrappers

For services that wrap an external HTTP API, use the `Clients/` folder with a typed client pattern. This separates HTTP concerns (serialization, retries, auth headers) from business logic.

```
Clients/
├── I{ExternalApi}Client.cs       # Interface
└── {ExternalApi}Client.cs        # Implementation
```

```csharp
// Clients/I{ExternalApi}Client.cs
namespace {Organization}.{Product}.Modules.{ModuleName}.{ComponentName}.{ServiceName}.Clients;

public interface I{ExternalApi}Client
{
    Task<TResponse> GetByIdAsync(string id, CancellationToken cancellationToken);
    Task<TResponse> CreateAsync(TRequest request, CancellationToken cancellationToken);
}
```

```csharp
// Clients/{ExternalApi}Client.cs
namespace {Organization}.{Product}.Modules.{ModuleName}.{ComponentName}.{ServiceName}.Clients;

public class {ExternalApi}Client : I{ExternalApi}Client
{
    private readonly HttpClient _httpClient;

    public {ExternalApi}Client(HttpClient httpClient)
    {
        _httpClient = httpClient;
    }

    public async Task<TResponse> GetByIdAsync(string id, CancellationToken cancellationToken)
    {
        var response = await _httpClient.GetAsync($"/api/resource/{id}", cancellationToken);
        response.EnsureSuccessStatusCode();
        return await response.Content.ReadFromJsonAsync<TResponse>(cancellationToken: cancellationToken)!;
    }

    public async Task<TResponse> CreateAsync(TRequest request, CancellationToken cancellationToken)
    {
        var response = await _httpClient.PostAsJsonAsync("/api/resource", request, cancellationToken);
        response.EnsureSuccessStatusCode();
        return await response.Content.ReadFromJsonAsync<TResponse>(cancellationToken: cancellationToken)!;
    }
}
```

Registration in `Extensions/StartupExtensions.cs` using typed client with resilience:

```csharp
services.AddHttpClient<I{ExternalApi}Client, {ExternalApi}Client>(client =>
{
    client.BaseAddress = new Uri(settings.BaseUrl);
    client.Timeout = settings.HttpTimeout;
})
.AddStandardResilienceHandler();
```

Service.cs then injects `I{ExternalApi}Client` directly (not `IHttpClientFactory`).

> **When to use Clients/ vs IHttpClientFactory**: Use `Clients/` when wrapping an external API with multiple methods, response mapping, and error translation. Use `IHttpClientFactory` directly (below) for simple one-off HTTP calls.

## IHttpClientFactory

For simple HTTP calls that don't warrant a full client wrapper.

**Important**: Resilience policies (retry, circuit breaker, timeout) MUST be configured in the service's own `Extensions/StartupExtensions.cs`, colocated with the HTTP client registration. Do NOT add resilience at the host level (`ProgramExtensions.cs` / `ConfigureHttpClientDefaults`) — it stacks rather than overrides, causing double retries and conflicting timeouts.

```csharp
// Field
private readonly IHttpClientFactory _httpClientFactory;

// Constructor parameter
IHttpClientFactory httpClientFactory

// Constructor body
_httpClientFactory = httpClientFactory;

// Service method usage
var httpClient = _httpClientFactory.CreateClient(Constants.HttpClientName);
var response = await httpClient.PostAsync(url, content);

// Settings - add HttpTimeout property with a sensible default
public TimeSpan HttpTimeout { get; set; } = TimeSpan.FromSeconds(120);

// StartupExtensions - register named client with resilience pipeline
services.AddHttpClient(Constants.HttpClientName)
    .AddResilienceHandler("{ServiceName}Pipeline", static (builder, context) =>
    {
        var settings = context.ServiceProvider.GetRequiredService<IOptions<{ServiceName}Settings>>().Value;

        builder.AddRetry(new HttpRetryStrategyOptions
        {
            BackoffType = DelayBackoffType.Exponential,
            MaxRetryAttempts = settings.MaxRetryAttempts,
            UseJitter = true
        });

        builder.AddCircuitBreaker(new HttpCircuitBreakerStrategyOptions
        {
            SamplingDuration = TimeSpan.FromSeconds(90),
            FailureRatio = 0.2,
            MinimumThroughput = 100,
            ShouldHandle = static args =>
            {
                return ValueTask.FromResult(args is
                {
                    Outcome.Result.StatusCode:
                        HttpStatusCode.RequestTimeout or
                        HttpStatusCode.TooManyRequests or
                        HttpStatusCode.InternalServerError or
                        HttpStatusCode.BadGateway or
                        HttpStatusCode.ServiceUnavailable or
                        HttpStatusCode.GatewayTimeout
                });
            }
        });

        builder.AddTimeout(settings.HttpTimeout);
    });

// Required usings in StartupExtensions
// using System.Net;
// using Microsoft.Extensions.Http.Resilience;
// using Polly;
```

## HybridCache

```csharp
// Field
private readonly HybridCache _hybridCache;

// Constructor parameter
HybridCache hybridCache

// Constructor body
_hybridCache = hybridCache;

// StartupExtensions - add to required services
typeof(HybridCache)

// Usage
var result = await _hybridCache.GetOrCreateAsync(
    cacheKey,
    async token => await FetchDataAsync(token),
    cancellationToken: cancellationToken);
```

## IDistributedCache

```csharp
// Field
private readonly IDistributedCache _distributedCache;

// Constructor parameter
IDistributedCache distributedCache

// Constructor body
_distributedCache = distributedCache;

// StartupExtensions - add to required services
typeof(IDistributedCache)

// Usage
var cached = await _distributedCache.GetStringAsync(key, cancellationToken);
await _distributedCache.SetStringAsync(key, value, options, cancellationToken);
```

## IDistributedLock

```csharp
// Field
private readonly IDistributedLock _distributedLock;

// Constructor parameter
IDistributedLock distributedLock

// Constructor body
_distributedLock = distributedLock;

// StartupExtensions - add to required services
typeof(IDistributedLock)

// Usage
await using var lockHandle = await _distributedLock.AcquireAsync(
    $"lock:{resourceId}", 
    timeout: TimeSpan.FromSeconds(30),
    cancellationToken);
```

## ICloudStorageFactory

```csharp
// Field
private readonly ICloudStorageFactory _cloudStorageFactory;

// Constructor parameter
ICloudStorageFactory cloudStorageFactory

// Constructor body
_cloudStorageFactory = cloudStorageFactory;

// StartupExtensions - add to required services
typeof(ICloudStorageFactory)

// Usage
var storage = _cloudStorageFactory.Create(_settings.StorageProvider);
await storage.UploadAsync(stream, path, cancellationToken);
```

## IMessageQueueFactory

[Ruya.Services.MessageQueue](https://github.com/cilerler/ruya#message-queue) is the reference implementation for the API shape below.

```csharp
// Field
private readonly IMessageQueueFactory _messageQueueFactory;

// Constructor parameter
IMessageQueueFactory messageQueueFactory

// Constructor body
_messageQueueFactory = messageQueueFactory;

// StartupExtensions - add to required services
typeof(IMessageQueueFactory)

// Publish usage
var queue = await _messageQueueFactory.CreateQueueAsync(
    _settings.MessageQueueProviderName,
    cancellationToken);
await queue.PublishAsync(
    Constants.Topics.{EventName},
    message,
    cancellationToken: cancellationToken);
```

The factory owns the named queue instance. Code that calls `CreateQueueAsync` does not dispose that shared queue.

### Long-lived subscriptions

A broker subscriber is a thin, event-driven `BackgroundService` adapter. Do not derive it from `WorkerBackgroundService`: a subscription remains open and the broker owns delivery timing, concurrency, and redelivery rather than the cron/polling loop.

```csharp
public sealed class {EventName}Subscriber : BackgroundService
{
    private readonly IMessageQueueFactory _messageQueueFactory;
    private readonly IServiceScopeFactory _scopeFactory;
    private readonly {ServiceName}Settings _settings;

    public {EventName}Subscriber(
        IMessageQueueFactory messageQueueFactory,
        IServiceScopeFactory scopeFactory,
        IOptions<{ServiceName}Settings> options)
    {
        _messageQueueFactory = messageQueueFactory;
        _scopeFactory = scopeFactory;
        _settings = options.Value;
    }

    protected override async Task ExecuteAsync(CancellationToken stoppingToken)
    {
        var queue = await _messageQueueFactory.CreateQueueAsync(
            _settings.MessageQueueProviderName,
            stoppingToken);

        await using var subscription = await queue.SubscribeAsync<{EventName}>(
            Constants.Topics.{EventName},
            HandleAsync,
            cancellationToken: stoppingToken);

        try
        {
            await Task.Delay(Timeout.InfiniteTimeSpan, stoppingToken);
        }
        catch (OperationCanceledException) when (stoppingToken.IsCancellationRequested)
        {
            // Normal host shutdown. Exiting the scope disposes the live subscription.
        }
    }

    private async Task<MessageResult> HandleAsync(MessageContext<{EventName}> context)
    {
        await using var scope = _scopeFactory.CreateAsyncScope();
        var service = scope.ServiceProvider.GetRequiredService<I{ServiceName}>();

        await service.ProcessAsync(context.Envelope.Payload, context.CancellationToken);
        return MessageResult.Success();
    }
}
```

The subscriber owns and asynchronously disposes the returned `IMessageSubscription`; the cancellation token alone does not replace that ownership. Keep business logic in `I{ServiceName}` or a scoped handler. Map known transient failures to `MessageResult.Retry` and invalid/permanent messages to `MessageResult.Reject` according to the service's delivery policy. Instrument message processing with [`ActivityKind.Consumer`](../../observability/SKILL.md#activity-kinds); queue age/depth, retry/reject rate, DLQ depth, and subscription health are owned by the observability model.

## DbContext (Direct)

```csharp
// Field
private readonly MyDbContext _dbContext;

// Constructor parameter
MyDbContext dbContext

// Constructor body
_dbContext = dbContext;

// Service lifetime: Scoped (required for DbContext)

// Usage
var entities = await _dbContext.MyEntities
    .Where(e => e.IsActive)
    .ToListAsync(cancellationToken);
```

## Repository/UoW Pattern

```csharp
// Field
private readonly IUnitOfWork _unitOfWork;

// Constructor parameter
IUnitOfWork unitOfWork

// Constructor body
_unitOfWork = unitOfWork;

// StartupExtensions - add to required services
typeof(IUnitOfWork)

// Service lifetime: Scoped

// Usage
var repository = _unitOfWork.GetRepository<MyEntity>();
var entities = await repository.GetAllAsync(cancellationToken);
await _unitOfWork.SaveChangesAsync(cancellationToken);
```

## Combined Example

Service with multiple optional dependencies:

```csharp
public class {ServiceName}Service : I{ServiceName}
{
    private readonly ILogger<{ServiceName}Service> _logger;
    private readonly IDistributedTracing _tracer;
    private readonly Meter _meter;
    private readonly {ServiceName}Settings _settings;
    
    // Optional (alphabetical)
    private readonly IDistributedCache _distributedCache;
    private readonly HttpClient _httpClient;
    private readonly HybridCache _hybridCache;

    public {ServiceName}Service(
        ILogger<{ServiceName}Service> logger,
        IDistributedTracing distributedTracing,
        IMeterFactory meterFactory,
        IOptions<{ServiceName}Settings> options,
        // Optional (alphabetical)
        IDistributedCache distributedCache,
        IHttpClientFactory httpClientFactory,
        HybridCache hybridCache)
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
        
        _distributedCache = distributedCache;
        _httpClient = httpClientFactory.CreateClient(Constants.HttpClientName);
        _hybridCache = hybridCache;
    }
}
```
