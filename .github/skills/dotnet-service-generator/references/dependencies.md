# Optional Dependencies

Patterns for optional service dependencies. Add to constructor after core dependencies (ILogger, IDistributedTracing, IMeterFactory, IOptions) in alphabetical order.

## IHttpClientFactory

```csharp
// Field
private readonly HttpClient _httpClient;

// Constructor parameter
IHttpClientFactory httpClientFactory

// Constructor body
_httpClient = httpClientFactory.CreateClient(nameof({ServiceName}));

// StartupExtensions - add to required services
typeof(IHttpClientFactory)

// Usage
var response = await _httpClient.GetAsync(requestUri, cancellationToken);
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

```csharp
// Field
private readonly IMessageQueueFactory _messageQueueFactory;

// Constructor parameter
IMessageQueueFactory messageQueueFactory

// Constructor body
_messageQueueFactory = messageQueueFactory;

// StartupExtensions - add to required services
typeof(IMessageQueueFactory)

// Usage
var queue = _messageQueueFactory.Create(_settings.QueueName);
await queue.PublishAsync(message, cancellationToken);
```

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
public class {ServiceName} : I{ServiceName}
{
    private readonly ILogger<{ServiceName}> _logger;
    private readonly IDistributedTracing _tracer;
    private readonly Meter _meter;
    private readonly {ServiceName}Settings _settings;
    
    // Optional (alphabetical)
    private readonly IDistributedCache _distributedCache;
    private readonly HttpClient _httpClient;
    private readonly HybridCache _hybridCache;

    public {ServiceName}(
        ILogger<{ServiceName}> logger,
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
        _httpClient = httpClientFactory.CreateClient(nameof({ServiceName}));
        _hybridCache = hybridCache;
    }
}
```
