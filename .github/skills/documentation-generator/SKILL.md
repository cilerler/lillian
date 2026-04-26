---
name: documentation-generator
type: guidance
applies_to:
  - Documenter
  - Planner
  - Architect
  - Developer
  - Tester
mandatory: conditional
triggers:
  - documentation
  - ADR
  - RFC
  - runbook
  - post incident review
  - postmortem
  - design doc
  - handover
  - handoff
  - SOP
  - business case
  - brag document
  - project status
  - retrospective
  - tech stack
  - architecture overview
  - data dictionary
  - performance improvement
  - test cases
  - test plan
  - role brief
  - job ad
  - hiring
  - recruiting
references:
  - templates/architecture-decision-record.md
  - templates/request-for-comments.md
  - templates/design-doc.md
  - templates/runbook.md
  - templates/post-incident-review.md
  - templates/standard-operating-procedure.md
  - templates/takeover-handover.md
  - templates/data-dictionary.md
  - templates/business-glossary.md
  - templates/business-case.md
  - templates/business-case-financial-model.md
  - templates/brag-document.md
  - templates/performance-improvement-plan.md
  - templates/project-status-update.md
  - templates/retrospective.md
  - templates/tech-stack-overview.md
  - templates/architecture-overview.md
  - templates/test-cases.md
  - templates/test-plan.md
  - templates/role-brief.md
summary: Document templates for ADRs, RFCs, design docs, runbooks, post incident reviews, SOPs, handovers, business cases, test plans, test cases, role briefs, and more.
---

# Documentation Skill

Provides standardized templates for all documentation types used in the repository.

## When to Use

| Phase | Document Type | When to Use | Created By | Reviewed By |
|-------|---------------|-------------|------------|-------------|
| 2. Justification & Approval | Business Case | To secure support, funding, or prioritization. Scales: light usage = problem + reasons + scope + risks; heavy usage = full investment justification | PM, Product Lead, Architect | Leadership, Finance |
| 2. Justification & Approval | Business Case Financial Model | To evaluate financial impact of a project | PM, Product Lead | Leadership, Finance |
| 3. Knowledge Transfer (in) / 9. Closure | Takeover & Handover | Single template covering both directions of ownership transfer — Takeover when inheriting a system, Handover when transferring out | Receiving / Departing Engineer | Receiving Team / Architect |
| 4. Decide & Design | RFC | Proposed changes before implementing | Documenter | Peers, Architects |
| 4. Decide & Design | ADR | Architecture decisions | Architect, Documenter | Senior Devs |
| 4. Decide & Design | Design Doc (aka Tech Spec) | Before coding complex features | Engineer, Tech Lead | Dev Team, Product |
| 5. Build Contract | Test Plan | Cross-feature, release, or project-level test strategy; required in regulated contexts (FDA, IEC 62304, ISO 13485, ISO 26262) | Test Lead, Tester | QA Lead, Product Owner, Engineering Lead |
| 5. Build Contract | Test Cases | For QA verification of acceptance criteria | Tester | Reviewer, QA |
| 7. Operate | Runbook | For handling systems & failures | Developer, SRE | Platform, On-call |
| 7. Operate | SOP | For repetitive tasks, compliance | DevOps, SRE | Team Lead |
| 8. Report Progress | Project Status Update | Regular reporting to stakeholders | Project Manager | Leadership |
| 9. Closure | Retrospective | At project end, to capture outcomes and lessons | PM, Team Lead | Leadership, Team |
| 10. Always-Living Reference | Tech Stack Overview | To document current technologies | Engineer, Tech Lead | New team members |
| 10. Always-Living Reference | Architecture Overview | To explain how the existing system / module / component works (Diátaxis "Explanation") | Architect, Tech Lead | Dev Team, New team members |
| 10. Always-Living Reference | Data Dictionary | To define schema, fields, data types | Data Engineers, DBAs | Data Governance |
| 10. Always-Living Reference | Business Glossary | To define key business terms | Product, Domain Experts | Product Owners |
| Orthogonal A. Incident | Post Incident Review (aka Postmortem) | After incidents | On-call Engineer | SRE Lead, Manager |
| Orthogonal B. People & Recruiting | Role Brief | Tech-team intake brief handed to HR/recruiting describing the kind of person we want; HR translates into a public job posting | Engineering Manager, Tech Lead | Hiring Manager, HR Partner |
| Orthogonal B. People & Recruiting | Brag Document | Before reviews or promo cycles | Individual | Manager |
| Orthogonal B. People & Recruiting | Performance Improvement Plan | When performance needs formal guidance | Manager, HR | HR, Department Head |

> **Project intake** is *not* a template here — small ideas live as a **GitHub issue**. If an issue grows into a project, graduate it into `/docs/projects/P{N}/BusinessCase.md` (light usage; financial sections skipped). Add `BusinessCaseFinancialModel.md` only when a financial gate engages.

## Lifecycle Phases

Templates group into phases. The flow is the *default* path; each project picks the subset that fits.

```
PHASE                          ARTIFACTS
─────────────────────────────────────────────────────────────────
1. Discovery / Inception       GitHub issue (intake — not a template)
2. Justification & Approval    Business Case (light or heavy)
                               → Business Case Financial Model
                                 (only if material)
3. Knowledge Transfer (in)     Takeover (single template covers both
                                 incoming and outgoing transfers)
4. Decide & Design             RFC → ADR(s) → Design Doc
                               ADRs emerge across all three —
                               and during Implementation
5. Build Contract              Test Plan (project-level, optional;
                                 parallel to Design Doc)
                               Test Cases (per-feature, derived from
                                 acceptance criteria; pre-code)
6. Implementation              Code gated by Test Cases
7. Operate                     Runbook (living) + SOP (repeatable)
8. Report Progress             Project Status Update (recurring)
9. Closure                     Handover (same template as Phase 3,
                                 used outgoing here)
                               Project Retrospective
10. Always-Living Reference    Tech Stack Overview (updated when an
                                 ADR changes a tech choice)
                               Architecture Overview (updated when
                                 system behavior or structure shifts)
                               Data Dictionary (updated on any schema
                                 change — no ADR required)
                               Business Glossary (updated whenever
                                 terminology enters or shifts)
─── ORTHOGONAL FLOWS ─────────────────────────────────────────────
A. Incident (any time, system-lifetime)
   Post Incident Review (aka Postmortem)
B. People & Recruiting (HR-adjacent flow, not in repo)
   Role Brief, Brag Document, Performance Improvement Plan
```

### Phase notes

- **Phase 1 (Discovery / Inception)** lives in the issue tracker, *not* the repo. Only graduates to a doc if it becomes a project.
- **Phase 2 (Justification & Approval)** — the Business Case template scales: light usage covers project-brief intake (problem + reasons + scope + risks); heavy usage adds the financial sections; a separate Business Case Financial Model is produced only when the analysis is material.
- **Phase 4 (Decide & Design)** — RFC, ADR, and Design Doc are not strictly linear; see *Lifecycle Ordering* below for which subset to pick. **ADRs can crystallize during RFC, during Design Doc work, or after-the-fact during Implementation** when an emergent decision needs capture.
- **Phase 5 (Build Contract)** — Test Cases derive from the Planner's *acceptance criteria*, not from the Design Doc. They can be drafted **before or after** the DD: pre-DD when acceptance criteria are clear and the design is uncontroversial; post-DD when the design surfaces edge cases. Test Plan, when used, runs **parallel to the Design Doc** because it depends on architecture choices to define environments and integration strategy.
- **Phase 10 (Always-Living Reference)** — these docs are *never closed*, but their update triggers differ:
  - **Tech Stack Overview** — updated when an ADR changes a tech choice (new framework, swapped database, new observability stack, etc.).
  - **Architecture Overview** — updated when system behavior or structure shifts (new component, swapped data flow, removed integration). The Diátaxis *Explanation* doc — describes how the existing system works for someone with zero prior context. Defers *why* to ADRs, *what tools* to Tech Stack, *fields* to Data Dictionary.
  - **Data Dictionary** — updated on any schema change (new table, new field, type change, removal). No ADR required; a migration is enough.
  - **Business Glossary** — updated whenever new terminology enters the domain or an existing term's meaning shifts. No ADR or migration required.
- **Orthogonal Flow A (Incident)** — PIRs are **system-lifetime**, not project-bound. They accumulate against the running system over its whole life; a project can close while PIRs continue.
- **Orthogonal Flow B (People & Recruiting)** — HR-adjacent docs. **None live in the repo.**
  - **Role Brief** — tech team's intake brief handed to HR / recruiting when opening a requisition. HR owns the public job posting (comp, benefits, EEO, application process); this brief is the upstream input.
  - **Brag Document** — personal artifact for performance reviews and promotion cycles.
  - **Performance Improvement Plan** — HR artifact for formal performance guidance.

## Lifecycle Ordering: RFC, ADR, Design Doc

RFCs, ADRs, and Design Docs look similar at a glance but capture different things. They are **not strictly linear** — each change picks the subset that fits — but the default order is:

**RFC → ADR → Design Doc** *(propose → decide → design how)*

| Artifact | Question it answers | State | Shape |
|----------|--------------------|-------|-------|
| **RFC** | *Should we do this?* | Open while under discussion; closes with a decision | Problem, alternatives, trade-offs, recommendation |
| **ADR** | *We chose X because Y.* | Immutable record of one decision | Context, decision, consequences — single-focus |
| **Design Doc** | *Here's how we will build it.* | Lives through implementation | Components, APIs, data flow, edge cases |

### How they compose

- One RFC can produce **multiple ADRs** — each discrete decision in the RFC's "Decision" section becomes its own ADR so the choice stays discoverable without reading the full proposal.
- One Design Doc can **reference multiple ADRs** — the DD describes the how; the ADRs explain why each constrained choice was made.
- ADRs can also emerge **during** Design Doc work — decisions surface as the design is fleshed out and get captured as they crystallize.

### When to use which subset

| Situation | Artifacts needed |
|-----------|------------------|
| Small change, clear decision | **ADR** only |
| Contested or speculative proposal, no complex build | **RFC → ADR** |
| Large feature, controversial approach | **RFC → ADR(s) → Design Doc** |
| Large feature, uncontested approach | **Design Doc** (ADRs extracted as decisions surface) |
| Emergent architectural choice made during implementation | **ADR** written after the fact |
| Exploratory or google-style design culture | **RFC → Design Doc → ADR(s) extracted from DD** |

### Anti-patterns

- **RFC that reads like a Design Doc.** If you already know how to build it and there's nothing to debate, skip the RFC.
- **ADR that reads like an RFC.** An ADR records a decision — it does not propose one. If alternatives are still open, you want an RFC.
- **Design Doc with no ADRs for load-bearing choices.** Key technology or architecture picks should be extractable — future readers shouldn't have to re-read the whole DD to find them.
- **Writing all three for a trivial change.** Overhead is real; pick the smallest artifact set that captures the decision.

## File Placement & Naming

Templates in this skill produce artifacts that live in a repository. The location, filename, and whether the name is dated or fixed all matter.

### Scope hierarchy

Documentation can live at three scopes:

| Scope | Location | Typical contents |
|-------|----------|------------------|
| **App** | `/docs/` | All document types |
| **Module** | `/Modules/{Module}/Docs/` | ADRs, RFCs, runbooks, test-cases scoped to a single module |
| **Component** | `/Modules/{Module}/{Component}/Docs/` | ADRs, RFCs, runbooks, test-cases scoped to a single component |

Choose the narrowest scope that still captures the right audience. Module-specific runbooks go under the module; app-wide ones go under `/docs/`. Full repo layout is defined in the wiki's `Conventions-Naming-Standards.md`.

### Where each document goes

| Template | Target directory | Filename | Notes |
|----------|------------------|----------|-------|
| architecture-decision-record | `/docs/adrs/` (or module/component `Docs/adrs/`) | `{yyyyMMddHHmm}-{slug}.md` | |
| request-for-comments | `/docs/rfcs/` (or module/component `Docs/rfcs/`) | `{yyyyMMddHHmm}-{slug}.md` | |
| design-doc | `/docs/designs/` | `{yyyyMMddHHmm}-{slug}.md` | |
| runbook | `/docs/runbooks/` (or module/component `Docs/runbooks/`) | `{slug}.md` | **No date prefix** — living document |
| standard-operating-procedure | `/docs/sops/` | `{yyyyMMddHHmm}-{slug}.md` | |
| post-incident-review | `/docs/pirs/` | `{yyyyMMddHHmm}-{slug}.md` | System-lifetime, incident-driven (not project-bound) |
| takeover-handover | `/docs/tickets/{TICKET-ID}/` | `Handoff.md` | Fixed name. Note spelling: **Handoff** (noun-form), not Handover (verb). Same template covers both directions — incoming Takeover and outgoing Handover. |
| data-dictionary | `/docs/` | `data-dictionary.md` | Fixed name, singleton |
| business-glossary | `/docs/` | `business-glossary.md` | Fixed name, singleton |
| tech-stack-overview | `/docs/` | `tech-stack-overview.md` | Fixed name, singleton |
| architecture-overview | `/docs/architectures/` (or module/component `Docs/architectures/`) | `{slug}.md` | **No date prefix** — living document. Multiple allowed per scope, each covering a system / module / component / area. Slug describes what it covers (e.g., `system.md`, `auth-flow.md`, `billing-pricing-engine.md`). |
| business-case | `/docs/projects/P{N}/` | `BusinessCase.md` | Fixed name |
| business-case-financial-model | `/docs/projects/P{N}/` | `BusinessCaseFinancialModel.md` | Fixed name |
| retrospective | `/docs/projects/P{N}/` | `Retrospective.md` | Fixed name |
| project-status-update | `/docs/projects/P{N}/StatusUpdates/` | `{yyyyMMddHHmm}-{slug}.md` | |
| test-plan *(project-scoped)* | `/docs/projects/P{N}/` | `TestPlan.md` | Fixed name. Sits alongside `BusinessCase.md`, `Retrospective.md` |
| test-plan *(app/release-scoped)* | `/docs/test-plans/` | `{yyyyMMddHHmm}-{slug}.md` | Use when scope is a release or initiative not tied to a `P{N}` project |
| test-cases | `/docs/test-cases/` (or module/component `Docs/test-cases/`) | `{slug}.md` | **No date prefix** — living document |
| brag-document | — | — | Personal artifact; lives outside the repo |
| performance-improvement-plan | — | — | HR artifact; lives outside the repo |
| role-brief | — | — | Lives outside the repo (HR-adjacent intake artifact, not engineering deliverable) |

### Identifier schemes

- **Tickets** use the external tracker identifier, e.g. `GITHUB-{N}` for GitHub issues. Adapt the prefix if another tracker is used.
- **Projects** use a sequential internal ID: `P1`, `P2`, `P3`, ...
- **Documents** use a timestamp-slug ID: `{ABBR}-{yyyyMMddHHmm}-{slug}` where `ABBR` is the document-type abbreviation (`ADR`, `RFC`, `PIR`, etc.), the timestamp follows .NET DateTime conventions (`yyyy`=year, `MM`=month, `dd`=day, `HH`=24-hour, `mm`=minute), and `slug` is the kebab-case title. The filename omits the abbreviation prefix (folder context supplies it) — file is `{yyyyMMddHHmm}-{slug}.md`, in-document references use the full `{ABBR}-{yyyyMMddHHmm}-{slug}` form.
- **ID placement inside a document:** the ID lives in the `## Metadata` block (e.g., `**ADR ID:** ADR-202603121430-adopt-event-sourcing-for-billing`), **not** in the `# H1 title`. The H1 is the human-readable title only — `# Architectural Decision Record: Adopt event sourcing for the billing module` — keeping the ID out of the title prevents repetition and keeps the heading scannable.

### Placeholder conventions inside templates

- **Dates:** `[YYYYMMDD]` — compact, no dashes (e.g., `[20260425]`).
- **Times:** `[HH:MM]` (24-hour).
- **Generic placeholders:** square brackets — `[Name]`, `[Project Name]`, `[Title]`.
- **Format-string placeholders** (where the *shape* of the value is the placeholder): bare literal — `yyyyMMddHHmm`, `slug`, `[N]`, `[X.Y]`. No curly braces.

### Metadata field conventions

Rules that govern the `## Metadata` block at the top of every template. The templates themselves are the source of truth for which fields each doc carries — the rules below prevent drift.

**Field order** (by scanning priority, not alphabetical):

1. Identity — Doc ID, or for project-scoped docs `Project ID` + `Project Name`, or for HR/personal docs the subject identity (`Role`, `Employee Name`)
2. Version (when carried — see rule below)
3. Last Updated / Modified (when present)
4. Date / Created (when first written; SOP uses `Effective Date` here)
5. Status (only when present as a metadata field, not a separate `## Status` section)
6. Domain-specific descriptive fields — Severity, Scope, Reporting Period, Duration, etc.
7. Person fields — Authors, Owner, Reviewers, Approver, Manager, From/To

**Naming rules:**

- **Author / Owner**: `Authors` / `Author` for who **wrote** a per-instance doc; `Owner` for who **maintains** a living doc. Domain labels (`Manager` for PIP, `From`/`To` for Handover, `Project Manager` for PSU) where intrinsic to the doc type.
- **Version is rare**. For most docs, Git history + the `Status` field already capture revision and lifecycle — a manually-bumped Version adds bookkeeping without value. Templates default to **no `Version:`**. Two exceptions:
  - **Regulated SOPs** (ISO 9001 / FDA QSR / GxP) — auditors require an explicit Version stamp independent of Last Reviewed; the SOP template flags this as a regulated-context override.
  - **Takeover & Handover** — sign-off ceremony where both parties literally agree on a specific revision; Version is part of the legal feel of the doc.
- **Last Updated** is used by docs that are continuously edited: living docs (Runbook, Test Cases, Tech Stack, Glossary, Data Dictionary, Architecture Overview), and continuously-revised per-instance docs (Test Plan, SOP — which uses `Last Reviewed`).
- **Date semantics**: `Date` = creation; `Last Updated` = most recent edit; `Effective Date` + `Last Reviewed` + `Next Review` for SOP; `Incident Date` (event) vs `Date` (when written) for PIR.

**Metadata is data, not links.** Pointers to other docs go **only** in `## References` — never as `**RFC:**` / `**Business Case:**` / `**References:**` field inside Metadata. One canonical location per fact.

### Supporting attachments

Any non-markdown supporting material for a document — diagrams (`.mermaid`, `.excalidraw`, `.puml`, `.png`), screenshots, spreadsheets, raw data, benchmark output, recordings — lives in a sibling `attachments/` folder next to the document, under a subfolder that matches the document's basename (without `.md`).

> The name `attachments/` is deliberately chosen over two tempting alternatives:
> - **`artifacts/`** — rejected because it collides with CI/CD vocabulary (GitHub Actions artifacts, Azure DevOps Artifacts, Maven/Gradle build artifacts, test artifacts).
> - **`assets/`** — rejected because in documentation-tooling (MkDocs, Docusaurus, Jekyll, Hugo) the term specifically means *web statics referenced by the rendered output* (images, CSS, JS, fonts). What we store here is broader: source files that produce images (`.mermaid`, `.excalidraw`, `.puml`), spreadsheets, raw data, benchmark JSON, recordings. These are supporting evidence attached to a document, not web assets of a rendered site.
>
> "Attachment" carries an unambiguous meaning — material attached to a specific document — and matches how people already think about supporting files in email, Jira, GitHub Issues, and Confluence.

**Pattern (dated docs):**

```
{doc-folder}/
├── {yyyyMMddHHmm}-{slug}.md
└── attachments/
    └── {yyyyMMddHHmm}-{slug}/
        ├── flow.puml
        ├── benchmark.json
        └── screenshot.png
```

**Examples:**

| Document | Attachments folder |
|----------|--------------------|
| `/docs/rfcs/202604240930-new-auth.md` | `/docs/rfcs/attachments/202604240930-new-auth/` |
| `/docs/adrs/202604240930-queue-choice.md` | `/docs/adrs/attachments/202604240930-queue-choice/` |
| `/docs/designs/202604241015-billing-flow.md` | `/docs/designs/attachments/202604241015-billing-flow/` |
| `/docs/sops/202604241030-oncall-rotation.md` | `/docs/sops/attachments/202604241030-oncall-rotation/` |
| `/docs/pirs/202604241100-outage.md` | `/docs/pirs/attachments/202604241100-outage/` |
| `/docs/runbooks/deploy-worker.md` *(living)* | `/docs/runbooks/attachments/deploy-worker/` |
| `/docs/test-cases/checkout-flow.md` *(living)* | `/docs/test-cases/attachments/checkout-flow/` |
| `/docs/test-plans/202604241200-q2-release.md` *(release-scoped)* | `/docs/test-plans/attachments/202604241200-q2-release/` |
| `/docs/tickets/GITHUB-42/Handoff.md` | `/docs/tickets/GITHUB-42/attachments/Handoff/` |
| `/docs/projects/P3/BusinessCase.md` | `/docs/projects/P3/attachments/BusinessCase/` |
| `/docs/projects/P3/BusinessCaseFinancialModel.md` | `/docs/projects/P3/attachments/BusinessCaseFinancialModel/` |
| `/docs/projects/P3/TestPlan.md` *(project-scoped)* | `/docs/projects/P3/attachments/TestPlan/` |
| `/docs/projects/P3/Retrospective.md` | `/docs/projects/P3/attachments/Retrospective/` |
| `/docs/projects/P3/StatusUpdates/202604241100-week18.md` | `/docs/projects/P3/StatusUpdates/attachments/202604241100-week18/` |
| `/Modules/Billing/Docs/rfcs/202604241200-refunds.md` | `/Modules/Billing/Docs/rfcs/attachments/202604241200-refunds/` |

**Rules:**
- Subfolder name matches the document basename exactly — same timestamp, same slug (or same fixed name for `Handoff`, `BusinessCase`, etc.).
- The rule is uniform: **every doc type uses its own `attachments/{basename}/` subfolder**, including handovers in `tickets/{TICKET-ID}/` and docs in `projects/P{N}/`. No container-as-bag exception — each doc owns its own attachments so the association stays explicit when a container holds multiple docs.
- Tickets and projects are always folders — `/docs/tickets/{TICKET-ID}/` and `/docs/projects/P{N}/` exist as directories regardless of how many docs they hold.
- Link from doc to attachment with a relative path: `![flow](./attachments/202604240930-new-auth/flow.mermaid)`. Mermaid source can also be inlined directly in the markdown via a ` ```mermaid ` code fence — reserve attachment storage for complex or reused diagrams.
- Create the subfolder only when there is material to put in it. Empty `attachments/` folders are clutter.
- **Singletons do not use this convention.** `data-dictionary.md`, `business-glossary.md`, and `tech-stack-overview.md` live at `/docs/` root and have no sibling `attachments/` folder — placing a generic `attachments/` at the docs root pollutes the top level and isn't scoped to any doc type. If a singleton genuinely needs supporting material, embed it inline or promote the doc into its own typed folder first.
- Commit only sharable supporting files. Personal scratch, raw recordings, or sensitive data belong elsewhere.

### Gotchas

- `takeover-handover.md` template renders to `Handoff.md` — different spelling (noun: the *handoff*). Same template used for both Takeover (incoming) and Handover (outgoing).
- Runbooks and test-cases are the only date-less entries in the dated group — filenames are `{slug}.md`, not `{yyyyMMddHHmm}-{slug}.md`. They are living documents updated as features change.
- `data-dictionary`, `business-glossary`, and `tech-stack-overview` are **singletons** at `/docs/` root — not in a subfolder, never dated, one per repo.
- `architecture-overview` is a **living slug-only doc** like Runbook — multiple allowed per scope, each describing a system / module / component / area. Filename is `{slug}.md` in `/docs/architectures/` (or module/component `Docs/architectures/`). Pick the narrowest scope that captures the right audience.
- Brag documents and PIPs are personal/HR artifacts. Do not commit them to the repository.

## Templates

Templates below are ordered by lifecycle phase, matching the Lifecycle Phases section above.

### Phase 2 — Justification & Approval

#### Business Case
**Template:** [templates/business-case.md](templates/business-case.md)

Use to secure support, funding, or prioritization. **Scales to project size:**
- **Light usage** *(Project Brief equivalent)*: Executive Summary, Reasons, Business Options, Timescale, Major Risks. Skip the financial sections. Use when approval gates on capacity/strategy, not budget.
- **Heavy usage**: Fill all sections including Costs, Dis-benefits, Investment Appraisal. Use for funding/capital allocation decisions.
- **With dedicated Financial Model**: Keep financial sections high-level here and produce `BusinessCaseFinancialModel.md` alongside.

---

#### Business Case Financial Model
**Template:** [templates/business-case-financial-model.md](templates/business-case-financial-model.md)

Use to evaluate financial impact.

---

### Phase 3 / 9 — Knowledge Transfer (in) / Closure

#### Takeover & Handover
**Template:** [templates/takeover-handover.md](templates/takeover-handover.md)

Single template covering both directions of ownership transfer:
- **Phase 3 (Takeover)** — receiving party fills it in when **inheriting** ownership of an existing system or project.
- **Phase 9 (Handover)** — outgoing party fills it in when **transferring out** ownership at project closure or role change.

---

### Phase 4 — Decide & Design

#### Request for Comments (RFC)
**Template:** [templates/request-for-comments.md](templates/request-for-comments.md)

Use before implementing big changes.

---

#### Architecture Decision Record (ADR)
**Template:** [templates/architecture-decision-record.md](templates/architecture-decision-record.md)

Use when making or changing architecture.

---

#### Design Doc (aka Tech Spec)
**Template:** [templates/design-doc.md](templates/design-doc.md)

Use before coding complex features.

---

### Phase 5 — Build Contract

#### Test Plan
**Template:** [templates/test-plan.md](templates/test-plan.md)

Use for cross-feature, release, or project-level test strategy.

**Created by:** Test Lead (or senior Tester)

**When to use:** opt-in, *not* per-feature.

- Multi-feature releases needing a coordinated test approach (shared environments, integration strategy, performance/load plans).
- Project-level work — sits in `/docs/projects/P{N}/TestPlan.md` next to `BusinessCase.md` and `Retrospective.md`.
- Regulated contexts (FDA, IEC 62304, ISO 13485, ISO 26262) where a Test Plan is a *required* deliverable.
- Non-functional test strategy (performance, security, accessibility, chaos) that doesn't fit cleanly under any single feature's Test Cases.

**Skip when:** feature-by-feature work where Planner's acceptance criteria + per-feature Test Cases + CI gates already capture the verification approach. Most agile change sets do not need a TP.

**Relationship to Test Cases:** A Test Plan *contains references to or implies* the set of Test Cases that fulfill it. One TP, many TCs. Do not duplicate scenario-level content between them — keep TC-level detail in the TC document; keep strategy / environment / schedule content in the TP.

---

#### Test Cases
**Template:** [templates/test-cases.md](templates/test-cases.md)

Use for QA verification of acceptance criteria.

**Created by:** Tester

**Timing:** Test Cases are **drafted before Developer starts** — they serve as the build contract, derived 1:1 from the Planner's acceptance criteria. Developer builds against them. After Developer passes Reviewer, the Tester implements the Test Cases as executable unit/integration tests. Both the Test Cases document and the executable tests are updated together during Reviewer FAIL iterations.

If a Test Plan exists for the release/project, ensure these Test Cases align with the TP's exit criteria, environment expectations, and overall approach.

Drafting Test Cases pre-implementation catches missing or ambiguous acceptance criteria while they are still cheap to fix and prevents the Tester from backfilling cases to match what was built (confirmation bias).

---

### Phase 7 — Operate

#### Runbook
**Template:** [templates/runbook.md](templates/runbook.md)

Use for handling systems and failures.

**Audience:** On-call engineers who may be unfamiliar with the service

**Clarity Checklist:**
- [ ] Symptom clearly described (what does the alert/issue look like?)
- [ ] Steps are numbered and specific
- [ ] Commands are copy-pasteable (no placeholders without explanation)
- [ ] Expected output shown for each command
- [ ] Escalation path defined (who to contact, when)
- [ ] Rollback steps included
- [ ] No jargon without explanation

**Shell Commands:** Use PowerShell syntax (`pwsh` code blocks). Do not use Unix-style commands like `grep`, `awk`, `sed`. Use PowerShell equivalents:

| Unix Command | PowerShell Equivalent |
|--------------|----------------------|
| `grep "pattern"` | `Select-String -Pattern "pattern"` |
| `grep -i "pattern"` | `Select-String -Pattern "pattern" -CaseSensitive:$false` |
| `grep -A5 "pattern"` | `Select-String -Pattern "pattern" -Context 0,5` |
| `grep -B5 "pattern"` | `Select-String -Pattern "pattern" -Context 5,0` |
| `grep "a\|b\|c"` | `Select-String -Pattern "a|b|c"` |
| `cat file.txt` | `Get-Content file.txt` |
| `head -n 10` | `Select-Object -First 10` |
| `tail -n 10` | `Select-Object -Last 10` |

---

#### Standard Operating Procedure (SOP)
**Template:** [templates/standard-operating-procedure.md](templates/standard-operating-procedure.md)

Use for repetitive tasks requiring compliance and consistency.

---

### Phase 8 — Report Progress

#### Project Status Update
**Template:** [templates/project-status-update.md](templates/project-status-update.md)

Use for regular reporting to stakeholders.

---

### Phase 9 — Closure

#### Retrospective
**Template:** [templates/retrospective.md](templates/retrospective.md)

Use at project end to capture outcomes and lessons.

(Takeover & Handover template, also used in Phase 9 for outgoing transfer, is documented above under Phase 3 / 9.)

---

### Phase 10 — Always-Living Reference

#### Tech Stack Overview
**Template:** [templates/tech-stack-overview.md](templates/tech-stack-overview.md)

Use to document current technologies.

---

#### Architecture Overview
**Template:** [templates/architecture-overview.md](templates/architecture-overview.md)

Use to explain how an existing system, module, component, or area works — the Diátaxis *Explanation* quadrant. Describes behavior and structure as they are today; defers the *why* to ADRs, *what tools* to Tech Stack Overview, and *fields* to Data Dictionary.

**Scope is flexible.** A repo can have many architecture overviews, each covering a different scope:
- `system.md` — the whole app
- `auth-flow.md` — a coherent sub-system within a module
- `billing-pricing-engine.md` — a specific area of complexity
- `Modules/Billing/Docs/architectures/refunds-pipeline.md` — module-scoped area

Pick the narrowest scope that captures a useful audience. Don't try to put everything in one doc.

**When to use:** any time someone with zero prior context needs to understand a system or sub-system without reading the code. Common triggers: onboarding new engineers, post-acquisition integration, regulator/auditor walkthroughs, vendor due diligence, replacing tribal knowledge with written reference.

**Distinct from Design Doc:** Design Doc is forward-looking (*how we will build it*). Architecture Overview is retrospective (*how it works today*). The same system may have a Design Doc when first built and an Architecture Overview that lives on as the system evolves.

---

#### Data Dictionary
**Template:** [templates/data-dictionary.md](templates/data-dictionary.md)

Use to document schema, fields, data types, and governance.

---

#### Business Glossary
**Template:** [templates/business-glossary.md](templates/business-glossary.md)

Use to define key business and technical terms.

---

### Orthogonal Flow A — Incident

#### Post Incident Review (aka Postmortem)
**Template:** [templates/post-incident-review.md](templates/post-incident-review.md)

Use after incidents.

---

### Orthogonal Flow B — People & Recruiting (not in repo)

HR-adjacent docs. **None of these live in the repo** — they are personal or HR artifacts. Templates are kept in this skill so they are available when needed, but the produced documents are stored outside the repo.

#### Role Brief
**Template:** [templates/role-brief.md](templates/role-brief.md)

Tech-team intake brief handed to HR / recruiting when opening a new requisition. Documents what the engineering team is looking for so HR can source candidates and produce the public job posting.

**Created by:** Engineering Manager or Tech Lead, with input from the team.

**Reviewed by:** Hiring Manager + HR Partner.

**Scope:** Document the role, not specific candidates. One brief per role; updated as the role definition evolves.

---

#### Brag Document
**Template:** [templates/brag-document.md](templates/brag-document.md)

Use before reviews or promotion cycles.

---

#### Performance Improvement Plan (PIP)
**Template:** [templates/performance-improvement-plan.md](templates/performance-improvement-plan.md)

Use when an employee's performance needs formal guidance.

---

## Role Responsibilities

### Documenter
- **Pre-implementation:** Creates RFC from Architect's technical design
- **Post-implementation:** Updates README, ADRs, runbooks, SOPs, Business Glossary, Tech Stack Overview, Business Case
- Selects appropriate template based on documentation need
- Ensures runbooks/SOPs are readable by unfamiliar engineers

### Architect
- Produces design doc using `templates/design-doc.md`
- Creates ADRs for significant architectural decisions
- Reviews RFCs and design docs from others

### DBA
- Creates/updates data dictionary for schema changes

### Developer
- Creates runbook drafts for new services/features
- Documents operational procedures

### Tester
- **Pre-implementation:** Drafts Test Cases from Planner's acceptance criteria — serves as the build contract for Developer
- **Post-implementation:** Implements Test Cases as executable unit/integration tests, iterates with Reviewer
- **During FAIL cycles:** Updates both the Test Cases document and the executable tests together
- **If a Test Plan exists for the release/project:** Ensures Test Cases align with the TP's scope, exit criteria, and test approach; updates the TP's Test Cases Index to link the new TC document

### Test Lead (when a Test Plan is invoked)
- Authors and owns the Test Plan at release / project / app scope
- Coordinates with Planner, Architect, and Tester(s) to define scope, environments, and exit criteria
- Maintains the Test Cases Index inside the TP
- Drives sign-off at exit-criteria milestones

### Planner
- Identifies documentation needs in the plan
