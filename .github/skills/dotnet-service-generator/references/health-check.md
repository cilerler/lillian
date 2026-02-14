# Health Check Pattern

Custom health checks for services using `IHealthCheck`.

## HealthCheck.cs

```csharp
namespace {Organization}.{Product}.Services.{ServiceName};

public class {ServiceName}HealthCheck : IHealthCheck
{
    private readonly I{ServiceName} _service;
    private readonly {ServiceName}Settings _settings;

    public {ServiceName}HealthCheck(
        I{ServiceName} service,
        IOptions<{ServiceName}Settings> options)
    {
        _service = service;
        _settings = options.Value;
    }

    public async Task<HealthCheckResult> CheckHealthAsync(
        HealthCheckContext context,
        CancellationToken cancellationToken = default)
    {
        if (!_settings.Enabled)
        {
            return HealthCheckResult.Healthy("Service disabled.");
        }

        try
        {
            // Service-specific health validation
            var isHealthy = await _service.IsHealthyAsync(cancellationToken);
            
            return isHealthy
                ? HealthCheckResult.Healthy()
                : HealthCheckResult.Unhealthy("Service health check failed.");
        }
        catch (Exception ex)
        {
            return HealthCheckResult.Unhealthy("Health check exception.", ex);
        }
    }
}
```

## Registration in StartupExtensions.cs

```csharp
services.AddHealthChecks()
    .AddCheck<{ServiceName}HealthCheck>("{ServiceName}", tags: ["ready"]);
```

## Common Health Check Patterns

### Dependency Check
```csharp
public async Task<HealthCheckResult> CheckHealthAsync(
    HealthCheckContext context,
    CancellationToken cancellationToken = default)
{
    try
    {
        using var cts = CancellationTokenSource.CreateLinkedTokenSource(cancellationToken);
        cts.CancelAfter(TimeSpan.FromSeconds(5));
        
        await _httpClient.GetAsync("/health", cts.Token);
        return HealthCheckResult.Healthy();
    }
    catch (Exception ex)
    {
        return HealthCheckResult.Unhealthy("Dependency unavailable.", ex);
    }
}
```

### Cache Connectivity
```csharp
public async Task<HealthCheckResult> CheckHealthAsync(
    HealthCheckContext context,
    CancellationToken cancellationToken = default)
{
    try
    {
        var testKey = $"health:{Guid.NewGuid()}";
        await _distributedCache.SetStringAsync(testKey, "ok", cancellationToken);
        await _distributedCache.RemoveAsync(testKey, cancellationToken);
        return HealthCheckResult.Healthy();
    }
    catch (Exception ex)
    {
        return HealthCheckResult.Unhealthy("Cache unavailable.", ex);
    }
}
```

### Database Connectivity
```csharp
public async Task<HealthCheckResult> CheckHealthAsync(
    HealthCheckContext context,
    CancellationToken cancellationToken = default)
{
    try
    {
        await _dbContext.Database.CanConnectAsync(cancellationToken);
        return HealthCheckResult.Healthy();
    }
    catch (Exception ex)
    {
        return HealthCheckResult.Unhealthy("Database unavailable.", ex);
    }
}
```

## Tags

| Tag | Purpose |
|-----|---------|
| `ready` | Readiness probe - can accept traffic |
| `live` | Liveness probe - process is running |
| `startup` | Startup probe - initialization complete |
