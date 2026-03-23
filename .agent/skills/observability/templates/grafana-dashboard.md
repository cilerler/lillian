# Grafana Dashboard Templates

Grafana dashboard JSON templates for .NET services with environment separation.

---

## Output Directory

```
tools/grafana/
├── service-health-dashboard.json
├── api-performance-dashboard.json
├── background-worker-dashboard.json
└── resource-usage-dashboard.json
```

---

## Standard Template Variables

Every dashboard **must** include these three Grafana template variables. Place them in the `templating.list` array.

### datasource

```json
{
  "name": "datasource",
  "type": "datasource",
  "query": "prometheus",
  "current": { "text": "default", "value": "default" },
  "hide": 0,
  "label": "Datasource"
}
```

### env

```json
{
  "name": "env",
  "type": "custom",
  "query": "Integration,Testing,Staging,Production",
  "current": { "text": "Production", "value": "Production" },
  "options": [
    { "text": "Integration", "value": "Integration", "selected": false },
    { "text": "Testing", "value": "Testing", "selected": false },
    { "text": "Staging", "value": "Staging", "selected": false },
    { "text": "Production", "value": "Production", "selected": true }
  ],
  "hide": 0,
  "label": "Environment",
  "includeAll": false,
  "multi": false
}
```

### service

```json
{
  "name": "service",
  "type": "query",
  "datasource": { "type": "prometheus", "uid": "$datasource" },
  "query": "label_values(http_server_request_duration_seconds_count{env=\"$env\"}, service_name)",
  "current": {},
  "hide": 0,
  "label": "Service",
  "includeAll": false,
  "multi": false,
  "refresh": 2,
  "sort": 1
}
```

---

## PromQL Query Patterns

All queries **must** include `env="$env"` and `service_name="$service"` selectors.

### Request Rate

```promql
sum(rate(http_server_request_duration_seconds_count{env="$env", service_name="$service"}[5m]))
```

### Error Rate (%)

```promql
sum(rate(http_server_request_duration_seconds_count{env="$env", service_name="$service", http_response_status_code=~"5.."}[5m]))
/
sum(rate(http_server_request_duration_seconds_count{env="$env", service_name="$service"}[5m]))
* 100
```

### Error Rate by Status Code

```promql
sum by (http_response_status_code) (rate(http_server_request_duration_seconds_count{env="$env", service_name="$service", http_response_status_code=~"[45].."}[5m]))
```

### Latency Percentiles

```promql
# p50
histogram_quantile(0.50, sum by (le) (rate(http_server_request_duration_seconds_bucket{env="$env", service_name="$service"}[5m])))

# p95
histogram_quantile(0.95, sum by (le) (rate(http_server_request_duration_seconds_bucket{env="$env", service_name="$service"}[5m])))

# p99
histogram_quantile(0.99, sum by (le) (rate(http_server_request_duration_seconds_bucket{env="$env", service_name="$service"}[5m])))
```

### Active Connections

```promql
sum(http_server_active_requests{env="$env", service_name="$service"})
```

### Endpoint Latency Breakdown

```promql
histogram_quantile(0.95, sum by (le, http_route) (rate(http_server_request_duration_seconds_bucket{env="$env", service_name="$service"}[5m])))
```

### Request Volume by Endpoint

```promql
sum by (http_route) (rate(http_server_request_duration_seconds_count{env="$env", service_name="$service"}[5m]))
```

### CPU Utilization

```promql
rate(process_cpu_seconds_total{env="$env", service_name="$service"}[5m]) * 100
```

### Memory Usage

```promql
process_runtime_dotnet_gc_heap_size_bytes{env="$env", service_name="$service"}
```

### GC Collections

```promql
sum by (generation) (rate(process_runtime_dotnet_gc_collections_total{env="$env", service_name="$service"}[5m]))
```

### Thread Pool

```promql
process_runtime_dotnet_thread_pool_threads_count{env="$env", service_name="$service"}
```

### Background Worker - Execution Rate

```promql
sum(rate(app_${worker}_total{env="$env", service_name="$service"}[5m]))
```

### Background Worker - Success / Failure Rate

```promql
# Success rate
sum(rate(app_${worker}_success{env="$env", service_name="$service"}[5m]))

# Failure rate
sum(rate(app_${worker}_failed{env="$env", service_name="$service"}[5m]))
```

### Background Worker - Failure Ratio (%)

```promql
sum(rate(app_${worker}_failed{env="$env", service_name="$service"}[5m]))
/
sum(rate(app_${worker}_total{env="$env", service_name="$service"}[5m]))
* 100
```

### Background Worker - Active Executions

```promql
sum(app_${worker}_active{env="$env", service_name="$service"})
```

### Background Worker - Skipped Executions

```promql
sum(rate(app_${worker}_skipped{env="$env", service_name="$service"}[5m]))
```

### Background Worker - Retry Rate

```promql
sum(rate(app_${worker}_retries{env="$env", service_name="$service"}[5m]))
```

### Background Worker - Duration Percentiles

```promql
# p50
histogram_quantile(0.50, sum by (le) (rate(app_${worker}_duration_seconds_bucket{env="$env", service_name="$service"}[5m])))

# p95
histogram_quantile(0.95, sum by (le) (rate(app_${worker}_duration_seconds_bucket{env="$env", service_name="$service"}[5m])))

# p99
histogram_quantile(0.99, sum by (le) (rate(app_${worker}_duration_seconds_bucket{env="$env", service_name="$service"}[5m])))
```

> **Note**: `${worker}` is the snake_case service class name (e.g., `payment_processor` for `PaymentProcessor`). The base class generates metric names as `app_{snake_case_class_name}_{metric}`.

---

## Service Health Dashboard

Full template. Replace `$(SERVICE_NAME)` with the actual service name.

```json
{
  "uid": "$(SERVICE_NAME)-health",
  "title": "$(SERVICE_NAME) - Service Health",
  "tags": ["generated", "service-health"],
  "timezone": "browser",
  "editable": true,
  "fiscalYearStartMonth": 0,
  "graphTooltip": 1,
  "refresh": "30s",
  "schemaVersion": 39,
  "templating": {
    "list": [
      {
        "name": "datasource",
        "type": "datasource",
        "query": "prometheus",
        "current": { "text": "default", "value": "default" },
        "hide": 0,
        "label": "Datasource"
      },
      {
        "name": "env",
        "type": "custom",
        "query": "Integration,Testing,Staging,Production",
        "current": { "text": "Production", "value": "Production" },
        "options": [
          { "text": "Integration", "value": "Integration", "selected": false },
          { "text": "Testing", "value": "Testing", "selected": false },
          { "text": "Staging", "value": "Staging", "selected": false },
          { "text": "Production", "value": "Production", "selected": true }
        ],
        "hide": 0,
        "label": "Environment",
        "includeAll": false,
        "multi": false
      },
      {
        "name": "service",
        "type": "query",
        "datasource": { "type": "prometheus", "uid": "$datasource" },
        "query": "label_values(http_server_request_duration_seconds_count{env=\"$env\"}, service_name)",
        "current": {},
        "hide": 0,
        "label": "Service",
        "includeAll": false,
        "multi": false,
        "refresh": 2,
        "sort": 1
      }
    ]
  },
  "panels": [
    {
      "title": "Request Rate",
      "type": "timeseries",
      "gridPos": { "h": 8, "w": 8, "x": 0, "y": 0 },
      "datasource": { "type": "prometheus", "uid": "$datasource" },
      "targets": [
        {
          "expr": "sum(rate(http_server_request_duration_seconds_count{env=\"$env\", service_name=\"$service\"}[5m]))",
          "legendFormat": "req/s",
          "refId": "A"
        }
      ],
      "fieldConfig": {
        "defaults": {
          "unit": "reqps",
          "custom": { "fillOpacity": 10, "lineWidth": 2 }
        }
      }
    },
    {
      "title": "Error Rate",
      "type": "timeseries",
      "gridPos": { "h": 8, "w": 8, "x": 8, "y": 0 },
      "datasource": { "type": "prometheus", "uid": "$datasource" },
      "targets": [
        {
          "expr": "sum(rate(http_server_request_duration_seconds_count{env=\"$env\", service_name=\"$service\", http_response_status_code=~\"5..\"}[5m])) / sum(rate(http_server_request_duration_seconds_count{env=\"$env\", service_name=\"$service\"}[5m])) * 100",
          "legendFormat": "error %",
          "refId": "A"
        }
      ],
      "fieldConfig": {
        "defaults": {
          "unit": "percent",
          "custom": { "fillOpacity": 10, "lineWidth": 2 },
          "thresholds": {
            "steps": [
              { "color": "green", "value": null },
              { "color": "yellow", "value": 1 },
              { "color": "red", "value": 5 }
            ]
          }
        }
      }
    },
    {
      "title": "Latency Percentiles",
      "type": "timeseries",
      "gridPos": { "h": 8, "w": 8, "x": 16, "y": 0 },
      "datasource": { "type": "prometheus", "uid": "$datasource" },
      "targets": [
        {
          "expr": "histogram_quantile(0.50, sum by (le) (rate(http_server_request_duration_seconds_bucket{env=\"$env\", service_name=\"$service\"}[5m])))",
          "legendFormat": "p50",
          "refId": "A"
        },
        {
          "expr": "histogram_quantile(0.95, sum by (le) (rate(http_server_request_duration_seconds_bucket{env=\"$env\", service_name=\"$service\"}[5m])))",
          "legendFormat": "p95",
          "refId": "B"
        },
        {
          "expr": "histogram_quantile(0.99, sum by (le) (rate(http_server_request_duration_seconds_bucket{env=\"$env\", service_name=\"$service\"}[5m])))",
          "legendFormat": "p99",
          "refId": "C"
        }
      ],
      "fieldConfig": {
        "defaults": {
          "unit": "s",
          "custom": { "fillOpacity": 10, "lineWidth": 2 }
        }
      }
    },
    {
      "title": "Active Connections",
      "type": "timeseries",
      "gridPos": { "h": 8, "w": 8, "x": 0, "y": 8 },
      "datasource": { "type": "prometheus", "uid": "$datasource" },
      "targets": [
        {
          "expr": "sum(http_server_active_requests{env=\"$env\", service_name=\"$service\"})",
          "legendFormat": "active",
          "refId": "A"
        }
      ],
      "fieldConfig": {
        "defaults": {
          "unit": "short",
          "custom": { "fillOpacity": 10, "lineWidth": 2 }
        }
      }
    },
    {
      "title": "Health Check Status",
      "type": "stat",
      "gridPos": { "h": 8, "w": 8, "x": 8, "y": 8 },
      "datasource": { "type": "prometheus", "uid": "$datasource" },
      "targets": [
        {
          "expr": "min(up{env=\"$env\", service_name=\"$service\"})",
          "legendFormat": "health",
          "refId": "A"
        }
      ],
      "fieldConfig": {
        "defaults": {
          "mappings": [
            { "type": "value", "options": { "0": { "text": "DOWN", "color": "red" }, "1": { "text": "UP", "color": "green" } } }
          ],
          "thresholds": {
            "steps": [
              { "color": "red", "value": null },
              { "color": "green", "value": 1 }
            ]
          }
        }
      }
    },
    {
      "title": "Instance Count",
      "type": "stat",
      "gridPos": { "h": 8, "w": 8, "x": 16, "y": 8 },
      "datasource": { "type": "prometheus", "uid": "$datasource" },
      "targets": [
        {
          "expr": "count(up{env=\"$env\", service_name=\"$service\"} == 1)",
          "legendFormat": "instances",
          "refId": "A"
        }
      ],
      "fieldConfig": {
        "defaults": { "unit": "short" }
      }
    }
  ],
  "time": { "from": "now-1h", "to": "now" }
}
```

---

## API Performance Dashboard

Replace `$(SERVICE_NAME)` with the actual service name. Uses the same template variables as Service Health.

### Panel Definitions

| Panel | Type | Query Summary |
|-------|------|---------------|
| Endpoint Latency Breakdown | timeseries | `histogram_quantile(0.95, ... by (le, http_route) ...)` |
| Top 10 Slowest Endpoints | bar gauge | `topk(10, histogram_quantile(0.95, ... by (le, http_route) ...))` |
| Error Breakdown by Status Code | timeseries | `sum by (http_response_status_code) (rate(...{status=~"[45].."}...))` |
| Request Volume by Endpoint | timeseries | `sum by (http_route) (rate(..._count{...}[5m]))` |
| Request Duration Heatmap | heatmap | `sum by (le) (increase(..._bucket{...}[5m]))` |

### Dashboard Shell

```json
{
  "uid": "$(SERVICE_NAME)-api-perf",
  "title": "$(SERVICE_NAME) - API Performance",
  "tags": ["generated", "api-performance"],
  "timezone": "browser",
  "editable": true,
  "graphTooltip": 1,
  "refresh": "30s",
  "schemaVersion": 39,
  "templating": {
    "list": [
      "<<< same datasource, env, service variables as Service Health >>>"
    ]
  },
  "panels": [
    {
      "title": "Endpoint Latency Breakdown (p95)",
      "type": "timeseries",
      "gridPos": { "h": 8, "w": 12, "x": 0, "y": 0 },
      "datasource": { "type": "prometheus", "uid": "$datasource" },
      "targets": [
        {
          "expr": "histogram_quantile(0.95, sum by (le, http_route) (rate(http_server_request_duration_seconds_bucket{env=\"$env\", service_name=\"$service\"}[5m])))",
          "legendFormat": "{{ http_route }}",
          "refId": "A"
        }
      ],
      "fieldConfig": { "defaults": { "unit": "s" } }
    },
    {
      "title": "Top 10 Slowest Endpoints",
      "type": "bargauge",
      "gridPos": { "h": 8, "w": 12, "x": 12, "y": 0 },
      "datasource": { "type": "prometheus", "uid": "$datasource" },
      "targets": [
        {
          "expr": "topk(10, histogram_quantile(0.95, sum by (le, http_route) (rate(http_server_request_duration_seconds_bucket{env=\"$env\", service_name=\"$service\"}[5m]))))",
          "legendFormat": "{{ http_route }}",
          "refId": "A",
          "instant": true
        }
      ],
      "fieldConfig": { "defaults": { "unit": "s" } },
      "options": { "orientation": "horizontal" }
    },
    {
      "title": "Error Breakdown by Status Code",
      "type": "timeseries",
      "gridPos": { "h": 8, "w": 12, "x": 0, "y": 8 },
      "datasource": { "type": "prometheus", "uid": "$datasource" },
      "targets": [
        {
          "expr": "sum by (http_response_status_code) (rate(http_server_request_duration_seconds_count{env=\"$env\", service_name=\"$service\", http_response_status_code=~\"[45]..\"}[5m]))",
          "legendFormat": "{{ http_response_status_code }}",
          "refId": "A"
        }
      ],
      "fieldConfig": { "defaults": { "unit": "reqps" } }
    },
    {
      "title": "Request Volume by Endpoint",
      "type": "timeseries",
      "gridPos": { "h": 8, "w": 12, "x": 12, "y": 8 },
      "datasource": { "type": "prometheus", "uid": "$datasource" },
      "targets": [
        {
          "expr": "sum by (http_route) (rate(http_server_request_duration_seconds_count{env=\"$env\", service_name=\"$service\"}[5m]))",
          "legendFormat": "{{ http_route }}",
          "refId": "A"
        }
      ],
      "fieldConfig": { "defaults": { "unit": "reqps" } }
    },
    {
      "title": "Request Duration Heatmap",
      "type": "heatmap",
      "gridPos": { "h": 8, "w": 24, "x": 0, "y": 16 },
      "datasource": { "type": "prometheus", "uid": "$datasource" },
      "targets": [
        {
          "expr": "sum by (le) (increase(http_server_request_duration_seconds_bucket{env=\"$env\", service_name=\"$service\"}[5m]))",
          "legendFormat": "{{ le }}",
          "refId": "A",
          "format": "heatmap"
        }
      ],
      "options": {
        "calculate": false,
        "yAxis": { "unit": "s" }
      }
    }
  ],
  "time": { "from": "now-1h", "to": "now" }
}
```

---

## Resource Usage Dashboard

Replace `$(SERVICE_NAME)` with the actual service name. Uses the same template variables as Service Health, plus an `instance` variable.

### Additional Template Variable

```json
{
  "name": "instance",
  "type": "query",
  "datasource": { "type": "prometheus", "uid": "$datasource" },
  "query": "label_values(process_cpu_seconds_total{env=\"$env\", service_name=\"$service\"}, instance)",
  "current": {},
  "hide": 0,
  "label": "Instance",
  "includeAll": true,
  "multi": true,
  "refresh": 2,
  "sort": 1
}
```

### Panel Definitions

| Panel | Type | Query Summary |
|-------|------|---------------|
| CPU Utilization | timeseries | `rate(process_cpu_seconds_total{...}[5m]) * 100` |
| Memory Usage | timeseries | `process_runtime_dotnet_gc_heap_size_bytes` + `process_memory_virtual_bytes` |
| GC Collections | timeseries | `sum by (generation) (rate(process_runtime_dotnet_gc_collections_total{...}[5m]))` |
| GC Pause Time | timeseries | `rate(process_runtime_dotnet_gc_pause_time_seconds_total{...}[5m])` |
| Thread Pool | timeseries | `process_runtime_dotnet_thread_pool_threads_count` + `process_runtime_dotnet_thread_pool_queue_length` |
| Connection Pools | timeseries | `db_client_connections_usage` (if available) |

### Dashboard Shell

```json
{
  "uid": "$(SERVICE_NAME)-resources",
  "title": "$(SERVICE_NAME) - Resource Usage",
  "tags": ["generated", "resource-usage"],
  "timezone": "browser",
  "editable": true,
  "graphTooltip": 1,
  "refresh": "30s",
  "schemaVersion": 39,
  "templating": {
    "list": [
      "<<< same datasource, env, service variables as Service Health >>>",
      "<<< plus instance variable defined above >>>"
    ]
  },
  "panels": [
    {
      "title": "CPU Utilization",
      "type": "timeseries",
      "gridPos": { "h": 8, "w": 12, "x": 0, "y": 0 },
      "datasource": { "type": "prometheus", "uid": "$datasource" },
      "targets": [
        {
          "expr": "rate(process_cpu_seconds_total{env=\"$env\", service_name=\"$service\", instance=~\"$instance\"}[5m]) * 100",
          "legendFormat": "{{ instance }}",
          "refId": "A"
        }
      ],
      "fieldConfig": {
        "defaults": {
          "unit": "percent",
          "thresholds": {
            "steps": [
              { "color": "green", "value": null },
              { "color": "yellow", "value": 70 },
              { "color": "red", "value": 90 }
            ]
          }
        }
      }
    },
    {
      "title": "Memory Usage",
      "type": "timeseries",
      "gridPos": { "h": 8, "w": 12, "x": 12, "y": 0 },
      "datasource": { "type": "prometheus", "uid": "$datasource" },
      "targets": [
        {
          "expr": "process_runtime_dotnet_gc_heap_size_bytes{env=\"$env\", service_name=\"$service\", instance=~\"$instance\"}",
          "legendFormat": "{{ instance }} heap",
          "refId": "A"
        },
        {
          "expr": "process_memory_virtual_bytes{env=\"$env\", service_name=\"$service\", instance=~\"$instance\"}",
          "legendFormat": "{{ instance }} virtual",
          "refId": "B"
        }
      ],
      "fieldConfig": { "defaults": { "unit": "bytes" } }
    },
    {
      "title": "GC Collections",
      "type": "timeseries",
      "gridPos": { "h": 8, "w": 12, "x": 0, "y": 8 },
      "datasource": { "type": "prometheus", "uid": "$datasource" },
      "targets": [
        {
          "expr": "sum by (generation) (rate(process_runtime_dotnet_gc_collections_total{env=\"$env\", service_name=\"$service\", instance=~\"$instance\"}[5m]))",
          "legendFormat": "gen{{ generation }}",
          "refId": "A"
        }
      ],
      "fieldConfig": { "defaults": { "unit": "ops" } }
    },
    {
      "title": "GC Pause Time",
      "type": "timeseries",
      "gridPos": { "h": 8, "w": 12, "x": 12, "y": 8 },
      "datasource": { "type": "prometheus", "uid": "$datasource" },
      "targets": [
        {
          "expr": "rate(process_runtime_dotnet_gc_pause_time_seconds_total{env=\"$env\", service_name=\"$service\", instance=~\"$instance\"}[5m])",
          "legendFormat": "{{ instance }}",
          "refId": "A"
        }
      ],
      "fieldConfig": { "defaults": { "unit": "s" } }
    },
    {
      "title": "Thread Pool",
      "type": "timeseries",
      "gridPos": { "h": 8, "w": 12, "x": 0, "y": 16 },
      "datasource": { "type": "prometheus", "uid": "$datasource" },
      "targets": [
        {
          "expr": "process_runtime_dotnet_thread_pool_threads_count{env=\"$env\", service_name=\"$service\", instance=~\"$instance\"}",
          "legendFormat": "{{ instance }} threads",
          "refId": "A"
        },
        {
          "expr": "process_runtime_dotnet_thread_pool_queue_length{env=\"$env\", service_name=\"$service\", instance=~\"$instance\"}",
          "legendFormat": "{{ instance }} queued",
          "refId": "B"
        }
      ],
      "fieldConfig": { "defaults": { "unit": "short" } }
    },
    {
      "title": "Connection Pools",
      "type": "timeseries",
      "gridPos": { "h": 8, "w": 12, "x": 12, "y": 16 },
      "datasource": { "type": "prometheus", "uid": "$datasource" },
      "targets": [
        {
          "expr": "db_client_connections_usage{env=\"$env\", service_name=\"$service\", instance=~\"$instance\", state=\"used\"}",
          "legendFormat": "{{ instance }} used",
          "refId": "A"
        },
        {
          "expr": "db_client_connections_usage{env=\"$env\", service_name=\"$service\", instance=~\"$instance\", state=\"idle\"}",
          "legendFormat": "{{ instance }} idle",
          "refId": "B"
        }
      ],
      "fieldConfig": { "defaults": { "unit": "short" } }
    }
  ],
  "time": { "from": "now-1h", "to": "now" }
}
```

---

## Background Worker Dashboard

For services extending `WorkerBackgroundService<TSettings>`. Replace `$(SERVICE_NAME)` with the actual service name and `$(WORKER)` with the snake_case class name (e.g., `payment_processor`).

### Additional Template Variable

```json
{
  "name": "worker",
  "type": "custom",
  "query": "$(WORKER)",
  "current": { "text": "$(WORKER)", "value": "$(WORKER)" },
  "hide": 2,
  "label": "Worker"
}
```

### Panel Definitions

| Panel | Type | Query Summary |
|-------|------|---------------|
| Execution Rate | timeseries | `sum(rate(app_${worker}_total{...}[5m]))` |
| Success / Failure Ratio | timeseries (stacked) | `sum(rate(app_${worker}_success{...}[5m]))` + `_failed` |
| Active Executions | stat | `sum(app_${worker}_active{...})` |
| Skip Rate | timeseries | `sum(rate(app_${worker}_skipped{...}[5m]))` |
| Retry Rate | timeseries | `sum(rate(app_${worker}_retries{...}[5m]))` |
| Execution Duration | timeseries | `histogram_quantile(0.50/0.95/0.99, ... app_${worker}_duration_seconds_bucket ...)` |

### Dashboard Shell

```json
{
  "uid": "$(SERVICE_NAME)-worker",
  "title": "$(SERVICE_NAME) - Background Worker",
  "tags": ["generated", "background-worker"],
  "timezone": "browser",
  "editable": true,
  "fiscalYearStartMonth": 0,
  "graphTooltip": 1,
  "refresh": "30s",
  "schemaVersion": 39,
  "templating": {
    "list": [
      {
        "name": "datasource",
        "type": "datasource",
        "query": "prometheus",
        "current": { "text": "default", "value": "default" },
        "hide": 0,
        "label": "Datasource"
      },
      {
        "name": "env",
        "type": "custom",
        "query": "Integration,Testing,Staging,Production",
        "current": { "text": "Production", "value": "Production" },
        "options": [
          { "text": "Integration", "value": "Integration", "selected": false },
          { "text": "Testing", "value": "Testing", "selected": false },
          { "text": "Staging", "value": "Staging", "selected": false },
          { "text": "Production", "value": "Production", "selected": true }
        ],
        "hide": 0,
        "label": "Environment",
        "includeAll": false,
        "multi": false
      },
      {
        "name": "service",
        "type": "query",
        "datasource": { "type": "prometheus", "uid": "$datasource" },
        "query": "label_values(app_$(WORKER)_total{env=\"$env\"}, service_name)",
        "current": {},
        "hide": 0,
        "label": "Service",
        "includeAll": false,
        "multi": false,
        "refresh": 2,
        "sort": 1
      },
      {
        "name": "worker",
        "type": "custom",
        "query": "$(WORKER)",
        "current": { "text": "$(WORKER)", "value": "$(WORKER)" },
        "hide": 2,
        "label": "Worker"
      }
    ]
  },
  "panels": [
    {
      "title": "Execution Rate",
      "type": "timeseries",
      "gridPos": { "h": 8, "w": 8, "x": 0, "y": 0 },
      "datasource": { "type": "prometheus", "uid": "$datasource" },
      "targets": [
        {
          "expr": "sum(rate(app_${worker}_total{env=\"$env\", service_name=\"$service\"}[5m]))",
          "legendFormat": "exec/s",
          "refId": "A"
        }
      ],
      "fieldConfig": {
        "defaults": {
          "unit": "ops",
          "custom": { "fillOpacity": 10, "lineWidth": 2 }
        }
      }
    },
    {
      "title": "Success / Failure Rate",
      "type": "timeseries",
      "gridPos": { "h": 8, "w": 8, "x": 8, "y": 0 },
      "datasource": { "type": "prometheus", "uid": "$datasource" },
      "targets": [
        {
          "expr": "sum(rate(app_${worker}_success{env=\"$env\", service_name=\"$service\"}[5m]))",
          "legendFormat": "success",
          "refId": "A"
        },
        {
          "expr": "sum(rate(app_${worker}_failed{env=\"$env\", service_name=\"$service\"}[5m]))",
          "legendFormat": "failed",
          "refId": "B"
        }
      ],
      "fieldConfig": {
        "defaults": {
          "unit": "ops",
          "custom": { "fillOpacity": 30, "lineWidth": 2, "stacking": { "mode": "normal" } }
        },
        "overrides": [
          { "matcher": { "id": "byName", "options": "success" }, "properties": [{ "id": "color", "value": { "fixedColor": "green", "mode": "fixed" } }] },
          { "matcher": { "id": "byName", "options": "failed" }, "properties": [{ "id": "color", "value": { "fixedColor": "red", "mode": "fixed" } }] }
        ]
      }
    },
    {
      "title": "Failure Ratio",
      "type": "timeseries",
      "gridPos": { "h": 8, "w": 8, "x": 16, "y": 0 },
      "datasource": { "type": "prometheus", "uid": "$datasource" },
      "targets": [
        {
          "expr": "sum(rate(app_${worker}_failed{env=\"$env\", service_name=\"$service\"}[5m])) / sum(rate(app_${worker}_total{env=\"$env\", service_name=\"$service\"}[5m])) * 100",
          "legendFormat": "failure %",
          "refId": "A"
        }
      ],
      "fieldConfig": {
        "defaults": {
          "unit": "percent",
          "custom": { "fillOpacity": 10, "lineWidth": 2 },
          "thresholds": {
            "steps": [
              { "color": "green", "value": null },
              { "color": "yellow", "value": 10 },
              { "color": "red", "value": 25 }
            ]
          }
        }
      }
    },
    {
      "title": "Active Executions",
      "type": "stat",
      "gridPos": { "h": 8, "w": 6, "x": 0, "y": 8 },
      "datasource": { "type": "prometheus", "uid": "$datasource" },
      "targets": [
        {
          "expr": "sum(app_${worker}_active{env=\"$env\", service_name=\"$service\"})",
          "legendFormat": "active",
          "refId": "A"
        }
      ],
      "fieldConfig": {
        "defaults": {
          "unit": "short",
          "thresholds": {
            "steps": [
              { "color": "green", "value": null },
              { "color": "yellow", "value": 2 },
              { "color": "red", "value": 5 }
            ]
          }
        }
      }
    },
    {
      "title": "Skip Rate",
      "type": "timeseries",
      "gridPos": { "h": 8, "w": 9, "x": 6, "y": 8 },
      "datasource": { "type": "prometheus", "uid": "$datasource" },
      "targets": [
        {
          "expr": "sum(rate(app_${worker}_skipped{env=\"$env\", service_name=\"$service\"}[5m]))",
          "legendFormat": "skipped/s",
          "refId": "A"
        }
      ],
      "fieldConfig": {
        "defaults": {
          "unit": "ops",
          "custom": { "fillOpacity": 10, "lineWidth": 2 },
          "thresholds": {
            "steps": [
              { "color": "green", "value": null },
              { "color": "yellow", "value": 0.08 },
              { "color": "red", "value": 0.33 }
            ]
          }
        }
      }
    },
    {
      "title": "Retry Rate",
      "type": "timeseries",
      "gridPos": { "h": 8, "w": 9, "x": 15, "y": 8 },
      "datasource": { "type": "prometheus", "uid": "$datasource" },
      "targets": [
        {
          "expr": "sum(rate(app_${worker}_retries{env=\"$env\", service_name=\"$service\"}[5m]))",
          "legendFormat": "retries/s",
          "refId": "A"
        }
      ],
      "fieldConfig": {
        "defaults": {
          "unit": "ops",
          "custom": { "fillOpacity": 10, "lineWidth": 2 },
          "thresholds": {
            "steps": [
              { "color": "green", "value": null },
              { "color": "yellow", "value": 0.17 },
              { "color": "red", "value": 0.83 }
            ]
          }
        }
      }
    },
    {
      "title": "Execution Duration",
      "type": "timeseries",
      "gridPos": { "h": 8, "w": 24, "x": 0, "y": 16 },
      "datasource": { "type": "prometheus", "uid": "$datasource" },
      "targets": [
        {
          "expr": "histogram_quantile(0.50, sum by (le) (rate(app_${worker}_duration_seconds_bucket{env=\"$env\", service_name=\"$service\"}[5m])))",
          "legendFormat": "p50",
          "refId": "A"
        },
        {
          "expr": "histogram_quantile(0.95, sum by (le) (rate(app_${worker}_duration_seconds_bucket{env=\"$env\", service_name=\"$service\"}[5m])))",
          "legendFormat": "p95",
          "refId": "B"
        },
        {
          "expr": "histogram_quantile(0.99, sum by (le) (rate(app_${worker}_duration_seconds_bucket{env=\"$env\", service_name=\"$service\"}[5m])))",
          "legendFormat": "p99",
          "refId": "C"
        }
      ],
      "fieldConfig": {
        "defaults": {
          "unit": "s",
          "custom": { "fillOpacity": 10, "lineWidth": 2 }
        }
      }
    }
  ],
  "time": { "from": "now-1h", "to": "now" }
}
```

---

## Generation Rules

1. **Output location**: Always generate under `tools/grafana/`
2. **Environment variable**: Every dashboard must include the `env` template variable with values matching `ASPNETCORE_ENVIRONMENT`: `Integration`, `Testing`, `Staging`, `Production`
3. **Datasource variable**: Every dashboard must include the `$datasource` variable
4. **Query filtering**: Every PromQL query must include `env="$env"` and `service_name="$service"`
5. **Placeholder**: Use `$(SERVICE_NAME)` for dashboard uid and title - replaced during deployment
6. **Tags**: Include `generated` tag on all dashboards
7. **Naming**: Dashboard files use kebab-case: `{dashboard-type}-dashboard.json`
