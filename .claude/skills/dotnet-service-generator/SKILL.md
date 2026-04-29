---
name: dotnet-service-generator
type: guidance
applies_to:
  - Developer
mandatory: conditional
triggers:
  - create a service
  - scaffold service
  - add a new service
  - generate service boilerplate
references:
  - references/standard-service.md
  - references/background-service.md
  - references/api-patterns.md
  - references/dependencies.md
  - references/health-check.md
  - references/modular-polylith.md
summary: Interactive scaffolder for .NET service modules with observability and DI conventions.
---

# .NET Service Generator

Interactive scaffolder for .NET services with full observability support.

> **Folder layout source of truth:** [`solution-structure`](../solution-structure/SKILL.md) defines the modular-polylith service path (`/src/{Namespace}.Modules.{Module}/{Component}/{Service}/`) and the per-service folder shape. The patterns below mirror that skill — when they diverge, `solution-structure` wins.

## Workflow

1. Gather information interactively
2. Identify dependencies from service purpose
3. Present dependency checklist for confirmation
4. Determine service lifetime
5. Generate files to specified location

## Step 1: Gather Basic Info

Ask these questions (one or two at a time):

1. **Service name** - PascalCase (e.g., `PaymentProcessor`, `UserNotification`)
2. **Namespace** - `{Organization}.{Product}` (e.g., `Microsoft.Windows`)
3. **Purpose** - Brief description (used to identify dependencies)
4. **Output location** - Where to generate files (standalone: `Services/{ServiceName}/`, modular polylith: `Company.Project.Modules.{ModuleName}/{ComponentName}/{ServiceName}/`)
5. **Interface visibility** - Is `I{ServiceName}` consumed by other modules? (default: **no** → placed in `Contracts/`)

## Step 2: Identify Dependencies

Based on service purpose:

| If the service... | Likely needs |
|-------------------|--------------|
| Calls external APIs | `Clients/` with typed HTTP client |
| Makes simple HTTP calls | IHttpClientFactory |
| Caches data | HybridCache or IDistributedCache |
| Reads/writes database | DbContext |
| Uploads/downloads files | ICloudStorageFactory |
| Sends/receives messages | IMessageQueueFactory |
| Needs coordination/locking | IDistributedLock |
| Runs on schedule/background | Worker.cs (extends WorkerBackgroundService) |
| Exposes HTTP endpoints | `Api/` folder |

## Step 3: Confirm Dependencies

Present numbered checklist:

```
Based on your description, I identified:
[x] 1. Clients/ with typed HTTP client (for external API calls)
[x] 2. HybridCache (for caching responses)

Additional options:
[ ] 3. IDistributedCache
[ ] 4. IDistributedLock
[ ] 5. DbContext (direct)
[ ] 6. Repository/UoW pattern (in Internals/)
[ ] 7. ICloudStorageFactory
[ ] 8. IMessageQueueFactory
[ ] 9. Worker.cs (background service)
[ ] 10. Api/ folder (HTTP endpoints)

Confirm or adjust (e.g., "add 4, remove 2"):
```

## Step 4: Determine Service Lifetime

Suggest based on dependencies:

- **Singleton**: Stateless, HttpClient wrappers, background services
- **Scoped**: Database access, request-specific state
- **Transient**: Lightweight, stateless, no shared resources

## Step 5: Generate Files

Output to `{OutputLocation}/{ServiceName}/`:

### Always Generate

| Path | Purpose |
|------|---------|
| `Configuration/{ServiceName}Settings.cs` | Configuration with validation |
| `Contracts/I{ServiceName}.cs` | Service interface (internal by default) |
| `Extensions/StartupExtensions.cs` | DI registration |
| `Constants.cs` | Domain constants + Metrics nested class |
| `{ServiceName}Service.cs` | Core business logic implementation |

### Create When Needed

Folders are created only when they have content. Do not create empty folders.

| Condition | Path |
|-----------|------|
| Public request DTOs | `Abstractions/Requests/` |
| Public response DTOs | `Abstractions/Responses/` |
| Public domain events | `Abstractions/Events/` |
| Interface externally consumed | `Abstractions/Interfaces/` (move `I{ServiceName}.cs` from `Contracts/`) |
| Shared enums, value objects | `Abstractions/Models/` |
| API exposure | `Api/{ServiceName}Api.cs` + `Api/{Verb}Endpoint.cs` per endpoint |
| External HTTP API wrappers | `Clients/` |
| Custom exceptions | `Exceptions/` |
| Internal helper implementations | `Internals/` (interfaces go to `Contracts/`) |
| Object mapping needed | `Mappers/` |
| Internal entities/domain objects | `Models/` |
| Grafana dashboard | `Observability/Grafana/` |
| Embedded resources (SQL, templates, etc.) | `Resources/` with subfolders by type |
| Custom validation attributes | `Validators/` |
| Background/cron service | `{ServiceName}Worker.cs` |
| Health monitoring | `{ServiceName}HealthCheck.cs` |
| API exposure | `tests/{ServiceName}.http` — HTTP test file for the service's endpoints |

## Code Patterns

See reference files:

- **Standard service**: [references/standard-service.md](references/standard-service.md)
- **Background service**: [references/background-service.md](references/background-service.md)
- **API patterns**: [references/api-patterns.md](references/api-patterns.md)
- **Optional dependencies**: [references/dependencies.md](references/dependencies.md)
- **Health checks**: [references/health-check.md](references/health-check.md)
- **Modular polylith**: [references/modular-polylith.md](references/modular-polylith.md)

## Observability Guidance

For log level selection and `ActivityKind` usage in generated code, see the [Observability Skill](../observability/SKILL.md#log-levels) — specifically the **Log Levels** and **Activity Kinds** sections.

## Key Conventions

### Architecture Rule: Service.cs Owns All Business Logic
- `{ServiceName}Service.cs` is the single home for business logic, accessed through `I{ServiceName}`
- `{ServiceName}Worker.cs` and `Api/` endpoints are **thin adapters** — they translate between their protocol (HTTP, cron) and `I{ServiceName}`, never containing business logic themselves
- API endpoints call `I{ServiceName}` methods and map results to HTTP responses — nothing more
- Worker calls `I{ServiceName}` methods and manages scheduling/lifecycle — nothing more

### Folder Organization
- Folders are created only when they have content — do not create empty folders
- `Abstractions/` = public contract (what other modules/consumers reference)
- `Contracts/` = internal interfaces (what stays within this service module)
- `Models/` = internal entities only (public DTOs go in `Abstractions/`)
- `Internals/` = internal helper implementations (their interfaces go in `Contracts/`)
- Core service files use `{ServiceName}` prefix: `{ServiceName}Service.cs`, `{ServiceName}Settings.cs`, `{ServiceName}Worker.cs`, `{ServiceName}HealthCheck.cs`, `I{ServiceName}.cs`, exception classes. Other files (endpoints, mappers, validators, helpers) use descriptive names without the prefix.

### Naming
- Variables match interface: `IDistributedCache` → `_distributedCache`
- Settings class: `{ServiceName}Settings` (in `Configuration/` folder — keeps the prefix for cross-service disambiguation)
- ConfigurationSectionName: `nameof({ServiceName})`

### Constructor Order
1. `ILogger<T>`
2. `IDistributedTracing`
3. `IMeterFactory`
4. `IOptions<TSettings>`
5. Optional dependencies (alphabetical)

### Meter Creation
```csharp
_meter = meterFactory.Create(new MeterOptions(Startup.AssemblyName)
{
    Version = Startup.AssemblyVersion,
    Tags = new TagList
    {
        { "code.namespace", GetType().Namespace },
        { "code.class", GetType().Name }
    }
});
```

### Metric Constants
Define metric names in `Constants.Metrics` nested class to ensure consistency between code and Grafana dashboards:
```csharp
public static class Constants
{
    public static class Metrics
    {
        public const string ActiveRequests = "active_requests";
        public const string OperationTotal = "operation_total";
        public const string OperationDuration = "operation_duration_seconds";
    }
}
```

## Output Format

After generation, provide:
1. List of generated files
2. Sample `appsettings.json` section
3. Sample `Program.cs` registration
