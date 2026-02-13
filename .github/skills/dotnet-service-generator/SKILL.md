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
summary: Interactive scaffolder for .NET service modules with observability and DI conventions.
---

# .NET Service Generator

Interactive scaffolder for .NET services with full observability support.

## Workflow

1. Gather information interactively
2. Identify dependencies from service purpose
3. Present dependency checklist for confirmation
4. Generate files to specified location

## Step 1: Gather Basic Info

Ask these questions (one or two at a time):

1. **Service name** - PascalCase (e.g., `PaymentProcessor`, `UserNotification`)
2. **Namespace** - `{Company}.{Product}` (e.g., `Microsoft.Windows`)
3. **Purpose** - Brief description (used to identify dependencies)
4. **Output location** - Where to generate files

## Step 2: Identify Dependencies

Based on service purpose:

| If the service... | Likely needs |
|-------------------|--------------|
| Calls external APIs | IHttpClientFactory |
| Caches data | HybridCache or IDistributedCache |
| Reads/writes database | DbContext |
| Uploads/downloads files | ICloudStorageFactory |
| Sends/receives messages | IMessageQueueFactory |
| Needs coordination/locking | IDistributedLock |
| Runs on schedule/background | WorkerBackgroundService |
| Exposes HTTP endpoints | Api.cs |

## Step 3: Confirm Dependencies

Present numbered checklist:

```
Based on your description, I identified:
[x] 1. IHttpClientFactory (for external API calls)
[x] 2. HybridCache (for caching responses)

Additional options:
[ ] 3. IDistributedCache
[ ] 4. IDistributedLock
[ ] 5. DbContext (direct)
[ ] 6. Repository/UoW pattern
[ ] 7. ICloudStorageFactory
[ ] 8. IMessageQueueFactory
[ ] 9. Background service
[ ] 10. API endpoints

Confirm or adjust (e.g., "add 4, remove 2"):
```

## Step 4: Determine Service Lifetime

Suggest based on dependencies:

- **Singleton**: Stateless, HttpClient wrappers, background services
- **Scoped**: Database access, request-specific state
- **Transient**: Lightweight, stateless, no shared resources

## Step 5: Generate Files

Output to `{OutputLocation}/Services/{ServiceName}/`:

### Always Generate

| File | Purpose |
|------|---------|
| `Contracts/I{ServiceName}.cs` | Service interface |
| `Constants.cs` | Domain constants |
| `Settings.cs` | Configuration with validation |
| `Service.cs` | Implementation |
| `StartupExtensions.cs` | DI registration |

### Conditionally Generate

| Condition | File |
|-----------|------|
| API exposure | `Api.cs` |
| Settings validation | `Validators/{Name}Attribute.cs` |
| Health monitoring | `HealthCheck.cs` |
| DTOs/records needed | `Models/{Name}.cs` |
| Custom exceptions | `Exceptions/{Name}Exception.cs` |
| Object mapping | `Mappers/{Name}Mapper.cs` |

## Code Patterns

See reference files:

- **Standard service**: [references/standard-service.md](references/standard-service.md)
- **Background service**: [references/background-service.md](references/background-service.md)
- **API patterns**: [references/api-patterns.md](references/api-patterns.md)
- **Optional dependencies**: [references/dependencies.md](references/dependencies.md)
- **Health checks**: [references/health-check.md](references/health-check.md)

## Key Conventions

### Naming
- Variables match interface: `IDistributedCache` → `_distributedCache`
- Settings: `{ServiceName}Settings`
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

## Output Format

After generation, provide:
1. List of generated files
2. Sample `appsettings.json` section
3. Sample `Program.cs` registration
