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
  - SOP
  - business case
  - brag document
  - project status
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
| Runbook | For handling systems & failures | Developer, SRE | Platform, On-call |
| SOP | For repetitive tasks, compliance | DevOps, SRE | Team Lead |
| Postmortem | After incidents | On-call Engineer | SRE Lead, Manager |
| Handover | When transferring ownership | Departing Engineer | Receiving Team |
| Brag Document | Before reviews or promo cycles | Individual | Manager |
| Performance Improvement Plan | When performance needs formal guidance | Manager, HR | HR, Department Head |
| Test Cases | For QA verification of acceptance criteria | Tester | Reviewer, QA |

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
- Acceptance criteria coverage mapping
- Step-by-step test procedures
- Expected results
- Edge cases and error paths
- Test execution summary

**Created by:** Tester (updated during review iterations)

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
- Creates test cases for QA verification
- Updates test cases during review iterations

### Planner
- Identifies documentation needs in the plan
