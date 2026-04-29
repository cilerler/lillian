# Modular Polylith Structure

Each module is a separate `.csproj` with a sibling `.Abstractions` project for cross-module contracts. A single `Host` project references the modules and decides at startup — via feature flags — which modules to register, so the same binary can be deployed as multiple roles. Each service inside a module follows the standard service pattern documented in [standard-service.md](standard-service.md).

## Hierarchy

```
src/
├── Company.Project.Abstractions/                   # App-wide cross-module contracts
│   ├── Events/
│   ├── Interfaces/
│   ├── Models/
│   ├── Requests/
│   └── Responses/
│
├── Company.Project.Host/                           # Single deployable composition root
│   ├── Program.cs                                  # Feature flags choose which modules to register
│   ├── Dockerfile
│   ├── appsettings.*.json
│   ├── Contracts/                                  # App-wide internal interfaces
│   ├── Exceptions/                                 # App-wide base exceptions
│   ├── Extensions/
│   │   └── StartupExtensions.cs                    # Registers modules — feature flags gate which activate per deployment
│   ├── Internals/                                  # App-wide shared helpers
│   ├── Observability/Grafana/                      # Platform overview dashboard
│   └── Constants.cs
│
├── Company.Project.Modules.{ModuleName}.Abstractions/   # Separate csproj — module's public contract
│   ├── Events/
│   ├── Interfaces/
│   ├── Models/
│   ├── Requests/
│   └── Responses/
│
├── Company.Project.Modules.{ModuleName}/                # Module project — components and services live here as folders
│   ├── Constants.cs                                # Module-wide constants
│   ├── Contracts/                                  # Module-wide internal interfaces
│   ├── Exceptions/                                 # Module-level base exceptions
│   ├── Extensions/
│   │   └── StartupExtensions.cs                    # Registers all components in module
│   ├── Internals/                                  # Module-wide shared helpers
│   ├── Observability/Grafana/                      # Module-level domain dashboard
│   │
│   ├── {ComponentName}/                            # Folder — always required (even single-component modules)
│   │   ├── Abstractions/                           # Cross-component within module — folder, NOT separate csproj
│   │   │   ├── Events/
│   │   │   ├── Interfaces/
│   │   │   ├── Models/
│   │   │   ├── Requests/
│   │   │   └── Responses/
│   │   ├── Contracts/                              # Component-wide internal interfaces
│   │   ├── Exceptions/                             # Component-level base exceptions
│   │   ├── Extensions/
│   │   │   └── StartupExtensions.cs                # Registers all services in component
│   │   ├── Internals/                              # Component-wide shared helpers
│   │   ├── Observability/Grafana/                  # Component-level dashboard
│   │   ├── Constants.cs                            # Component-wide constants
│   │   │
│   │   ├── {ServiceName}/                          # Folder — full service structure (see standard-service.md)
│   │   │   ├── Abstractions/                       # Cross-service within component — folder
│   │   │   ├── Api/                                # HTTP endpoints (optional)
│   │   │   ├── Clients/                            # External HTTP API wrappers
│   │   │   ├── Configuration/
│   │   │   ├── Contracts/
│   │   │   ├── Exceptions/
│   │   │   ├── Extensions/
│   │   │   ├── Internals/
│   │   │   ├── Mappers/
│   │   │   ├── Models/
│   │   │   ├── Observability/Grafana/
│   │   │   ├── Resources/
│   │   │   ├── Validators/
│   │   │   ├── Constants.cs
│   │   │   ├── {ServiceName}Service.cs
│   │   │   ├── {ServiceName}Worker.cs
│   │   │   └── {ServiceName}HealthCheck.cs
│   │   │
│   │   └── {ServiceName2}/
│   │
│   └── {ComponentName2}/
│
├── Company.Project.Modules.{ModuleName2}.Abstractions/
└── Company.Project.Modules.{ModuleName2}/
```

## Why Polylith, Not Monolith

The Host is **one binary**, but feature flags decide which modules register at startup. The same artifact can deploy in multiple roles:

| Deployment | Active modules | Role |
|---|---|---|
| Recipe service | `RecipeManagement` | API + workers for recipe CRUD/discovery |
| Planning service | `MealPlanning`, `Shopping` | Meal plan and shopping list workers |
| Dev/single-host | All modules | One process for local development |

You get the operational simplicity of a monolith (one Dockerfile, one CI pipeline, one observability stack) with the deployment flexibility of microservices (subset selection per environment).

## Project Boundaries

| Project | Scope | Why separate? |
|---|---|---|
| `Company.Project.Abstractions` | App-wide cross-module contracts | Types depended on by multiple modules without forcing a module-to-module dependency |
| `Company.Project.Host` | Composition root, configuration, hosting | One deployable per repo |
| `Company.Project.Modules.{Module}.Abstractions` | Module's public contract | Other modules reference contracts without pulling in implementation |
| `Company.Project.Modules.{Module}` | Module implementation (components, services) | One module = one project, one feature-flag toggle |

Components and services stay as **folders** inside the module project — they're internal implementation that ships and changes together. Only contracts that cross the **module** boundary get their own `.csproj`. Component-level and service-level `Abstractions/` are folders within the module project, not separate projects, since they only need to be visible inside the module.

## Concepts

| Level | Boundary | Visibility | Example |
|---|---|---|---|
| Host | Composition root (.csproj) | Picks modules at startup via feature flags | `Company.Project.Host` |
| Module | Separate project (.csproj) | Cross-module contracts in `.Abstractions` sibling project | `RecipeManagement`, `MealPlanning` |
| Component | Folder inside module | Cross-component within module via component `Abstractions/` folder | `Authoring`, `Discovery` |
| Service | Folder inside component | Cross-service within component via service `Abstractions/` folder | `RecipeEditor`, `RecipeSearch` |

### Components Are Always Required

Even single-component modules must have a named component. Avoids ambiguity about where to place services and prevents restructuring when a second component is added.

### Exception Hierarchy

Exceptions cascade through the hierarchy. Module-level base exceptions let you catch broadly at module boundaries:

```csharp
// Module level (in module project)
namespace Company.Project.Modules.RecipeManagement.Exceptions;
public class RecipeManagementException : Exception { ... }

// Component level — inherits from module
namespace Company.Project.Modules.RecipeManagement.Authoring.Exceptions;
public class AuthoringException : RecipeManagementException { ... }

// Service level — inherits from component
namespace Company.Project.Modules.RecipeManagement.Authoring.RecipeEditor.Exceptions;
public class RecipeEditorException : AuthoringException { ... }
```

## Namespace Convention

Namespaces follow the project name plus folder hierarchy:

```
Company.Project.Modules.{ModuleName}.Abstractions                  # separate project
Company.Project.Modules.{ModuleName}.Abstractions.Events           # folder in Abstractions project
Company.Project.Modules.{ModuleName}                               # module project root
Company.Project.Modules.{ModuleName}.{ComponentName}               # folder in module project
Company.Project.Modules.{ModuleName}.{ComponentName}.Abstractions  # folder — cross-component, NOT a separate project
Company.Project.Modules.{ModuleName}.{ComponentName}.{ServiceName} # folder
Company.Project.Modules.{ModuleName}.{ComponentName}.{ServiceName}.Contracts
Company.Project.Modules.{ModuleName}.{ComponentName}.{ServiceName}.Configuration
```

Component- and service-level `Abstractions/` folders share the same parent namespace — they're inside the module's csproj. Only **module-level** `Abstractions` is a separate project (default), so other modules can reference contracts without dragging in the implementation assembly.

### Standalone Mode

For services that don't belong to a module (e.g., infrastructure services, single-purpose utilities), drop the `Modules.{Module}` segment and place them inside the Host:

```
Company.Project.Services.{ServiceName}
Company.Project.Services.{ServiceName}.Contracts
```

## Cross-Module Communication

| Producer | Event | Consumer |
|---|---|---|
| `CookingExperience.Social.ReviewManager` | `ReviewCreatedEvent` | `RecipeManagement.Discovery.Recommender` |
| `MealPlanning.Shopping.ListGenerator` | `ListGeneratedEvent` | `MealPlanning.Shopping.PriceTracker` (intra-module) |

Cross-module: the consumer's project references the producing module's `.Abstractions` project (e.g., `Company.Project.Modules.CookingExperience.Abstractions`) — never the implementation project. Cross-component within a module: reference the producing component's `Abstractions/` folder. Cross-service within a component: reference the producing service's `Abstractions/` folder. Never reference internal types across boundaries.

```
Module A (.csproj)                          Module B (.csproj)
┌──────────────────────────┐                ┌──────────────────────────┐
│ Module A's .Abstractions │◄──ProjectRef───┤ Service.cs               │
│ project (cross-module)   │                │ (consumes A's contracts) │
└──────────────────────────┘                └──────────────────────────┘

┌─────────────────┐                         Component Y (folder, same module)
│ Component X     │                         ┌─────────────────┐
│ /Abstractions/ ◄┼───────folder ref────────┤ Service.cs      │
│ (cross-comp)    │                         └─────────────────┘
│                 │
│ Service A       │                         Service B (folder, same component)
│ /Abstractions/◄─┼───────folder ref────────┤ Service.cs      │
│ (cross-svc)     │                         └─────────────────┘
└─────────────────┘
```

## Registration Chain

Registration cascades: Host → Module → Component → Service. The Host decides which modules to register based on feature flags.

### Host Program.cs / Extensions/StartupExtensions.cs

```csharp
namespace Company.Project.Host.Extensions;

public static class StartupExtensions
{
    public static IServiceCollection AddModules(
        this IServiceCollection services,
        IFeatureFlags flags)
    {
        if (flags.RecipeManagementEnabled)
            services.AddRecipeManagementModule();

        if (flags.MealPlanningEnabled)
            services.AddMealPlanningModule();

        if (flags.CookingExperienceEnabled)
            services.AddCookingExperienceModule();

        return services;
    }
}
```

### Module Extensions/StartupExtensions.cs

```csharp
namespace Company.Project.Modules.{ModuleName}.Extensions;

public static class StartupExtensions
{
    public static IServiceCollection Add{ModuleName}Module(
        this IServiceCollection services)
    {
        services.Add{ComponentName1}();
        services.Add{ComponentName2}();
        return services;
    }
}
```

### Component Extensions/StartupExtensions.cs

```csharp
namespace Company.Project.Modules.{ModuleName}.{ComponentName}.Extensions;

public static class StartupExtensions
{
    public static IServiceCollection Add{ComponentName}(
        this IServiceCollection services)
    {
        services.Add{ServiceName1}();
        services.Add{ServiceName2}();
        return services;
    }
}
```

### Service Extensions/StartupExtensions.cs

See [standard-service.md](standard-service.md) for the service-level registration pattern.

## Project References

```
Company.Project.Host.csproj
├── ProjectReference: Company.Project.Abstractions
├── ProjectReference: Company.Project.Modules.RecipeManagement
├── ProjectReference: Company.Project.Modules.RecipeManagement.Abstractions
├── ProjectReference: Company.Project.Modules.MealPlanning
└── ProjectReference: Company.Project.Modules.MealPlanning.Abstractions

Company.Project.Modules.RecipeManagement.csproj
├── ProjectReference: Company.Project.Abstractions
├── ProjectReference: Company.Project.Modules.RecipeManagement.Abstractions
└── ProjectReference: Company.Project.Modules.CookingExperience.Abstractions   # only when consuming CookingExperience contracts

Company.Project.Modules.RecipeManagement.Abstractions.csproj
└── ProjectReference: Company.Project.Abstractions   # only if app-wide types are used in the contracts
```

A module project never references another module's **implementation** — only its `.Abstractions` sibling. This keeps the dependency graph DAG-shaped (no module-to-module implementation coupling) and makes feature-flagged exclusions safe at runtime.

## Example

Recipe/cooking platform demonstrating multiple modules, components, and services:

```
src/
├── Company.Project.Abstractions/
├── Company.Project.Host/
│
├── Company.Project.Modules.RecipeManagement.Abstractions/
├── Company.Project.Modules.RecipeManagement/
│   ├── Authoring/                                  # Write path
│   │   ├── RecipeEditor/                           # CRUD for recipes
│   │   ├── IngredientParser/                       # "2 cups flour" → structured data
│   │   └── MediaUploader/                          # Photo/video handling
│   └── Discovery/                                  # Read path
│       ├── RecipeSearch/                           # Full-text + faceted search
│       ├── Recommender/                            # "You might like" suggestions
│       └── CollectionManager/                      # User-curated collections
│
├── Company.Project.Modules.MealPlanning.Abstractions/
├── Company.Project.Modules.MealPlanning/
│   ├── Planning/                                   # Weekly meal plans
│   │   ├── PlanBuilder/                            # Drag-drop meal calendar
│   │   └── NutritionCalculator/                    # Aggregate macros
│   └── Shopping/                                   # Grocery lists
│       ├── ListGenerator/                          # Meal plan → shopping list
│       ├── StoreLocator/                           # Find stores, aisle mapping
│       └── PriceTracker/                           # Compare prices
│
├── Company.Project.Modules.CookingExperience.Abstractions/
├── Company.Project.Modules.CookingExperience/
│   ├── StepByStep/                                 # Guided cooking
│   │   ├── CookingSession/                         # Real-time step tracking
│   │   ├── Timer/                                  # Multi-timer management
│   │   └── Substitution/                           # "Out of X? Use Y"
│   └── Social/                                     # Community features
│       ├── ReviewManager/                          # Ratings + reviews
│       ├── CookingLog/                             # "I made this" history
│       └── ShareManager/                           # Social media sharing
│
├── Company.Project.Modules.UserProfile.Abstractions/
└── Company.Project.Modules.UserProfile/
    └── Identity/                                   # Single component
        ├── ProfileManager/                         # Preferences, dietary restrictions
        ├── SkillTracker/                           # Beginner → expert progression
        └── NotificationPreferences/                # Email/push settings
```

### Cross-Module Communication

| Producer | Event | Consumer |
|---|---|---|
| `CookingExperience.Social.ReviewManager` | `ReviewCreatedEvent` | `RecipeManagement.Discovery.Recommender` |
| `MealPlanning.Shopping.ListGenerator` | `ListGeneratedEvent` | `MealPlanning.Shopping.PriceTracker` |

Consumers reference the producing module's `.Abstractions` project (cross-module) or the producing component's `Abstractions/` folder (intra-module). Internal service types are never crossed.

### Observability Drill-Down

Dashboards cascade from broad to specific, enabling incident triage:

| Level | Dashboard scope | Example | Owned by |
|---|---|---|---|
| App (Host) | All modules side by side | "Platform Overview" — module health matrix, error budget | SRE / on-call |
| Module | All components in one domain | "RecipeManagement" — SLA status, cross-component event lag | Domain owner |
| Component | All services in one sub-domain | "Authoring" — request volume by service, error rate breakdown | Team lead |
| Service | One service's metrics | "RecipeEditor" — latency p50/p95/p99, active connections | Service developer |

The pattern is a drill-down: app dashboard shows a red module → module dashboard shows which component → component dashboard shows which service → service dashboard shows the details.

### Abstractions/ Content

Each `Abstractions` project (module level) and `Abstractions/` folder (component, service levels) contains the same subfolders, organized by communication role:

| Subfolder | Role | Example |
|---|---|---|
| Events/ | What gets published when something happens | `RecipeCreatedEvent` |
| Interfaces/ | Behavioral contracts to implement/consume | `IRecipeEditor` |
| Models/ | Supporting shared types (enums, value objects) | `RecipeStatus`, `Ingredient` |
| Requests/ | What you send to invoke an operation | `CreateRecipeRequest` |
| Responses/ | What you get back | `RecipeResponse` |
