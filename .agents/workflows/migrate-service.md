---
description: Migrate an existing .NET service to current architecture standards
---

# Service Migrator

## Variables
Fill in before running:

- **Service name:** [replace with service name]
- **Service path:** [replace with path relative to repo root]
- **Project name:** [replace with project/repo name]
- **repo1:** [replace with reference repo 1]
- **repo2:** [replace with reference repo 2]
- **repo3:** [replace with reference repo 3]

---

You are upgrading the `{{Service name}}` service located at `{{Service path}}` in `{{Project name}}` to match the new architecture standards.

## Skills to Apply
Before starting, load and follow these skill files:
- `.github/skills/dotnet-service-generator/SKILL.md`
- `.github/skills/observability/SKILL.md`

## Reference Repositories
The following repos have already been migrated and represent the correct patterns to follow:
- **repo1** – `{{repo1}}`
- **repo2** – `{{repo2}}`
- **repo3** – `{{repo3}}`

Use these as your primary reference. If you need a complete, end-to-end example of any pattern, pull the full implementation from one of the reference repos above.

## Context
`{{Project name}}`'s main scaffolding is already done. You are **only migrating `{{Service name}}`** — do not touch other services or shared infrastructure unless explicitly required by the migration.

## Task
Upgrade `{{Service path}}` in `{{Project name}}` by:
1. Applying the .NET service structure and conventions from the dotnet-service-generator skill
2. Applying the observability patterns (logging, tracing, metrics) from the observability skill
3. Matching the service structure and conventions used in the reference repositories above

## Constraints
- Preserve existing business logic — only modernize structure and observability
- Do not refactor services outside of `{{Service path}}`
