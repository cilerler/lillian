# Skills Index

This file maps task triggers to skill documents.
If multiple skills match a task, apply all applicable skills.

---

## dotnet-transformation-service
- Path: `.github/skills/dotnet-transformation-service/SKILL.md`
- Applies to: Developer (implementation), Architect (design)
- Mandatory when:
  - Creating a new transformation service project
  - Scaffolding ETL service repository structure
- Triggers:
  - "create transformation service"
  - "new etl service"
  - "create service repository"

---

## dotnet-service-generator
- Path: `.github/skills/dotnet-service-generator/SKILL.md`
- Applies to: Developer (implementation), Architect (review)
- Mandatory when:
  - Creating a new .NET service
  - Scaffolding service modules
- Triggers:
  - "create a service"
  - "scaffold service"
  - "add new service"
  - "generate service boilerplate"

---

## mssql-table-scaffolder
- Path: `.github/skills/mssql-table-scaffolder/SKILL.md`
- Applies to: Developer (implementation), DBA (design)
- Mandatory when:
  - Creating or standardizing MSSQL tables
  - Adding new schema artifacts
- Triggers:
  - "create table"
  - "generate table"
  - "scaffold table"
  - "standardize table"
  - "migrate table"

---

## plantuml-sequence
- Path: `.github/skills/plantuml-sequence/SKILL.md`
- Applies to: Planner, Developer, Architect
- Mandatory when:
  - A sequence or interaction diagram is requested
- Triggers:
  - "sequence diagram"
  - "PlantUML"
  - "service flow"
  - "API interaction diagram"

---

## observability
- Path: `.github/skills/observability/SKILL.md`
- Applies to: Architect (defines requirements), Developer (implements)
- Mandatory when:
  - Defining SLIs or observability requirements
  - Creating dashboards or alerts
  - Instrumenting with OpenTelemetry
- Triggers:
  - "dashboard"
  - "metrics"
  - "tracing"
  - "alerting"
  - "SLI"
  - "observability"

---

## infrastructure
- Path: `.github/skills/infrastructure/SKILL.md`
- Applies to: Developer (implements), Reviewer (verification)
- Mandatory when:
  - Creating or updating Dockerfiles
  - Creating or updating Kubernetes manifests
  - Configuring health probes
- Triggers:
  - "dockerfile"
  - "kubernetes"
  - "container"
  - "deployment"
  - "health probe"

---

## documentation
- Path: `.github/skills/documentation/SKILL.md`
- Applies to: Documenter, Architect (ADRs, RFCs)
- Mandatory when:
  - Creating ADRs or RFCs
  - Writing design documents
  - Creating runbooks or SOPs
  - Creating handover documentation
  - Creating data dictionaries
- Triggers:
  - "ADR"
  - "RFC"
  - "design doc"
  - "runbook"
  - "postmortem"
  - "SOP"
  - "handover"
  - "data dictionary"

---

# Libraries

Workspace libraries in `libraries/parasite/src/`. Use these instead of custom implementations.
Each library has a README with usage instructions.

| Library | Purpose | README |
|---------|---------|--------|
| MyOrganization.OpenTelemetry | OpenTelemetry configuration and instrumentation | [README](../../../libraries/parasite/src/MyOrganization.OpenTelemetry/README.md) |
| MyOrganization.Diagnostics | Diagnostic utilities, distributed tracing helpers | [README](../../../libraries/parasite/src/MyOrganization.Diagnostics/README.md) |
| MyOrganization.Diagnostics.Abstractions | Diagnostic abstractions | [README](../../../libraries/parasite/src/MyOrganization.Diagnostics.Abstractions/README.md) |
| MyOrganization.Services.DistributedLock | Distributed locking with heartbeat support | [README](../../../libraries/parasite/src/MyOrganization.Services.DistributedLock/README.md) |
| MyOrganization.Services.DistributedLock.Abstractions | Distributed lock abstractions | [README](../../../libraries/parasite/src/MyOrganization.Services.DistributedLock.Abstractions/README.md) |
| MyOrganization.Services.DistributedLock.Redis | Redis-based distributed lock implementation | [README](../../../libraries/parasite/src/MyOrganization.Services.DistributedLock.Redis/README.md) |
| MyOrganization.Services.MessageQueue | Provider-agnostic messaging infrastructure | [README](../../../libraries/parasite/src/MyOrganization.Services.MessageQueue/README.md) |
| MyOrganization.Services.MessageQueue.RabbitMq | RabbitMQ messaging implementation | [README](../../../libraries/parasite/src/MyOrganization.Services.MessageQueue.RabbitMq/README.md) |
| MyOrganization.Services.CloudStorage.Abstractions | Provider-agnostic cloud storage | [README](../../../libraries/parasite/src/MyOrganization.Services.CloudStorage.Abstractions/README.md) |
| MyOrganization.Services.TokenBroker | JWT service-to-service authentication | [README](../../../libraries/parasite/src/MyOrganization.Services.TokenBroker/README.md) |
| MyOrganization.EntityFrameworkCore.SqlServer | EF Core bulk operations via SqlBulkCopy | [README](../../../libraries/parasite/src/MyOrganization.EntityFrameworkCore.SqlServer/README.md) |
| MyOrganization.Extensions.Configuration | Configuration extensions | [README](../../../libraries/parasite/src/MyOrganization.Extensions.Configuration/README.md) |
| MyOrganization.Extensions.DependencyInjection | DI extensions | [README](../../../libraries/parasite/src/MyOrganization.Extensions.DependencyInjection/README.md) |
| MyOrganization.Extensions.Hosting | Hosting extensions | [README](../../../libraries/parasite/src/MyOrganization.Extensions.Hosting/README.md) |
| MyOrganization.AspNetCore.Middleware | ASP.NET Core middleware | [README](../../../libraries/parasite/src/MyOrganization.AspNetCore.Middleware/README.md) |
| MyOrganization.Primitives | Common primitives | [README](../../../libraries/parasite/src/MyOrganization.Primitives/README.md) |
| MyOrganization.Testing.Primitives | Testing utilities | [README](../../../libraries/parasite/src/MyOrganization.Testing.Primitives/README.md) |
| MyOrganization.System.Xml.Serialization | XML serialization utilities | [README](../../../libraries/parasite/src/MyOrganization.System.Xml.Serialization/README.md) |
| MyOrganization.Kiota.Client | Kiota HTTP client | [README](../../../libraries/parasite/src/MyOrganization.Kiota.Client/README.md) |
| MyOrganization.OData.Client | OData client | [README](../../../libraries/parasite/src/MyOrganization.OData.Client/README.md) |
