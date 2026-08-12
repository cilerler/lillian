---
name: infrastructure
description: Docker and Kubernetes patterns for .NET 10 services including health probes, resource limits, and graceful shutdown. Use when writing or reviewing Dockerfiles, Kubernetes manifests, container deployments, or health probes.
type: guidance
applies_to:
  - Developer
  - Reviewer
mandatory: conditional
mandatory_when:
  - Creating or updating Dockerfiles
  - Creating or updating Kubernetes manifests
  - Configuring health probes
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

Dockerfile and deployable-project placement comes from
[`Canonical deployable-runner identities`](../solution-structure/SKILL.md#canonical-deployable-runner-identities),
and Kubernetes placement comes from
[`Canonical Kubernetes directory structure`](../solution-structure/SKILL.md#canonical-kubernetes-directory-structure).
This skill owns the contents of Dockerfiles and Kubernetes manifests, not a second repository layout.

## Roles

- **Developer**: Creates and maintains Dockerfile and Kubernetes manifests
- **Reviewer**: Verifies infrastructure configuration meets standards

---

## Dockerfile Standards

See [templates/dockerfile.md](templates/dockerfile.md) for complete template.

The Dockerfile's `{DeployableProcessName}` is the full canonical deployable runner project name resolved from
`solution-structure` (for example, the value matching its `{Organization}.{Product}.Host` form). Do not shorten
it to a service name or invent app/core/infrastructure project identities.

### Required Structure

1. **Multi-stage build**: base → build → publish → final
2. **.NET 10 base images**: `mcr.microsoft.com/dotnet/aspnet:10.0` and `sdk:10.0`
3. **Non-root user**: `USER app`
4. **Standard ports**: 8080 (HTTP), 8081 (HTTPS)
5. **Build files**: Copy the four root build files required by `solution-structure`: `Directory.Packages.props`, `Directory.Build.props`, `Directory.Build.targets`, and `global.json`

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

### Placement contract

Use the [canonical Kubernetes directory structure](../solution-structure/SKILL.md#canonical-kubernetes-directory-structure)
before creating or moving a manifest. It alone owns the complete `/tools/Kubernetes/` tree. This skill supplies
content for its shared `base` and for its literal
`overlays/{integration,testing,staging,production}/{base,default,alternative}` directories; it does not add an
environment-level or image-transform layer. `default` and `alternative` are selectable components layered
over the environment's `base`, not shorter forms of the deployable process.

### Deployable identity and image tokens

- `{DeployableProcessName}` is the full canonical deployable runner/project identity resolved from
  `solution-structure`. It is a scaffold-time input, not a shortened service or application name.
- `{DeployableProcessKebabName}` is the only derived identity token. Derive it once from
  `{DeployableProcessName}` for Kubernetes DNS-label fields: lowercase the full identity, replace dots and
  other non-alphanumeric runs with one hyphen, and trim leading/trailing hyphens. If that result exceeds
  Kubernetes' 63-character label limit, take its first 54 characters, trim any trailing hyphen, then append a
  hyphen and the first eight lowercase hexadecimal characters of the SHA-256 of the unshortened kebab value.
  Committed manifests contain the resulting literal value.
- `app-image:latest` is the deploy-time image placeholder. CI rewrites it with
  `kustomize edit set image "app-image:latest=<image>:<tag>"` in the selected
  `/tools/Kubernetes/overlays/<selected-environment>/<selected-component>/kustomization.yaml`; there is no
  separate image-transform layer. CI may set the namespace in that same selected component.

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

For health check implementation and registration patterns, see the dotnet-service-generator skill's `references/health-check.md`.

```csharp
// Endpoints
app.MapHealthChecks("/healthz/live", new HealthCheckOptions
{
    Predicate = _ => false // Always healthy if process is running
});

app.MapHealthChecks("/healthz/ready", new HealthCheckOptions
{
    Predicate = check => check.Tags.Contains("ready")
});

app.MapHealthChecks("/healthz/startup", new HealthCheckOptions
{
    Predicate = check => check.Tags.Contains("startup")
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
var environmentName = builder.Environment.EnvironmentName;

builder.Configuration
    .AddJsonFile("appsettings.json", optional: false)
    .AddJsonFile($"appsettings.{environmentName}.json", optional: true)
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
- [ ] The canonical integration, testing, staging, and production overlay components are present as required by `solution-structure`
- [ ] The full deployable identity was resolved once and only DNS-label fields use its canonical kebab derivation
- [ ] CI pins the image and namespace in the actual selected `default` or `alternative` component kustomization
- [ ] The change was exercised locally with the repository's applicable container/orchestration harness; use
      Docker Compose or Minikube when that is the repository's established local runtime
