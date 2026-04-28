---
name: infrastructure
type: guidance
applies_to:
  - Developer
  - Reviewer
mandatory: conditional
triggers:
  - dockerfile
  - kubernetes
  - container
  - deployment
  - health probe
references:
  - templates/dockerfile.md
  - templates/kubernetes.md
summary: Docker and Kubernetes patterns for .NET 10 services including health probes, resource limits, and graceful shutdown.
---

# Infrastructure Skill

Defines containerization and orchestration standards for .NET services.

## Roles

- **Developer**: Creates and maintains Dockerfile and Kubernetes manifests
- **Reviewer**: Verifies infrastructure configuration meets standards

---

## Dockerfile Standards

See [templates/dockerfile.md](templates/dockerfile.md) for complete template.

### Required Structure

1. **Multi-stage build**: base → build → publish → final
2. **.NET 10 base images**: `mcr.microsoft.com/dotnet/aspnet:10.0` and `sdk:10.0`
3. **Non-root user**: `USER app`
4. **Standard ports**: 8080 (HTTP), 8081 (HTTPS)
5. **Build files**: Copy `Directory.*.props`, `global.json` for proper restore

### Build Arguments

| Argument | Purpose | Required |
|----------|---------|----------|
| `BUILD_CONFIGURATION` | Release/Debug | No (default: Release) |
| `GITHUB_PAT` | NuGet package authentication | Yes |
| `VERSION` | Assembly version | No (default: timestamp) |

### Security

- Never embed secrets in image layers
- Use non-root user
- Minimize image layers
- Use specific image tags, not `latest`

---

## Kubernetes Standards

See [templates/kubernetes.md](templates/kubernetes.md) for complete templates.

### Required Manifests

| File | Purpose |
|------|---------|
| `base/deployment.yaml` | Pod specification |
| `base/service.yaml` | Service exposure |
| `base/kustomization.yaml` | Kustomize configuration |
| `overlays/{env}/` | Environment-specific patches |

### Kustomize Structure

Source of truth: [`solution-structure`](../solution-structure/SKILL.md) § *.NET Solution* — `/tools/Kubernetes/` subtree (full `base/` + `overlays/{integration,testing,staging,production}/{base,default,alternative}/` shape).

Quick reference:
```
tools/kubernetes/
├── base/
│   ├── kustomization.yaml
│   ├── deployment.yaml
│   └── service.yaml
└── overlays/
    ├── integration/
    ├── testing/
    ├── staging/
    └── production/
```

### Variable Substitution

Use `$(VARIABLE_NAME)` syntax for Kustomize substitution:
- `$(APPLICATION_NAME)` - Service name
- `$(IMAGE)` - Container image with tag

---

## Health Probes

### Endpoints

| Probe | Path | Purpose | Tags |
|-------|------|---------|------|
| Liveness | `/healthz/live` | Process is alive | `live` |
| Readiness | `/healthz/ready` | Can accept traffic | `ready` |
| Startup | `/healthz/startup` | Initialization complete | `startup` |

### Probe Configuration

| Probe | initialDelay | period | timeout | failureThreshold |
|-------|--------------|--------|---------|------------------|
| Liveness | 0s | 60s | 1s | 3 |
| Readiness | 5s | 180s | 1s | 3 |
| Startup | 0s | 10s | 1s | 30 |

### Implementation

See `.github/skills/dotnet-service-generator/references/health-check.md` for health check patterns.

```csharp
// Registration
services.AddHealthChecks()
    .AddCheck<MyServiceHealthCheck>("MyService", tags: ["ready"]);

// Endpoints
app.MapHealthChecks("/healthz/live", new HealthCheckOptions
{
    Predicate = _ => false // Always healthy if process is running
});

app.MapHealthChecks("/healthz/ready", new HealthCheckOptions
{
    Predicate = check => check.Tags.Contains("ready")
});
```

---

## Resource Limits

### Default Values

| Environment | CPU Request | CPU Limit | Memory Request | Memory Limit |
|-------------|-------------|-----------|----------------|--------------|
| Integration | 250m | 500m | 256Mi | 512Mi |
| Testing | 500m | 1000m | 512Mi | 1024Mi |
| Staging | 500m | 1000m | 512Mi | 1024Mi |
| Production | 500m | 2000m | 512Mi | 2048Mi |

### Ephemeral Storage

All environments:
- Request: 1Gi
- Limit: 2Gi

### Adjustment Guidelines

- Profile actual usage before adjusting
- CPU limit should be 2x request for burst capacity
- Memory limit should be 2x request for safety margin
- Monitor OOMKilled events to detect memory pressure

---

## Graceful Shutdown

### Configuration

```yaml
terminationGracePeriodSeconds: 60
```

### Application Requirements

1. Handle SIGTERM signal
2. Stop accepting new requests
3. Complete in-flight requests
4. Close database connections
5. Flush telemetry buffers
6. Release distributed locks

### .NET Implementation

```csharp
// Program.cs
var builder = WebApplication.CreateBuilder(args);

// Configure graceful shutdown
builder.Host.ConfigureHostOptions(options =>
{
    options.ShutdownTimeout = TimeSpan.FromSeconds(30);
});

var app = builder.Build();

app.Lifetime.ApplicationStopping.Register(() =>
{
    // Cleanup logic here
});
```

---

## Volumes and Secrets

### Standard Mounts

| Path | Source | Purpose |
|------|--------|---------|
| `/app/configuration/secret` | Kubernetes Secret | Sensitive configuration |
| `/app/configuration/configmap` | ConfigMap | Non-sensitive configuration |

### Configuration Loading

```csharp
builder.Configuration
    .AddJsonFile("appsettings.json", optional: false)
    .AddJsonFile($"appsettings.{env}.json", optional: true)
    .AddJsonFile("/app/configuration/configmap/appsettings.json", optional: true)
    .AddJsonFile("/app/configuration/secret/appsettings.json", optional: true)
    .AddEnvironmentVariables();
```

---

## Deployment Strategy

### Default: Rolling Update

```yaml
strategy:
  type: RollingUpdate
  rollingUpdate:
    maxSurge: 0%
    maxUnavailable: 100%
```

This configuration:
- Terminates all old pods before creating new ones
- Minimizes resource usage during deployment
- Suitable for stateless services

### Alternative: Zero-Downtime

```yaml
strategy:
  type: RollingUpdate
  rollingUpdate:
    maxSurge: 25%
    maxUnavailable: 0%
```

Use when:
- Service must maintain availability during deployment
- Sufficient cluster resources for extra pods

---

## Reviewer Checklist

When reviewing infrastructure changes:

- [ ] Multi-stage Dockerfile with proper layer ordering
- [ ] Non-root user in container
- [ ] Health probes configured with appropriate timing
- [ ] Resource requests and limits defined
- [ ] Graceful shutdown period set
- [ ] Secrets mounted from Kubernetes Secrets (not ConfigMaps)
- [ ] Image pull secrets configured
- [ ] Environment-specific overlays for all environments
- [ ] No hardcoded values (use Kustomize substitution)
