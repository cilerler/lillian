---
name: observability
description: Standard SLIs, dashboard templates, alert conventions, and OpenTelemetry patterns for .NET services. Use when working on dashboards, metrics, tracing, alerting, SLIs, or any observability concern.
type: guidance
applies_to:
  - Architect
  - Developer
mandatory: conditional
triggers:
  - dashboard
  - metrics
  - tracing
  - alerting
  - SLI
  - observability
references:
  - templates/grafana-dashboard.md
summary: Standard SLIs, dashboard templates, alert conventions, and OpenTelemetry patterns for .NET services.
---

# Observability Skill

Defines observability standards for .NET services including SLIs, dashboards, alerts, and instrumentation patterns.

## Roles

- **Architect**: Defines observability requirements in technical design
- **Developer**: Implements per Architect's specifications

---

## Standard SLIs

### API / HTTP Services

| SLI | Description | Target | Measurement |
|-----|-------------|--------|-------------|
| Latency p50 | Median response time | < 100ms | Histogram quantile |
| Latency p95 | 95th percentile response time | < 500ms | Histogram quantile |
| Latency p99 | 99th percentile response time | < 1000ms | Histogram quantile |
| Error Rate | 5xx responses / total requests | < 0.1% | Counter ratio |
| Availability | Successful health checks / total | > 99.9% | Uptime probe |
| Saturation | CPU/Memory utilization | < 80% | Resource metrics |
| Throughput | Requests per second | Service-specific | Counter rate |

### Background Workers

| SLI | Description | Target | Measurement |
|-----|-------------|--------|-------------|
| Execution Duration p50 | Median execution time | Service-specific | Histogram quantile |
| Execution Duration p95 | 95th percentile execution time | < 2× average | Histogram quantile |
| Failure Rate | Failed executions / total | < 1% | Counter ratio |
| Skip Rate | Skipped (overlapping) / total | < 0.1% | Counter ratio |
| Retry Rate | Retries / total executions | < 5% | Counter ratio |
| Availability | Successful health checks / total | > 99.9% | Uptime probe |
| Saturation | CPU/Memory utilization | < 80% | Resource metrics |

---

## Alert Thresholds

### Severity Levels

| Severity | Response | Examples |
|----------|----------|----------|
| **Critical** | Immediate page | Service down, data loss risk, SLA breach |
| **Warning** | Review within hours | Degraded performance, approaching limits |
| **Info** | Review next business day | Anomalies, capacity planning signals |

### Standard Thresholds

| Metric | Warning | Critical | For Duration |
|--------|---------|----------|--------------|
| Error rate | > 1% | > 5% | 5 min / 2 min |
| Latency p95 | > 1s | > 3s | 5 min / 2 min |
| Latency p99 | > 2s | > 5s | 5 min / 2 min |
| CPU usage | > 70% | > 90% | 10 min / 5 min |
| Memory usage | > 75% | > 90% | 10 min / 5 min |
| Queue depth | > 1000 | > 5000 | 5 min / 2 min |
| Queue age (oldest msg) | > 5 min | > 15 min | 5 min / 2 min |
| Health check failures | 1 failure | 3 consecutive | immediate / 1 min |
| Connection pool exhaustion | > 80% | > 95% | 5 min / 2 min |
| Worker execution failure rate | > 10% | > 25% | 5 min / 2 min |
| Worker skip rate | > 5/min | > 20/min | 5 min / 2 min |
| Worker retry rate | > 10/min | > 50/min | 5 min / 2 min |
| Worker execution duration p95 | > 2× avg | > 5× avg | 5 min / 2 min |

---

## Dashboard Templates

See [templates/grafana-dashboard.md](templates/grafana-dashboard.md) for complete Grafana JSON templates.

**Output locations** (dashboards live at the level they monitor) — full paths defined in [`solution-structure`](../solution-structure/SKILL.md) § *.NET Solution*:
- Service: `{ServicePath}/Observability/Grafana/dashboard.json`
- Component: `{ComponentPath}/Observability/Grafana/dashboard.json`
- Module: `{ModulePath}/Observability/Grafana/dashboard.json`
- App-wide: `src/Observability/Grafana/dashboard.json`

**Required**: All dashboards must include `env` template variable with values matching `ASPNETCORE_ENVIRONMENT`: `Integration`, `Testing`, `Staging`, `Production`. All PromQL queries must filter by `env="$env"`.

### Service Health Dashboard

Required panels:
1. **Request Rate** - req/s over time
2. **Error Rate** - % errors with breakdown by status code
3. **Latency Histogram** - p50, p95, p99 percentiles
4. **Active Connections** - Current connection count
5. **Health Check Status** - Liveness and readiness state
6. **Instance Count** - Number of running replicas

### API Performance Dashboard

Required panels:
1. **Endpoint Latency Breakdown** - Latency by endpoint
2. **Top 10 Slowest Endpoints** - Sorted by p95 latency
3. **Error Breakdown by Status Code** - 4xx vs 5xx distribution
4. **Request Volume by Endpoint** - Traffic distribution
5. **Request Duration Heatmap** - Time vs latency visualization

### Background Worker Dashboard

Required panels for services extending `WorkerBackgroundService<TSettings>`:
1. **Execution Rate** - Executions per second over time
2. **Success / Failure Ratio** - Stacked success vs failed executions
3. **Active Executions** - Currently running executions gauge
4. **Skip Rate** - Skipped executions (previous still running)
5. **Retry Rate** - Retry attempts over time
6. **Execution Duration** - p50, p95, p99 percentiles from histogram

### Resource Usage Dashboard

Required panels:
1. **CPU Utilization** - Per instance over time
2. **Memory Usage** - Heap, working set, GC metrics
3. **GC Metrics** - Gen0/Gen1/Gen2 collections, pause times
4. **Thread Pool** - Worker threads, completion port threads
5. **Connection Pools** - Database, HTTP client pool saturation
6. **Disk I/O** - If applicable

---

## OpenTelemetry Patterns

Use `MyOrganization.OpenTelemetry` library. See [README](common-libraries/MyOrganization.OpenTelemetry/README.md).

### Observability Triad

All services should inject these three interfaces for complete observability:

| Interface | Purpose | Usage |
|-----------|---------|-------|
| `ILogger<T>` | Structured logging | Log events with contextual data |
| `IDistributedTracing` | Distributed tracing | Create spans/activities for operations |
| `IMeterFactory` | Metrics | Create counters, histograms, gauges |

Constructor pattern:
```csharp
public MyService(
    ILogger<MyService> logger,
    IDistributedTracing distributedTracing,
    IMeterFactory meterFactory)
```

### Log Levels

Every operation should be logged to provide a complete activity flow. Use the appropriate level:

| LogLevel | Value | When to Use |
|----------|-------|-------------|
| `Trace` | 0 | Most detailed messages. May contain sensitive data. Disabled by default; never enable in production. |
| `Debug` | 1 | Debugging and development. Use with caution in production due to high volume. |
| `Information` | 2 | General flow of the application. May have long-term value. |
| `Warning` | 3 | Abnormal or unexpected events. Errors or conditions that don't cause the app to fail. |
| `Error` | 4 | Errors and exceptions that cannot be handled. Failure in the current operation or request, not app-wide. |
| `Critical` | 5 | Failures requiring immediate attention (data loss, out of disk space). |
| `None` | 6 | Suppresses all logging for a category. |

Severity increases from Trace (lowest) to Critical (highest).

### Activity Kinds

When creating OpenTelemetry activities/spans, choose the correct `ActivityKind`:

| Kind | When to Use |
|------|-------------|
| `ActivityKind.Client` | Making a synchronous outbound call to an external system (DB, HTTP, gRPC) |
| `ActivityKind.Server` | Handling an incoming synchronous request |
| `ActivityKind.Producer` | Initiating an asynchronous request — sending a message to a queue, pub/sub topic, or event bus |
| `ActivityKind.Consumer` | Processing a message received asynchronously from a queue, pub/sub topic, or event bus |
| `ActivityKind.Internal` | In-process operation with no external call (default) |

Example:
```csharp
using var activity = _tracer.StartActivity("ProcessItem", ActivityKind.Internal);
using var dbActivity = _tracer.StartActivity("QueryDatabase", ActivityKind.Client);
```

### Registration

```csharp
// Program.cs
builder.ConfigureOpenTelemetry();
```

### Environment Attribution

The OpenTelemetry library is expected to automatically set `deployment.environment` as a resource attribute on all telemetry (metrics, traces, logs) using `builder.Environment.EnvironmentName`. This value comes from `ASPNETCORE_ENVIRONMENT` (set per environment in K8s overlays) and is what Grafana dashboards filter on via the `$env` template variable.

For traces, an activity processor should also stamp each span with `deployment.environment` as a tag.

### Configuration

```json
{
  "OpenTelemetry": {
    "Service": {
      "Name": "{ServiceName}",
      "Version": "1.0.0",
      "Namespace": "{Namespace}"
    },
    "Http": {
      "RecordException": true,
      "CaptureBody": true
    },
    "Sql": {
      "CaptureParameters": true
    }
  },
  "OTEL_EXPORTER_OTLP_ENDPOINT": "http://otel-collector:4317"
}
```

### Middleware (Optional)

```csharp
app.UseRouting();
app.UseHttpBodyCapture(); // Must be after UseRouting
app.MapControllers();
```

### Instrumentation Example

Complete example combining all three: structured logging, distributed tracing, and custom metrics.

```csharp
public class MyService : IDisposable
{
    private readonly ILogger<MyService> _logger;
    private readonly IDistributedTracing _tracer;
    private readonly Meter _meter;
    private readonly Counter<long> _itemsProcessed;
    private readonly Histogram<double> _processingDuration;

    public MyService(
        ILogger<MyService> logger,
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
            "items_processed",
            unit: "{item}",
            description: "Number of items processed");

        _processingDuration = _meter.CreateHistogram<double>(
            "processing_duration",
            unit: "ms",
            description: "Time to process an item");
    }

    public async Task ProcessAsync(Item item)
    {
        using var activity = _tracer.StartActivity("ProcessItem");
        activity.SetTag("item.id", item.Id);
        activity.SetTag("item.type", item.Type);
        var sw = Stopwatch.StartNew();

        try
        {
            _logger.LogDebug("Processing item {ItemId}", item.Id);
            // Process item
            _itemsProcessed.Add(1, new TagList { { "status", "success" } });
            activity.SetStatus(ActivityStatusCode.Ok);
        }
        catch (Exception ex)
        {
            _itemsProcessed.Add(1, new TagList { { "status", "failure" } });
            activity.SetStatus(ActivityStatusCode.Error, ex.Message);
            activity.SetTag("exception.type", ex.GetType().FullName);
            activity.SetTag("exception.message", ex.Message);
            _logger.LogError(ex, "Failed to process item {ItemId}", item.Id);
            throw;
        }
        finally
        {
            _processingDuration.Record(sw.ElapsedMilliseconds);
        }
    }

    public void Dispose()
    {
        _meter.Dispose();
        GC.SuppressFinalize(this);
    }
}
```

### Semantic Conventions

Use OpenTelemetry semantic conventions for tag names:

| Category | Convention | Example |
|----------|------------|---------|
| HTTP | `http.request.method`, `http.response.status_code`, `url.full` | `http.request.method=POST` |
| Database | `db.system`, `db.namespace`, `db.query.text` | `db.system=mssql` |
| Messaging | `messaging.system`, `messaging.destination.name` | `messaging.system=rabbitmq` |
| Exception | `exception.type`, `exception.message` | `exception.type=InvalidOperationException` |

---

## Architect Checklist

When defining observability requirements in technical design:

1. [ ] Which SLIs matter for this service?
2. [ ] What are the target values for each SLI?
3. [ ] Which dashboards are required?
4. [ ] What alert conditions and thresholds apply?
5. [ ] What custom metrics are needed?
6. [ ] What traces should be captured?
7. [ ] What log levels and structured fields are required?

---

## Developer Checklist

When implementing observability:

1. [ ] OpenTelemetry configured via `ConfigureOpenTelemetry()`
2. [ ] Service name and version set in configuration
3. [ ] Custom metrics created per Architect's requirements
4. [ ] Critical operations have traces with appropriate tags
5. [ ] Structured logging with event IDs for significant operations
6. [ ] Grafana dashboard JSON created
7. [ ] Alert rules configured
8. [ ] Runbook draft includes observability section
