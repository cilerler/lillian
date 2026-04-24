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
  - data dictionary
  - performance improvement
  - test cases
references:
  - templates/architecture-decision-record.md
  - templates/request-for-comments.md
  - templates/design-doc.md
  - templates/runbook.md
  - templates/postmortem.md
  - templates/standard-operating-procedure.md
  - templates/handover.md
  - templates/data-dictionary.md
  - templates/business-glossary.md
  - templates/business-case.md
  - templates/business-case-financial-model.md
  - templates/brag-document.md
  - templates/performance-improvement-plan.md
  - templates/project-status-update.md
  - templates/retrospective.md
  - templates/tech-stack-overview.md
  - templates/test-cases.md
summary: Document templates for ADRs, RFCs, design docs, runbooks, postmortems, SOPs, handovers, business cases, test cases, and more.
---

# Documentation Skill

Provides standardized templates for all documentation types used in the repository.

## When to Use

| Document Type | When to Use | Created By | Reviewed By |
|---------------|-------------|------------|-------------|
| Business Case | To secure support, funding, or prioritization | PM, Product Lead, Architect | Leadership, Finance |
| Business Case Financial Model | To evaluate financial impact of a project | PM, Product Lead | Leadership, Finance |
| Business Glossary | To define key business terms | Product, Domain Experts | Product Owners |
| Data Dictionary | To define schema, fields, data types | Data Engineers, DBAs | Data Governance |
| Tech Stack Overview | To document current technologies | Engineer, Tech Lead | New team members |
| RFC | Proposed changes before implementing | Documenter | Peers, Architects |
| ADR | Architecture decisions | Architect, Documenter | Senior Devs |
| Design Doc | Before coding complex features | Engineer, Tech Lead | Dev Team, Product |
| Project Status Update | Regular reporting to stakeholders | Project Manager | Leadership |
| Retrospective | At project end, to capture outcomes and lessons | PM, Team Lead | Leadership, Team |
| Runbook | For handling systems & failures | Developer, SRE | Platform, On-call |
| SOP | For repetitive tasks, compliance | DevOps, SRE | Team Lead |
| Postmortem | After incidents | On-call Engineer | SRE Lead, Manager |
| Handover | When transferring ownership | Departing Engineer | Receiving Team |
| Brag Document | Before reviews or promo cycles | Individual | Manager |
| Performance Improvement Plan | When performance needs formal guidance | Manager, HR | HR, Department Head |
| Test Cases | For QA verification of acceptance criteria | Tester | Reviewer, QA |

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
| postmortem | `/docs/postmortems/` | `{yyyyMMddHHmm}-{slug}.md` | |
| handover | `/docs/tickets/{TICKET-ID}/` | `Handoff.md` | Fixed name. Note spelling: **Handoff**, not Handover. |
| data-dictionary | `/docs/` | `data-dictionary.md` | Fixed name, singleton |
| business-glossary | `/docs/` | `business-glossary.md` | Fixed name, singleton |
| tech-stack-overview | `/docs/` | `tech-stack-overview.md` | Fixed name, singleton |
| business-case | `/docs/projects/P{N}/` | `BusinessCase.md` | Fixed name |
| business-case-financial-model | `/docs/projects/P{N}/` | `BusinessCaseFinancialModel.md` | Fixed name |
| retrospective | `/docs/projects/P{N}/` | `Retrospective.md` | Fixed name |
| project-status-update | `/docs/projects/P{N}/StatusUpdates/` | `{yyyyMMddHHmm}-{slug}.md` | |
| test-cases | `/docs/test-cases/` (or module/component `Docs/test-cases/`) | `{slug}.md` | **No date prefix** — living document |
| brag-document | — | — | Personal artifact; lives outside the repo |
| performance-improvement-plan | — | — | HR artifact; lives outside the repo |

### Identifier schemes

- **Tickets** use the external tracker identifier, e.g. `GITHUB-{N}` for GitHub issues. Adapt the prefix if another tracker is used.
- **Projects** use a sequential internal ID: `P1`, `P2`, `P3`, ...

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
| `/docs/postmortems/202604241100-outage.md` | `/docs/postmortems/attachments/202604241100-outage/` |
| `/docs/runbooks/deploy-worker.md` *(living)* | `/docs/runbooks/attachments/deploy-worker/` |
| `/docs/test-cases/checkout-flow.md` *(living)* | `/docs/test-cases/attachments/checkout-flow/` |
| `/docs/tickets/GITHUB-42/Handoff.md` | `/docs/tickets/GITHUB-42/attachments/Handoff/` |
| `/docs/projects/P3/BusinessCase.md` | `/docs/projects/P3/attachments/BusinessCase/` |
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

- `handover.md` template renders to `Handoff.md` — different spelling (noun: the *handoff*).
- Runbooks and test-cases are the only date-less entries in the dated group — filenames are `{slug}.md`, not `{yyyyMMddHHmm}-{slug}.md`. They are living documents updated as features change.
- `data-dictionary`, `business-glossary`, and `tech-stack-overview` are **singletons** at `/docs/` root — not in a subfolder, never dated, one per repo.
- Brag documents and PIPs are personal/HR artifacts. Do not commit them to the repository.

## Templates

### Architecture Decision Record (ADR)
**Template:** [templates/architecture-decision-record.md](templates/architecture-decision-record.md)

Use when making or changing architecture. Documents:
- Context and assumptions
- Considered options with pros/cons
- Decision and consequences
- Risks and implementation details

**Status values:** Proposed → Accepted | Rejected | Superseded | Deprecated

---

### Request for Comments (RFC)
**Template:** [templates/request-for-comments.md](templates/request-for-comments.md)

Use before implementing big changes. Documents:
- Context and proposal
- Alternatives considered
- Open questions
- Timeline

**Status values:** Draft → In Review → Accepted | Rejected | Implemented | Withdrawn

---

### Tech Spec / Design Doc
**Template:** [templates/design-doc.md](templates/design-doc.md)

Use before coding complex features. Documents:
- Context, scope, goals, non-goals
- Overview and detailed design
- Cross-cutting concerns (security, privacy)
- Alternatives considered
- Metrics and timeline

**Status values:** Draft → Final → Implemented → Obsolete

---

### Runbook
**Template:** [templates/runbook.md](templates/runbook.md)

Use for handling systems and failures. Documents:
- Purpose and prerequisites
- Step-by-step procedures
- Rollback plan
- Contact information

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

### Post Incident Review (Postmortem)
**Template:** [templates/postmortem.md](templates/postmortem.md)

Use after incidents. Documents:
- Summary and timeline
- Impact and root cause
- What went well/wrong
- Corrective and preventative measures
- Action items with owners and due dates

**Status values:** Draft → In Review → Approved → Completed → Closed

---

### Standard Operating Procedure (SOP)
**Template:** [templates/standard-operating-procedure.md](templates/standard-operating-procedure.md)

Use for repetitive tasks requiring compliance and consistency. Documents:
- Purpose and frequency
- Roles responsible
- Prerequisites
- Step-by-step procedure
- Rollback procedure

---

### Technical Handover
**Template:** [templates/handover.md](templates/handover.md)

Use when transferring ownership or onboarding new engineers. Documents:
- Executive summary and contacts
- Getting started guide
- System architecture
- CI/CD and deployment
- Operations and observability
- Security and data management
- Quality and testing

---

### Data Dictionary
**Template:** [templates/data-dictionary.md](templates/data-dictionary.md)

Use to document schema, fields, data types, and governance. Includes:
- Schema and field names
- Data types and constraints
- PK/FK relationships
- PII/Security classification

---

### Business Glossary
**Template:** [templates/business-glossary.md](templates/business-glossary.md)

Use to define key business and technical terms. Includes:
- Term definitions
- Business rules and calculations
- Examples
- Related terms and owners

---

### Business Case
**Template:** [templates/business-case.md](templates/business-case.md)

Use to secure support, funding, or prioritization. Documents:
- Executive summary
- Reasons and business options
- Expected benefits and dis-benefits
- Costs and timescale
- Major risks and investment appraisal

---

### Business Case Financial Model
**Template:** [templates/business-case-financial-model.md](templates/business-case-financial-model.md)

Use to evaluate financial impact. Documents:
- Revenue vs costs (OPEX, CAPEX, one-time)
- Hard returns vs soft returns
- 3-year cumulative costs
- ROI and payback period

---

### Brag Document
**Template:** [templates/brag-document.md](templates/brag-document.md)

Use before reviews or promotion cycles. Documents:
- Goals and projects
- Contributions, scope, and impact
- Collaboration and mentorship
- Design and documentation work
- Skills learned

---

### Performance Improvement Plan (PIP)
**Template:** [templates/performance-improvement-plan.md](templates/performance-improvement-plan.md)

Use when an employee's performance needs formal guidance. Documents:
- Specific performance issues
- Expected standards
- Action plan with timeline
- Support and resources
- Consequences

---

### Project Status Update
**Template:** [templates/project-status-update.md](templates/project-status-update.md)

Use for regular reporting to stakeholders. Documents:
- Overall status (RAG)
- Key accomplishments and planned activities
- Risks, issues, and dependencies (RAID)
- Milestone tracker
- Budget and resource update

---

### Retrospective
**Template:** [templates/retrospective.md](templates/retrospective.md)

Use at project end to capture outcomes and lessons. Documents:
- Project information and summary
- Original goals vs actual outcomes
- Timeline highlights
- What went well / didn't go well
- Root causes and lessons learned
- Action items for future projects
- Metrics (budget, duration, scope delivered)

**Status values:** Draft → In Review → Final → Archived

---

### Tech Stack Overview
**Template:** [templates/tech-stack-overview.md](templates/tech-stack-overview.md)

Use to document current technologies. Documents:
- Source control and CI/CD
- Runtime and infrastructure
- Frameworks and libraries
- Testing and observability
- Storage and integrations

---

### Test Cases
**Template:** [templates/test-cases.md](templates/test-cases.md)

Use for QA verification of acceptance criteria. Documents:
- Acceptance criteria coverage mapping (1:1)
- Step-by-step test procedures
- Expected results
- Edge cases and error paths
- Test execution summary

**Created by:** Tester

**Timing:** Test Cases are **drafted before Developer starts** — they serve as the build contract, derived 1:1 from the Planner's acceptance criteria. Developer builds against them. After Developer passes Reviewer, the Tester implements the Test Cases as executable unit/integration tests. Both the Test Cases document and the executable tests are updated together during Reviewer FAIL iterations.

Drafting Test Cases pre-implementation catches missing or ambiguous acceptance criteria while they are still cheap to fix and prevents the Tester from backfilling cases to match what was built (confirmation bias).

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

### Planner
- Identifies documentation needs in the plan
