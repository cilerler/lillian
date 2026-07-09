# Skills Index

This file maps task triggers to skill documents.
If multiple skills match a task, apply all applicable skills.

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

## plantuml-sequence-diagram-generator
- Path: `.github/skills/plantuml-sequence-diagram-generator/SKILL.md`
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

## solution-structure
- Path: `.github/skills/solution-structure/SKILL.md`
- Applies to: Developer, Architect, Documenter, DBA, Reviewer
- Mandatory when:
  - Deciding where a file/folder goes inside the .NET solution
  - Placing a doc, dashboard, Kubernetes manifest, embedded SQL, or service scaffold
- Triggers:
  - "folder structure"
  - "directory layout"
  - "solution structure"
  - "repo layout"
  - "where does this go"
  - "file placement"
  - "opinionated folder"

---

## documentation-generator
- Path: `.github/skills/documentation-generator/SKILL.md`
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

## work-item-generator
- Path: `.github/skills/work-item-generator/SKILL.md`
- Applies to: Planner, Developer, Architect
- Mandatory when:
  - Creating work items (initiatives, epics, features, stories, bugs, spikes, enhancements, tasks)
  - Filing bugs or logging issues
- Triggers:
  - "initiative"
  - "epic"
  - "feature"
  - "story"
  - "bug"
  - "spike"
  - "enhancement"
  - "task"
  - "create issue"
  - "create ticket"
  - "file a bug"

---

## mssql-bulk-data-operations
- Path: `.github/skills/mssql-bulk-data-operations/SKILL.md`
- Applies to: Developer (implementation), DBA (operations)
- Mandatory when:
  - Performing large-scale INSERT, UPDATE, or DELETE operations (millions of rows)
  - Generating batched T-SQL scripts for bulk data processing
- Triggers:
  - "bulk update"
  - "bulk insert"
  - "bulk delete"
  - "update millions of records"
  - "insert millions of records"
  - "batch update"
  - "batch insert"
  - "large data operation"
  - "mass update"
  - "mass insert"

---

## excalidraw-diagram-generator
- Path: `.github/skills/excalidraw-diagram-generator/SKILL.md`
- Applies to: Developer, Architect, Documenter
- Mandatory when:
  - Creating visual diagrams of workflows, architectures, or concepts
  - Generating Excalidraw JSON files
- Triggers:
  - "excalidraw"
  - "diagram"
  - "visualize"
  - "architecture diagram"
  - "workflow diagram"

---

## session-handoff
- Path: `.github/skills/session-handoff/SKILL.md`
- Applies to: All agents (session level)
- Mandatory when:
  - The user wants to wrap up the session or hand off before clearing context
- Triggers:
  - "session handoff"
  - "wrap up session"
  - "hand off"
  - "handoff summary"
  - "summarize before I clear"
- Note: for a long-form project/role handover **document**, use `documentation-generator` (takeover-handover template) instead.

---

## storm-research
- Path: `.github/skills/storm-research/SKILL.md`
- Applies to: All agents
- Mandatory when:
  - A multi-perspective, citation-verified research briefing is requested
- Triggers:
  - "storm research"
  - "storm report"
  - "STORM briefing"
  - "multi-perspective research"
- Note: heavyweight pipeline (~9-11 subagents per run); for a simple factual lookup, answer directly instead.

---

# Libraries

Workspace libraries in `common-libraries/`. Use these instead of custom implementations.
Each library has a README with usage instructions.

| Library | Purpose | README |
|---------|---------|--------|
| MyOrganization.OpenTelemetry | OpenTelemetry configuration and instrumentation | [README](common-libraries/MyOrganization.OpenTelemetry/README.md) |
| MyOrganization.Diagnostics | Diagnostic utilities, distributed tracing helpers | [README](common-libraries/MyOrganization.Diagnostics/README.md) |
| MyOrganization.Diagnostics.Abstractions | Diagnostic abstractions | [README](common-libraries/MyOrganization.Diagnostics.Abstractions/README.md) |
| MyOrganization.Services.DistributedLock | Distributed locking with heartbeat support | [README](common-libraries/MyOrganization.Services.DistributedLock/README.md) |
| MyOrganization.Services.DistributedLock.Abstractions | Distributed lock abstractions | [README](common-libraries/MyOrganization.Services.DistributedLock.Abstractions/README.md) |
| MyOrganization.Services.DistributedLock.Redis | Redis-based distributed lock implementation | [README](common-libraries/MyOrganization.Services.DistributedLock.Redis/README.md) |
| MyOrganization.Services.MessageQueue | Provider-agnostic messaging infrastructure | [README](common-libraries/MyOrganization.Services.MessageQueue/README.md) |
| MyOrganization.Services.MessageQueue.RabbitMq | RabbitMQ messaging implementation | [README](common-libraries/MyOrganization.Services.MessageQueue.RabbitMq/README.md) |
| MyOrganization.Services.CloudStorage.Abstractions | Provider-agnostic cloud storage | [README](common-libraries/MyOrganization.Services.CloudStorage.Abstractions/README.md) |
| MyOrganization.Services.TokenBroker | JWT service-to-service authentication | [README](common-libraries/MyOrganization.Services.TokenBroker/README.md) |
| MyOrganization.EntityFrameworkCore.SqlServer | EF Core bulk operations via SqlBulkCopy | [README](common-libraries/MyOrganization.EntityFrameworkCore.SqlServer/README.md) |
| MyOrganization.Extensions.Configuration | Configuration extensions | [README](common-libraries/MyOrganization.Extensions.Configuration/README.md) |
| MyOrganization.Extensions.DependencyInjection | DI extensions | [README](common-libraries/MyOrganization.Extensions.DependencyInjection/README.md) |
| MyOrganization.Extensions.Hosting | Hosting extensions | [README](common-libraries/MyOrganization.Extensions.Hosting/README.md) |
| MyOrganization.AspNetCore.Middleware | ASP.NET Core middleware | [README](common-libraries/MyOrganization.AspNetCore.Middleware/README.md) |
| MyOrganization.Primitives | Common primitives | [README](common-libraries/MyOrganization.Primitives/README.md) |
| MyOrganization.Testing.Primitives | Testing utilities | [README](common-libraries/MyOrganization.Testing.Primitives/README.md) |
| MyOrganization.System.Xml.Serialization | XML serialization utilities | [README](common-libraries/MyOrganization.System.Xml.Serialization/README.md) |
| MyOrganization.Kiota.Client | Kiota HTTP client | [README](common-libraries/MyOrganization.Kiota.Client/README.md) |
| MyOrganization.OData.Client | OData client | [README](common-libraries/MyOrganization.OData.Client/README.md) |
