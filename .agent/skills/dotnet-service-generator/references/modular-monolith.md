# Modular Monolith Structure

Organization hierarchy for modular monolith architectures. Each service follows the standard service pattern documented in [standard-service.md](standard-service.md).

## Hierarchy

```
src/
├── Common/                                    # Shared libraries (NOT a module)
│   ├── {Organization}.Extensions.Hosting/
│   └── {Organization}.OpenTelemetry/
│
├── Abstractions/                              # Cross-module contracts (app-specific)
│   ├── Events/
│   ├── Interfaces/
│   ├── Models/
│   ├── Requests/
│   └── Responses/
├── Exceptions/                                # App-wide base exceptions
├── Extensions/
│   └── StartupExtensions.cs                   # Registers all modules
├── Observability/                             # Cross-module dashboards
│   └── Grafana/
├── Constants.cs                               # App-wide constants
│
├── Modules/
│   ├── {ModuleName}/
│   │   ├── Abstractions/                      # Module's public contract (cross-module)
│   │   │   ├── Events/
│   │   │   ├── Interfaces/
│   │   │   ├── Models/
│   │   │   ├── Requests/
│   │   │   └── Responses/
│   │   ├── Exceptions/                        # Module-level base exceptions
│   │   ├── Extensions/
│   │   │   └── StartupExtensions.cs           # Registers all components
│   │   ├── Observability/                     # Module-level dashboards
│   │   │   └── Grafana/
│   │   ├── Constants.cs                       # Module-wide constants
│   │   │
│   │   ├── {ComponentName}/                   # Always required (even single-component modules)
│   │   │   ├── Abstractions/                  # Component's public contract (cross-component)
│   │   │   │   ├── Events/
│   │   │   │   ├── Interfaces/
│   │   │   │   ├── Models/
│   │   │   │   ├── Requests/
│   │   │   │   └── Responses/
│   │   │   ├── Exceptions/                    # Component-level base exceptions
│   │   │   ├── Extensions/
│   │   │   │   └── StartupExtensions.cs       # Registers all services in component
│   │   │   ├── Observability/                 # Component-level dashboards
│   │   │   │   └── Grafana/
│   │   │   ├── Constants.cs                   # Component-wide constants
│   │   │   │
│   │   │   ├── {ServiceName}/                 # Full service structure
│   │   │   │   ├── Abstractions/              # Public contract (cross-service)
│   │   │   │   │   ├── Events/                # Domain events
│   │   │   │   │   ├── Interfaces/            # Public interfaces (when externally consumed)
│   │   │   │   │   ├── Models/                # Enums, value objects, shared DTOs
│   │   │   │   │   ├── Requests/              # Request DTOs
│   │   │   │   │   └── Responses/             # Response DTOs
│   │   │   │   ├── Api/                       # HTTP endpoints (optional)
│   │   │   │   ├── Clients/                   # External HTTP API wrappers
│   │   │   │   ├── Configuration/             # Settings and config binding
│   │   │   │   ├── Contracts/                 # Internal interfaces (DI/testing)
│   │   │   │   ├── Exceptions/                # Service-specific exceptions
│   │   │   │   ├── Extensions/                # DI registration, model extensions
│   │   │   │   ├── Internals/                 # Internal helper implementations
│   │   │   │   ├── Mappers/                   # Object mapping between types
│   │   │   │   ├── Models/                    # Internal entities/domain objects
│   │   │   │   ├── Observability/             # Dashboards and diagnostics
│   │   │   │   │   └── Grafana/               # Per-service Grafana dashboard JSON
│   │   │   │   ├── Resources/                 # optional — embedded resource files (SQL, templates, etc.)
│   │   │   │   │   └── SQL/
│   │   │   │   ├── Validators/                # Custom validation attributes
│   │   │   │   ├── Constants.cs               # Service constants + Metrics nested class
│   │   │   │   ├── {ServiceName}Service.cs    # Core business logic
│   │   │   │   ├── {ServiceName}Worker.cs     # Background service lifecycle (optional)
│   │   │   │   └── {ServiceName}HealthCheck.cs # Health monitoring (optional)
│   │   │   │
│   │   │   └── {ServiceName2}/
│   │   │
│   │   └── {ComponentName2}/
│   │
│   └── {ModuleName2}/
```

## Concepts

| Level | Purpose | Contains | Example |
|-------|---------|----------|---------|
| Root | Application-wide shared concerns | Abstractions/, Exceptions/, Extensions/, Observability/, Constants.cs | src/ |
| Module | Business domain boundary | Abstractions/, Exceptions/, Extensions/, Observability/, Constants.cs | RecipeManagement, MealPlanning |
| Component | Sub-domain within a module, always required | Abstractions/, Exceptions/, Extensions/, Observability/, Constants.cs | Authoring, Discovery |
| Service | Atomic implementation unit | All folders (see [standard-service.md](standard-service.md)) | RecipeEditor, RecipeSearch |

### Exception Hierarchy

Exceptions cascade through the hierarchy. Module-level base exceptions let you catch broadly at module boundaries:

```csharp
// Module level
namespace {Organization}.{Product}.Modules.RecipeManagement.Exceptions;
public class RecipeManagementException : Exception { ... }

// Component level — inherits from module
namespace {Organization}.{Product}.Modules.RecipeManagement.Authoring.Exceptions;
public class AuthoringException : RecipeManagementException { ... }

// Service level — inherits from component
namespace {Organization}.{Product}.Modules.RecipeManagement.Authoring.RecipeEditor.Exceptions;
public class RecipeEditorException : AuthoringException { ... }
```

### Components Are Always Required

Even single-component modules must have a named component. This avoids ambiguity about where to place services and prevents restructuring when a second component is added.

## Namespace Convention

Namespaces follow the full hierarchy:

```
{Organization}.{Product}.Modules.{ModuleName}.{ComponentName}.{ServiceName}
```

Sub-folders append to the service namespace:

```
{Organization}.{Product}.Modules.{ModuleName}.{ComponentName}.{ServiceName}.Contracts
{Organization}.{Product}.Modules.{ModuleName}.{ComponentName}.{ServiceName}.Abstractions.Requests
{Organization}.{Product}.Modules.{ModuleName}.{ComponentName}.{ServiceName}.Configuration
{Organization}.{Product}.Modules.{ModuleName}.{ComponentName}.{ServiceName}.Extensions
```

Component-level abstractions:

```
{Organization}.{Product}.Modules.{ModuleName}.{ComponentName}.Abstractions.Requests
{Organization}.{Product}.Modules.{ModuleName}.{ComponentName}.Abstractions.Events
{Organization}.{Product}.Modules.{ModuleName}.{ComponentName}.Extensions
```

Module-level abstractions:

```
{Organization}.{Product}.Modules.{ModuleName}.Abstractions.Requests
{Organization}.{Product}.Modules.{ModuleName}.Abstractions.Events
{Organization}.{Product}.Modules.{ModuleName}.Extensions
```

### Standalone Mode

In non-modular-monolith projects, the module and component levels are absent:

```
{Organization}.{Product}.Services.{ServiceName}
{Organization}.{Product}.Services.{ServiceName}.Contracts
```

### Example

Using the recipe platform:

```
MyOrganization.CookingPlatform.Modules.RecipeManagement.Authoring.RecipeEditor
MyOrganization.CookingPlatform.Modules.RecipeManagement.Authoring.RecipeEditor.Contracts
MyOrganization.CookingPlatform.Modules.RecipeManagement.Authoring.Abstractions.Events
MyOrganization.CookingPlatform.Modules.RecipeManagement.Abstractions.Events
```

## Abstractions at Four Levels

| Level | Visibility | Purpose |
|-------|-----------|---------|
| Root Abstractions | App-wide | What all modules share (cross-cutting contracts) |
| Module Abstractions | Cross-module | What other modules consume |
| Component Abstractions | Cross-component | What other components within the same module consume |
| Service Abstractions | Cross-service | What other services within the same component consume |

Each Abstractions/ folder contains: Events/, Interfaces/, Models/, Requests/, Responses/.

Communication flows through the appropriate level's Abstractions. Never reference a lower level's internal types from a higher scope.

```
Module A                          Module B
┌─────────────────┐              ┌─────────────────┐
│ Abstractions/ ◄─┼──────────────┤ Service.cs       │
│ (cross-module)  │  references  │ (consumes A's    │
│                 │              │  module abstractions)
├─────────────────┤              └─────────────────┘
│ Component X     │
│ ┌─────────────┐ │              Component Y (same module)
│ │Abstractions/│◄┼─────────────── Service.cs
│ │(cross-comp) │ │  references    (consumes X's
│ └─────────────┘ │                component abstractions)
│ ┌─────────────┐ │
│ │ Service A   │ │              Service B (same component)
│ │ Abstractions│◄┼─────────────── Service.cs
│ │(cross-svc)  │ │  references    (consumes A's
│ └─────────────┘ │                service abstractions)
└─────────────────┘
```

## Common/

Shared infrastructure libraries, **not** a module. Contains no domain logic.

| Belongs in Common/ | Does NOT belong in Common/ |
|---|---|
| Base classes (e.g., `WorkerBackgroundService`) | User authentication logic |
| OpenTelemetry setup | Tenant resolution rules |
| HTTP client utilities | Domain-specific validators |
| Shared middleware | Business event handlers |

If it has business rules, it's a module. If it's pure infrastructure, it's Common/.

## Registration Chain

Registration cascades through the hierarchy: Module → Component → Service.

### Module Extensions/StartupExtensions.cs

```csharp
namespace {Organization}.{Product}.Modules.{ModuleName}.Extensions;

public static class StartupExtensions
{
    public static IServiceCollection Add{ModuleName}Module(
        this IServiceCollection services)
    {
        // Register all components
        services.Add{ComponentName1}();
        services.Add{ComponentName2}();
        
        return services;
    }
}
```

### Component Extensions/StartupExtensions.cs

```csharp
namespace {Organization}.{Product}.Modules.{ModuleName}.{ComponentName}.Extensions;

public static class StartupExtensions
{
    public static IServiceCollection Add{ComponentName}(
        this IServiceCollection services)
    {
        // Register all services in this component
        services.Add{ServiceName1}();
        services.Add{ServiceName2}();
        
        return services;
    }
}
```

### Service Extensions/StartupExtensions.cs

See [standard-service.md](standard-service.md) for the service-level registration pattern.

### Program.cs

```csharp
builder.Services.AddRecipeManagementModule();
builder.Services.AddMealPlanningModule();
```

## Example

Recipe/cooking platform demonstrating multiple modules, components, and services:

```
src/
├── Common/
│   ├── MyOrganization.Extensions.Hosting/
│   └── MyOrganization.OpenTelemetry/
│
├── Abstractions/                              # App-wide shared contracts
├── Exceptions/
├── Extensions/
├── Observability/
│   └── Grafana/                               # Platform overview dashboard
├── Constants.cs
│
├── Modules/
│   ├── RecipeManagement/
│   │   ├── Abstractions/
│   │   ├── Exceptions/
│   │   ├── Extensions/
│   │   ├── Observability/
│   │   │   └── Grafana/                       # Recipe domain health dashboard
│   │   ├── Constants.cs
│   │   │
│   │   ├── Authoring/                         # Write path
│   │   │   ├── Abstractions/
│   │   │   ├── Exceptions/
│   │   │   ├── Extensions/
│   │   │   ├── Observability/
│   │   │   │   └── Grafana/                   # Authoring services aggregated dashboard
│   │   │   ├── Constants.cs
│   │   │   ├── RecipeEditor/                  # CRUD for recipes
│   │   │   ├── IngredientParser/              # "2 cups flour" → structured data
│   │   │   └── MediaUploader/                 # Photo/video handling
│   │   │
│   │   └── Discovery/                         # Read path
│   │       ├── Abstractions/
│   │       ├── Exceptions/
│   │       ├── Extensions/
│   │       ├── Observability/
│   │       │   └── Grafana/                   # Discovery services aggregated dashboard
│   │       ├── Constants.cs
│   │       ├── RecipeSearch/                  # Full-text + faceted search
│   │       ├── Recommender/                   # "You might like" suggestions
│   │       └── CollectionManager/             # User-curated collections
│   │
│   ├── MealPlanning/
│   │   ├── Abstractions/
│   │   ├── Exceptions/
│   │   ├── Extensions/
│   │   ├── Observability/
│   │   │   └── Grafana/
│   │   ├── Constants.cs
│   │   │
│   │   ├── Planning/                          # Weekly meal plans
│   │   │   ├── Abstractions/
│   │   │   ├── Exceptions/
│   │   │   ├── Extensions/
│   │   │   ├── Observability/
│   │   │   │   └── Grafana/
│   │   │   ├── Constants.cs
│   │   │   ├── PlanBuilder/                   # Drag-drop meal calendar
│   │   │   └── NutritionCalculator/           # Aggregate macros
│   │   │
│   │   └── Shopping/                          # Grocery lists
│   │       ├── Abstractions/
│   │       ├── Exceptions/
│   │       ├── Extensions/
│   │       ├── Observability/
│   │       │   └── Grafana/
│   │       ├── Constants.cs
│   │       ├── ListGenerator/                 # Meal plan → shopping list
│   │       ├── StoreLocator/                  # Find stores, aisle mapping
│   │       └── PriceTracker/                  # Compare prices
│   │
│   ├── CookingExperience/
│   │   ├── Abstractions/
│   │   ├── Exceptions/
│   │   ├── Extensions/
│   │   ├── Observability/
│   │   │   └── Grafana/
│   │   ├── Constants.cs
│   │   │
│   │   ├── StepByStep/                        # Guided cooking
│   │   │   ├── Abstractions/
│   │   │   ├── Exceptions/
│   │   │   ├── Extensions/
│   │   │   ├── Observability/
│   │   │   │   └── Grafana/
│   │   │   ├── Constants.cs
│   │   │   ├── CookingSession/                # Real-time step tracking
│   │   │   ├── Timer/                         # Multi-timer management
│   │   │   └── Substitution/                  # "Out of X? Use Y"
│   │   │
│   │   └── Social/                            # Community features
│   │       ├── Abstractions/
│   │       ├── Exceptions/
│   │       ├── Extensions/
│   │       ├── Observability/
│   │       │   └── Grafana/
│   │       ├── Constants.cs
│   │       ├── ReviewManager/                 # Ratings + reviews
│   │       ├── CookingLog/                    # "I made this" history
│   │       └── ShareManager/                  # Social media sharing
│   │
│   └── UserProfile/
│       ├── Abstractions/
│       ├── Exceptions/
│       ├── Extensions/
│       ├── Observability/
│       │   └── Grafana/
│       ├── Constants.cs
│       │
│       └── Identity/                          # Single component
│           ├── Abstractions/
│           ├── Exceptions/
│           ├── Extensions/
│           ├── Observability/
│           │   └── Grafana/
│           ├── Constants.cs
│           ├── ProfileManager/                # Preferences, dietary restrictions
│           ├── SkillTracker/                  # Beginner → expert progression
│           └── NotificationPreferences/       # Email/push settings
```

### Cross-Module Communication

| Producer | Event | Consumer |
|----------|-------|----------|
| CookingExperience.Social.ReviewManager | `ReviewCreatedEvent` | RecipeManagement.Discovery.Recommender |
| MealPlanning.Shopping.ListGenerator | `ListGeneratedEvent` | MealPlanning.Shopping.PriceTracker |

Consumers reference the producer's **module** Abstractions, never internal service types. For intra-module communication between components, reference the producing **component's** Abstractions.

### Observability Drill-Down

Dashboards cascade from broad to specific, enabling incident triage:

| Level | Dashboard scope | Example | Owned by |
|-------|----------------|---------|----------|
| App (root) | All modules side by side | "Platform Overview" — module health matrix, error budget | SRE / on-call |
| Module | All components in one domain | "RecipeManagement" — SLA status, cross-component event lag | Domain owner |
| Component | All services in one sub-domain | "Authoring" — request volume by service, error rate breakdown | Team lead |
| Service | One service's metrics | "RecipeEditor" — latency p50/p95/p99, active connections | Service developer |

The pattern is a drill-down: app dashboard shows a red module → module dashboard shows which component → component dashboard shows which service → service dashboard shows the details.

### Abstractions/ Content

Each Abstractions/ folder at every level contains the same subfolders, organized by communication role:

| Subfolder | Role | Example |
|-----------|------|---------|
| Events/ | What gets published when something happens | `RecipeCreatedEvent` |
| Interfaces/ | Behavioral contracts to implement/consume | `IRecipeEditor` |
| Models/ | Supporting shared types (enums, value objects) | `RecipeStatus`, `Ingredient` |
| Requests/ | What you send to invoke an operation | `CreateRecipeRequest` |
| Responses/ | What you get back | `RecipeResponse` |
