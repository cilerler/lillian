---
name: solution-structure
description: Source of truth for the opinionated .NET solution folder structure (root scaffolding, /docs, /src/Modules/Component/Service hierarchy, /tools/Kubernetes, /tests) and the documentation placement rules that govern items inside it. Use when deciding folder structure, directory layout, repo layout, or where a file belongs.
type: guidance
applies_to:
  - Developer
  - Architect
  - Documenter
  - DBA
  - Reviewer
mandatory: conditional
mandatory_when:
  - Deciding where a file/folder goes inside the .NET solution
  - Placing a doc, dashboard, Kubernetes manifest, embedded SQL, or service scaffold
triggers:
  - folder structure
  - directory layout
  - solution structure
  - repo layout
  - where does this go
  - file placement
  - opinionated folder
references: []
summary: Source of truth for the opinionated .NET solution folder structure (root scaffolding, /docs, /src/Modules/Component/Service hierarchy, /tools/Kubernetes, /tests) and the documentation placement rules that govern items inside it.
---

# Solution Structure

Source of truth for the opinionated **.NET solution** folder structure. When any skill places a file inside this repo, the rules come from here.

> Scope: this skill defines **only** the in-repo `.NET Solution` layout. It does **not** cover workspace structure (`%USERPROFILE%\Source\...`), company-wide document taxonomy, email aliases, RBAC / queue / artifact / test-project / repository naming — those are separate concerns owned elsewhere.

## Consumers

| Skill | Reads from this skill |
|-------|-----------------------|
| `dotnet-service-generator` | `/src/{Organization}.{Product}.Modules.{Module}/{Component}/{Service}/...` paths and per-service folder shape |
| `documentation-generator` | `/docs/...` placement and ticket/project folder shapes (that skill owns filename, identifier, and attachments conventions) |
| `infrastructure` | `/tools/Kubernetes/{base,overlays}` Kustomize layout |
| `observability` | `/Observability/Grafana/` dashboard placement at app/module/component/service tiers |
| `mssql-table-scaffolder` | `/Resources/SQL/` placement when SQL is embedded in a service |
| `mssql-bulk-data-operations` | `/docs/tickets/.../attachments/` or `/docs/runbooks/.../attachments/` placement for operational SQL scripts |

---

## Documentation Placement Rules

These rules govern items inside the `/docs/` and `Modules/.../Docs/` subtrees of the solution. Attachments, filename, and identifier conventions are owned by the [`documentation-generator`](../documentation-generator/SKILL.md) skill.

### Tickets and Projects

- One folder per ticket: `/docs/tickets/GITHUB-{N}/` with required `Handoff.md` + `attachments/Handoff/`.
- One folder per project: `/docs/projects/P{N}/` with required `BusinessCase.md`, optional `BusinessCaseFinancialModel.md`, `Retrospective.md`, `TestPlan.md`, `StatusUpdates/{yyyyMMddHHmm}-{slug}.md`, `attachments/{BasenameMatchingDoc}/`.

---

## .NET Solution Folder Structure

```
/.vscode                                    // Visual Studio Code settings
  - settings.json                           // Workspace settings
  - launch.json                             // Debugging configuration
  - tasks.json                              // Task configuration
  - extensions.json                         // Recommended extensions
/.git                                       // Git configuration
  - config                                  // Git configuration file
/.github                                    // GitHub configuration
  - CODEOWNERS                              // Code owners for the repository
  - PULL_REQUEST_TEMPLATE.md                // Pull request template
  /ISSUE_TEMPLATE                           // Issue templates
    - bug_report.yml                        // Bug report template
    - feature_request.yml                   // Feature request template
    - custom_template.yml                   // Custom template
  /workflows                                // GitHub Actions workflows
    - ci.yml                                // CI/CD pipeline for continuous integration
    - checks.yml                            // CI/CD pipeline for running checks and tests

/docs                                       // App-level documentation
  - README.md                               // Master index — pointers to sections below
  - business-glossary.md                    // SINGLETON — no /attachments/ (promote to its own typed folder if support material is needed)
  - data-dictionary.md                      // SINGLETON — no /attachments/
  - tech-stack-overview.md                  // SINGLETON — no /attachments/

  /adrs                                     // Architecture Decision Records — why we chose X over Y (immutable once accepted)
    - {yyyyMMddHHmm}-{slug}.md              // One decision per file (e.g. 202504141430-use-event-sourcing.md)
    /attachments
      /{yyyyMMddHHmm}-{slug}                // Per-doc supporting files (diagrams, screenshots, data, recordings)
  /rfcs                                     // Request for Comments — proposals under discussion, may or may not be accepted
    - {yyyyMMddHHmm}-{slug}.md
    /attachments
      /{yyyyMMddHHmm}-{slug}
  /designs                                  // Technical Design Documents — narrative explanation of how a feature/system works
    - {yyyyMMddHHmm}-{slug}.md
    /attachments
      /{yyyyMMddHHmm}-{slug}
  /specs                                    // Machine-readable contract definitions — OpenAPI, GraphQL, JSON Schema, etc. (no /attachments/ — these ARE the artifacts)
    - {slug}.yaml
    - {slug}.json
  /diagrams                                 // Shared system/architecture diagrams referenced by multiple docs (no /attachments/ — these ARE the artifacts)
    - {slug}.puml                           // PlantUML source
    - {slug}.excalidraw                     // Excalidraw source
    - {slug}.mermaid                        // Mermaid source
  /notebooks                                // Jupyter notebooks for analysis or runnable examples (no /attachments/ — these ARE the artifacts)
    - {slug}.ipynb

  /architectures                            // Architecture overviews — Diátaxis "Explanation" docs describing how existing systems / modules / components / areas work
    - {slug}.md                             // Living documents — no date prefix. Multiple per scope (e.g., system.md, auth-flow.md, billing-pricing-engine.md)
    /attachments
      /{slug}
  /runbooks                                 // App-wide operational procedures (deploy, backup, restore, etc.)
    - {slug}.md                             // Living documents — no date prefix (updated as systems evolve)
    /attachments
      /{slug}
  /sops                                     // Standard Operating Procedures — formalized org processes
    - {slug}.md                             // Living documents — no date prefix (revised in place as procedures change)
    /attachments
      /{slug}
  /pirs                                     // Post Incident Reviews — what broke, why, how we fixed it
    - {yyyyMMddHHmm}-{slug}.md
    /attachments
      /{yyyyMMddHHmm}-{slug}
  /test-plans                               // App / release-level test strategy (opt-in; required in regulated contexts)
    - {yyyyMMddHHmm}-{slug}.md              // Use when scope is a release or initiative not tied to a P{N} project
    /attachments
      /{yyyyMMddHHmm}-{slug}
  /test-cases                               // QA verification of acceptance criteria
    - {slug}.md                             // Living documents — no date prefix (updated as features change)
    /attachments
      /{slug}

  /tickets                                  // Per-ticket working artifacts and handoffs
    /GITHUB-{N}                             // Always a folder; one per ticket (identifier from external tracker, e.g. GITHUB-{N})
      - Handoff.md                          // REQUIRED — final handoff summary at ticket resolution
      /attachments
        /Handoff                            // Subfolder name matches doc basename — holds scripts, screenshots, investigation notes, raw data, recordings

  /projects                                 // Per-project working artifacts and documentation
    /P{N}                                   // Always a folder; one per project (sequential internal ID: P1, P2, P3, ...)
      - BusinessCase.md                     // REQUIRED — initiates the project (scope, rationale, approval)
      - BusinessCaseFinancialModel.md       // Optional — financial evaluation (OPEX/CAPEX, ROI, payback period)
      - Retrospective.md                    // End-of-project retrospective
      - TestPlan.md                         // Optional — project-scoped test strategy (sits alongside BusinessCase)
      /StatusUpdates                        // Iterative status reports over the life of the project
        - {yyyyMMddHHmm}-{slug}.md
        /attachments
          /{yyyyMMddHHmm}-{slug}            // Per-update supporting files
      /attachments
        /BusinessCase                       // Each subfolder matches a doc basename in this folder
        /BusinessCaseFinancialModel
        /Retrospective
        /TestPlan

/tools
  /Kubernetes
    - kustomization.yaml                    // Kustomize configuration for Kubernetes
    /base
      - kustomization.yaml                  // Base kustomize configuration for Kubernetes
      - deployment.yaml                     // Base deployment configuration for Kubernetes
      - service.yaml                        // Base service configuration for Kubernetes
    /overlays
      /integration
        /base                               // Base configuration for Integration environment
          - kustomization.yaml              // Base kustomize configuration for Integration environment
          - deployment.yaml                 // Base deployment configuration for Integration environment
          - service.yaml                    // Base service configuration for Integration environment
        /default                            // Default configuration for Integration environment
          - kustomization.yaml              // Default kustomize configuration for Integration environment
          - deployment.yaml                 // Default deployment configuration for Integration environment
          - service.yaml                    // Default service configuration for Integration environment
        /alternative                        // Alternative configuration for Integration environment
          - kustomization.yaml              // Alternative kustomize configuration for Integration environment
          - deployment.yaml                 // Alternative deployment configuration for Integration environment
          - service.yaml                    // Alternative service configuration for Integration environment
      /testing
        /base
          - kustomization.yaml
          - deployment.yaml
          - service.yaml
        /default
          - kustomization.yaml
          - deployment.yaml
          - service.yaml
        /alternative
          - kustomization.yaml
          - deployment.yaml
          - service.yaml
      /staging
        /base
          - ...
        /default
          - ...
        /alternative
          - ...
      /production
        /...
/tests
  - App.http                                            // Cross-module HTTP request tests
  - {ModuleName}.http                                   // Cross-component tests within a module
  - {ComponentName}.http                                // Cross-service tests within a component
  - {ServiceName}.http                                  // Tests for one service's API endpoints
  /{Organization}.{Product}.Domain.Integration.Tests
    - {Organization}.{Product}.Domain.Integration.Tests.csproj
    - EnterpriseServiceTests.cs
  /{Organization}.{Product}.Domain.Unit.Tests
    - {Organization}.{Product}.Domain.Unit.Tests.csproj
    - EnterpriseServiceTests.cs
  /{Organization}.{Product}.Host.E2E.Tests
    - {Organization}.{Product}.Host.E2E.Tests.csproj
    - HealthCheckTests.cs
  /{Organization}.{Product}.Host.Integration.Tests
    - {Organization}.{Product}.Host.Integration.Tests.csproj
    - HealthCheckTests.cs
  /{Organization}.{Product}.Host.Unit.Tests
    - {Organization}.{Product}.Host.Unit.Tests.csproj
    - HealthCheckTests.cs
  /{Organization}.{Product}.Tests.Common                         // Shared test utilities, fixtures, mocks
    - {Organization}.{Product}.Tests.Common.csproj
  /...
.dockerignore                               // Docker ignore file
.editorconfig                               // Editor configuration file
.gitattributes                              // Git attributes file
.gitignore                                  // Git ignore file
LICENSE                                     // License file
README.md                                   // Readme file explains the project
CHANGELOG.md                                // Changelog file for the project
azure-pipelines.yml                         // Azure DevOps pipeline configuration
Directory.Build.props                       // Common properties for all projects in the solution
Company.Solution.sln                        // Visual Studio solution file
/src
  /{Organization}.{Product}.Abstractions
  /{Organization}.{Product}.Extensions
  /{Organization}.{Product}.Domain
  /{Organization}.{Product}.Host
    - Program.cs                            // Entry point for the application
    - ProgramExtensions.cs                  // Extension methods for the program
    - StartupBackgroundService.cs           // Initial background service for the application
    - StartupHealthCheck.cs                 // Health check for the application
    - AppConfigurationExtensions.cs         // Configuration extensions for the application
    - appsettings.json                      // Configuration settings for the application
    - appsettings.Development.json          // Configuration settings for the development environment
    - appsettings.Integration.json          // Configuration settings for the integration environment
    - appsettings.Testing.json              // Configuration settings for the testing environment
    - appsettings.Staging.json              // Configuration settings for the staging environment
    - appsettings.Production.json           // Configuration settings for the production environment
    - Dockerfile                            // Docker configuration for containerization
    - {Organization}.{Product}.Host.csproj           // Project file
    - Buildinfo.txt                         // Build information to show when the app starts
    - App.razor                             // Main application component
    - Routes.razor                          // Route configuration for the application

    /Properties
      - launchSettings.json                 // Debugging settings for the project, Visual Studio and .NET Core CLI

    /Resources
      /SQL
        - Constants.cs
        - Query1.sql
        - Query2.sql
        - ...
      /...

    /wwwroot
      - index.html                          // Default HTML file for the application
      - favicon.ico                         // Favicon for the application
      - ...
      /css
        - app.css
        - ...

    /Pages
      - Page1.razor                         // Razor page for the application
      - Page2.razor
      - ...

    /PageComponents
      - PageComponent1.razor                // Page component for the application
      - PageComponent2.razor
      - ...

    /Layout
      - MainLayout.razor                    // Main layout component
      - NavMenu.razor                       // Navigation menu component
      - _Imports.razor                      // Import statements for the application

    /Abstractions                              // App-wide shared contracts (cross-module)
      /Events
      /Interfaces
      /Models                                  // Enums, value objects, shared DTOs
      /Requests
      /Responses
    /Contracts                                 // App-wide internal interfaces for shared helpers
    /Exceptions                                // App-wide base exceptions
    /Extensions
      - StartupExtensions.cs                   // Registers modules — feature flags decide which are active per deployment
    /Internals                                 // App-wide shared helper implementations
    /Observability
      /Grafana                                 // Platform overview dashboard
        - dashboard.json

  /{Organization}.{Product}.Modules.{Module1}.Abstractions    // Separate csproj — module's public contract (cross-module)
    - {Organization}.{Product}.Modules.{Module1}.Abstractions.csproj
    /Events
    /Interfaces
    /Models                                          // Enums, value objects, shared DTOs
    /Requests
    /Responses

  /{Organization}.{Product}.Modules.{Module1}                 // Module project — owns components and services as folders
    - {Organization}.{Product}.Modules.{Module1}.csproj       // References its .Abstractions sibling; references other modules' .Abstractions when consuming their contracts
    - Constants.cs                                   // Module-wide constants
    /Contracts                                       // Module-wide internal interfaces for shared helpers
    /Docs                                            // Module-scoped documentation (optional)
      /adrs                                          // Module-specific architectural decisions
      /rfcs                                          // Module-specific proposals
      /runbooks                                      // Module-level operational procedures
    /Exceptions                                      // Module-level base exceptions
    /Extensions
      - StartupExtensions.cs                         // Registers all components in this module
    /Internals                                       // Module-wide shared helper implementations
    /Observability
      /Grafana                                       // Module-level domain health dashboard
        - dashboard.json

    /{Component1}                                    // Folder inside module project — always required (even single-component modules)
      /Abstractions                                  // Component's public contract (cross-component within module — folder, NOT separate csproj)
        /Events
        /Interfaces
        /Models
        /Requests
        /Responses
      /Contracts                                     // Component-wide internal interfaces for shared helpers
      /Docs                                          // Component-scoped documentation (optional)
        /adrs                                        // Component-specific architectural decisions
        /rfcs                                        // Component-specific proposals
        /runbooks                                    // Component-level operational procedures
      /Exceptions                                    // Component-level base exceptions
      /Extensions
        - StartupExtensions.cs                       // Registers all services in this component
      /Internals                                     // Component-wide shared helper implementations
      /Observability
        /Grafana                                     // Component-level aggregated dashboard
          - dashboard.json
      - Constants.cs                                 // Component-wide constants

      /{Service1}                                    // Folder — full service structure
        /Abstractions                                // Public contract (cross-service within component — folder)
          /Events                                    // Domain events
          /Interfaces                                // Public interfaces (when externally consumed)
          /Models                                    // Enums, value objects, shared DTOs
          /Requests                                  // Request DTOs
          /Responses                                 // Response DTOs
        /Api                                         // HTTP endpoints (optional)
          - {ServiceName}Api.cs                      // Route group definition
          - {Verb}Endpoint.cs                        // One file per endpoint
        /Clients                                     // External HTTP API wrappers
        /Configuration                               // Settings and config binding
          - {ServiceName}Settings.cs
        /Contracts                                   // Internal interfaces (DI/testing)
          - I{ServiceName}.cs                        // Default: internal
        /Docs                                        // Service-scoped documentation (optional)
          - README.md                                // Service overview
          - runbook.md                               // Service-specific operational procedures
          - test-plan.md                             // Service-specific test strategy
        /Exceptions                                  // Service-specific exceptions
        /Extensions                                  // DI registration, model extensions
          - StartupExtensions.cs
        /Internals                                   // Internal helper implementations
        /Mappers                                     // Object mapping between types
        /Models                                      // Internal entities/domain objects
        /Observability                               // Dashboards and diagnostics
          /Grafana                                   // Per-service dashboard
            - dashboard.json
        /Resources                                   // Embedded resource files — optional (SQL, templates, etc.)
          /SQL
            - {Name}.sql
            - ResourceLoader.cs                      // Lazy loader for embedded resources
            - Constants.cs                           // Resource file name constants
        /Validators                                  // Custom validation attributes
        - Constants.cs                               // Service constants + Metrics nested class
        - {ServiceName}Service.cs                    // Core business logic
        - {ServiceName}Worker.cs                     // Background service lifecycle (optional)
        - {ServiceName}HealthCheck.cs                // Health monitoring (optional)

      /{Service2}
        /...

    /{Component2}
      /...

  /{Organization}.{Product}.Modules.{Module2}.Abstractions
    /...
  /{Organization}.{Product}.Modules.{Module2}
    /...
```
