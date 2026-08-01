---
description: Restructure an existing .NET service to match current folder structure and naming conventions
---

# Service Restructurer

## Variables
If any of these values were not provided in the invocation, ask the user for them before starting:

- **Service path:** [replace with path relative to repo root, e.g., src/Services/PaymentProcessor]
- **Module name:** [replace with target module name, or "none" if standalone]
- **Component name:** [replace with target component name, or "none" if standalone]

---

You are restructuring an existing service to match the folder structure and naming conventions defined in the dotnet-service-generator skill.

## Skills to Apply
Before starting, load and follow:
- `.github/skills/dotnet-service-generator/SKILL.md`
- `.github/skills/dotnet-service-generator/references/standard-service.md` — canonical folder structure
- `.github/skills/dotnet-service-generator/references/modular-polylith.md` — module/component hierarchy (if module name provided)

## Phase 1: Analyze Current Structure

Scan `{{Service path}}` and produce a report:

1. **Inventory** — list every file and folder, noting what each one is (interface, settings, model, exception, etc.)
2. **Identify the service name** — infer from the primary interface or class name
3. **Classify each file** by where it belongs in the new structure:

| Current location | Target folder | Reason |
|---|---|---|
| `I{ServiceName}.cs` at root | `Contracts/I{ServiceName}.cs` | Internal interface (default) |
| `{ServiceName}Settings.cs` | `Configuration/{ServiceName}Settings.cs` | Move to Configuration folder, update namespace |
| `StartupExtensions.cs` | `Extensions/StartupExtensions.cs` | Update namespace |
| Request/Response DTOs | `Abstractions/Requests/` or `Abstractions/Responses/` | Public contract types |
| Domain events | `Abstractions/Events/` | Public contract types |
| Enums shared externally | `Abstractions/Models/` | Shared types |
| Internal entities | `Models/` | Stay internal |
| Mapper classes | `Mappers/` | Keep existing |
| Exception classes | `Exceptions/` | Keep existing |
| Validator attributes | `Validators/` | Keep existing |
| `Api.cs` (single file) | `Api/{ServiceName}Api.cs` + split endpoints | One file per endpoint |
| Background service extending `WorkerBackgroundService` | `{ServiceName}Worker.cs` | Business logic stays in `{ServiceName}Service.cs` |
| Health check | `{ServiceName}HealthCheck.cs` | File and class name match |
| HTTP client wrappers | `Clients/` | Interface + implementation |
| Internal helpers | `Internals/` | Interfaces go to `Contracts/` |

4. **Missing folders** — based on the classified files, list which folders need to be created. Only create folders that will have content — do not create empty folders.

5. **Module/Component assessment** — if `{{Module name}}` is not "none":
   - Check if `Modules/{{Module name}}/` exists. If not, flag it needs creation with: `Abstractions/`, `Exceptions/`, `Extensions/StartupExtensions.cs`, `Observability/Grafana/`, `Constants.cs`
   - Check if `Modules/{{Module name}}/{{Component name}}/` exists. If not, flag it needs creation with same structure
   - Determine the target path: `Modules/{{Module name}}/{{Component name}}/{ServiceName}/`

## Phase 2: Present Migration Plan

Present the plan as a table showing every file move, rename, and namespace change. Include:

1. **File moves** — source → destination path
2. **Class renames** — align to the `{ServiceName}` prefix convention from solution-structure (`{ServiceName}Service`, `{ServiceName}Worker`, `{ServiceName}Settings`, `{ServiceName}HealthCheck`); file name must match class name
3. **Namespace changes** — old → new for each file
4. **New folders** — empty folders to create
5. **Module/Component scaffolding** — if creating module/component levels, list what gets created
6. **Worker/Service split** — if the current service extends `WorkerBackgroundService`, explain the split: business logic moves to `Service.cs`, lifecycle stays in `Worker.cs`
7. **API split** — if a single `Api.cs` has multiple endpoints, list the new endpoint files

**Wait for user approval before proceeding.**

## Phase 3: Execute Migration

After approval, execute the restructuring:

1. Create folders needed for the classified files — do not create empty folders
2. Create module/component scaffolding if needed (only the folders that will have content at each level)
3. Move files to their new locations
4. Update namespaces in all moved files
5. Update `using` statements across all files to reflect new namespaces
6. Rename files and classes per convention: core service files use `{ServiceName}` prefix — `{ServiceName}Service.cs`, `{ServiceName}Worker.cs`, `{ServiceName}HealthCheck.cs`, `{ServiceName}Settings.cs`, `I{ServiceName}.cs`, and exception classes. File name must match class name.
7. **After each rename, grep for the old class name across the entire service folder** and update every reference — generic type parameters, field declarations, constructor parameters, DI registrations, logger types, static member access, `nameof()`, etc. Zero occurrences of the old name must remain.
8. Split `Api.cs` into `Api/Api.cs` + individual endpoint files if applicable
9. Split Worker/Service if the service extends `WorkerBackgroundService`:
   - Business logic (checking for data, processing) → `{ServiceName}Service.cs` implementing `I{ServiceName}`
   - Lifecycle/scheduling (DoWorkAsync override, IdleCycle) → `{ServiceName}Worker.cs` extending `WorkerBackgroundService<{ServiceName}Settings>`
   - Worker takes `I{ServiceName}` as constructor dependency and delegates to it
10. Update `StartupExtensions.cs` registrations to reference new class names and namespaces
11. If metric names are inline strings, extract to `Constants.Metrics` nested class
12. Update any `appsettings.json` references if configuration section names changed

## Phase 3b: Update Dependents

After restructuring the service itself:

1. **Test projects** — find test projects that reference this service (grep for old class names and namespaces across the `/tests` folder). Update `using` statements, type references, and any test setup that constructs or mocks renamed types.
2. **Other services** — grep for old class names and namespaces across the entire `src/` folder. If other services reference renamed types (e.g., they imported `{ServiceName}Settings`), list them and update. If unsure whether an external reference should be updated, flag it for user review.

## Phase 4: Verify

1. Confirm all files are in correct locations matching `standard-service.md` structure
2. Confirm core service files use the `{ServiceName}` prefix per solution-structure (`{ServiceName}Service.cs`, `{ServiceName}Worker.cs`, `{ServiceName}HealthCheck.cs`, `{ServiceName}Settings.cs`) and every file name matches its class name
3. **Grep for old class names** (`{ServiceName}Settings`, `{ServiceName}HealthCheck`, etc.) — zero matches must remain
4. Confirm namespaces match folder paths
5. Confirm no empty folders exist
6. Confirm no orphaned `using` statements pointing to old namespaces
7. If module/component created, confirm registration chain: Module StartupExtensions → Component StartupExtensions → Service StartupExtensions
8. Build the project to verify compilation

## Constraints
- **Preserve all business logic** — only restructure, never change behavior
- **Do not touch other services** — only modify the target service and its parent module/component scaffolding
- **Ask before splitting** — if a Worker/Service split or API split is needed, confirm the approach before executing
