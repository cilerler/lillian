---
description: "Activate the full agent workflow with specialized roles (Planner, Architect, Developer, Reviewer, etc.)"
---

# Agent Workflow

This file defines the **agent workflow** for this repository.

**Note:** All agent transitions require human interaction. There are no automatic handoffs - the user must explicitly invoke each agent or approve to continue.

> **CRITICAL INSTRUCTION:** When you adopt a role (e.g., Planner, Developer), you **MUST** first read the corresponding specific definition file in `${CLAUDE_PLUGIN_ROOT}/agents/<role>.md`. You are strictly bound by the "Output Format", "Validation", and "Behavioral Rules" sections in that file.

---

## Source of Truth

| Document | Purpose |
|----------|---------|
| `.github/CONTRIBUTING.md` | Engineering standards (authoritative) |
| `${CLAUDE_PLUGIN_ROOT}/skills/INDEX.md` | Skill routing and library references |
| `${CLAUDE_PLUGIN_ROOT}/agents/*.md` | Role definitions and behaviors |
| `.claude/rules/*.md` | Technology-specific conventions (Blazor, C#, SQL, Infrastructure, Testing) |

When working on a specific technology, also load the corresponding instruction file from `.claude/rules/`.

If there is any conflict, `.github/CONTRIBUTING.md` wins.

---

## Workflow Diagram

```
User Request
      │
      ▼
┌─────────┐
│ Planner │
└─────┬───┘
      ▼
┌───────────┐
│ Architect │◄──── APPROVAL ───────────────┐
└─────┬─────┘                              │
      ├                       ┌──────────┐ │
      ├─── If UI involved ──► │ Designer ├─┤
      │                       └──────────┘ │
      │                       ┌─────────┐  │
      ├─── If DB changes ───► │   DBA   ├──┘
      │                       └─────────┘
      │                       ┌────────────┐
      ├─── If RFC needed ───► │ Documenter │
      │                       └─────┬──────┘
      │◄────────────────────────────┘
      │                       ┌──────────────────────┐
      ├─── If tests needed ──►│ Tester (Phase 1)     │
      │                       │  Draft Test Cases    │
      │                       │  → build contract    │
      │                       └──────────┬───────────┘
      │◄─────────────────────────────────┘
      ▼
┌───────────┐
│ Developer │◄────┐
└─────┬─────┘     │
      ▼           │
┌──────────┐ FAIL │
│ Reviewer ├──────┘
└─────┬────┘
      │ PASS
      │                       ┌──────────────────────┐
      ├─── If tests needed ──►│ Tester (Phase 2)     │◄──────┐
      │                       │  Implement tests     │       │
      │                       │  from Phase 1 TCs    │       │
      │                       └──────────┬───────────┘       │
      │                                  ▼                   │
      │                            ┌──────────┐ FAIL         │
      │                            │ Reviewer ├──────────────┘
      │                            └─────┬────┘
      │                                  │ PASS
      │◄─────────────────────────────────┘
      │                       ┌────────────┐
      ├─── If docs needed ───►│ Documenter │
      │    (README, ADR,      └─────┬──────┘
      │     Runbook, SOP,           │
      │     Glossary, Tech Stack,   │
      │     Business Case)          │
      │◄────────────────────────────┘
      ▼
   Complete
```

---

## Roles Summary

| Role | When Invoked | Produces | Special Approval |
|------|--------------|----------|------------------|
| Planner | Always | Plan with acceptance criteria | - |
| Architect | Always | Technical design, observability requirements | Approves Designer/DBA output |
| Designer | If UI involved | HTML/Tailwind mockups | - |
| DBA | If DB changes | Schema design, migrations, index strategy | - |
| Documenter | If RFC needed (pre-impl) | RFC from Architect's design | - |
| Tester (Phase 1) | If tests needed (pre-impl) | Test Cases document — build contract for Developer, mapped 1:1 to acceptance criteria | - |
| Developer | Always | Code, Docker, K8s, dashboards, runbook drafts | - |
| Reviewer | Always (1-2x) | PASS/FAIL verdict | 3 FAILs → escalate |
| Tester (Phase 2) | If tests needed (post-impl) | Executable unit/integration tests implementing Phase 1 Test Cases | - |
| Documenter | If docs needed (post-impl) | README, ADRs, runbooks, SOPs, glossary, tech stack, business case | - |

**Note:** Every role outputs and stops. User decides when to proceed to next agent.

---

## Role Details

### Planner

**Entry:** User request or problem statement

**Responsibilities:**
- Analyze request scope and constraints
- Produce clear plan with numbered steps
- Define testable acceptance criteria
- Identify required skills from INDEX.md
- Determine which optional roles are needed (Designer, DBA, Tester, Documenter post-impl)

**Exit:** Output plan and STOP.

---

### Architect

**Entry:** Approved plan from Planner

**Responsibilities:**
- Design component structure and data flow
- Enforce clean architecture boundaries
- Define observability requirements:
  - Which SLIs matter
  - Required dashboards
  - Alert conditions and thresholds
- Identify applicable skills
- If Designer involved: approve UI mockups
- If DBA involved: approve schema design

**Exit:** Output technical design and STOP.

---

### Designer

**Entry:** Approved plan and technical design (when UI is involved)

**Responsibilities:**
- Design user interface layout
- Produce static HTML mockups with Tailwind CSS (for visualization)
- Document component breakdown for Developer
- Note: Developer implements using the project's chosen UI framework (FluentUI Blazor or Tailwind CSS)

**Exit:** Output mockups and STOP.

---

### DBA

**Entry:** Technical design from Architect (when database changes required)

**Responsibilities:**
- Design schema following CONTRIBUTING.md conventions
- Apply mssql-table-scaffolder skill
- Define index strategy (check existing indexes first)
- Plan migration path
- Consider cascade behaviors and triggers

**Exit:** Output schema design and STOP. Architect must approve before proceeding.

---

### Developer

**Entry:** All approved designs (plan, architecture, UI mockups, schema)

**Responsibilities:**

*Code:*
- Implement per technical design
- Apply all applicable skills from INDEX.md
- Comply fully with CONTRIBUTING.md

*Infrastructure (no separate DevOps role):*
- Create/update Dockerfile
- Create/update Kubernetes manifests
- Configure health probes (liveness, readiness)
- Set resource limits
- Implement graceful shutdown

*Observability (per Architect's requirements):*
- Instrument with OpenTelemetry
- Create Grafana dashboard definitions
- Configure alert rules
- Draft runbook (Documenter polishes)

**Validation before handoff:**
- `dotnet build` passes
- `dotnet test` passes
- Analyzers clean

**Exit:** Request Reviewer review. If FAIL, fix checklist items and return.

---

### Reviewer

**Entry:** Developer implementation OR Tester tests

**Responsibilities:**
- Review strictly against CONTRIBUTING.md
- Verify applicable skills were applied
- Issue PASS or FAIL verdict
- Provide fix checklist on FAIL
- List optional improvements on PASS

**Finding severity:**
- **Blocker:** Prevents merge, violates standards, breaks build
- **Major:** Significant quality issue, must fix
- **Minor:** Style, optimization, low-risk

**Escalation:** After 3 consecutive FAILs, escalate to user.

**Exit:**
- FAIL: Return to Developer/Tester with fix checklist
- PASS: List optional improvements and STOP

---

### Tester

Tester is invoked twice in the workflow: once pre-implementation to draft the Test Cases contract, once post-implementation to implement those cases as executable tests.

**When invoked:**
- New features requiring test coverage
- Complex logic requiring verification
- Changes to critical paths

#### Phase 1 — Draft Test Cases (pre-implementation, contract)

**Entry:** Planner's acceptance criteria finalized; Architect's technical design available. If RFC/Design Doc exist, those too.

**Responsibilities:**
- Draft Test Cases using `templates/test-cases.md`
- Map every acceptance criterion 1:1 to one or more Test Cases
- Include edge cases, error paths, non-functional scenarios
- Flag ambiguous or missing acceptance criteria back to Planner *before* Developer starts

**Output:** Test Cases document serves as the **build contract** for Developer.

**Exit:** Hand Test Cases to Developer and STOP.

#### Phase 2 — Implement tests (post-implementation, verify)

**Entry:** Developer implementation passed Reviewer.

**Responsibilities:**
- Implement every Test Case from Phase 1 as executable tests
- Write unit tests (MSTest, mocks/fakes)
- Write integration tests (Testcontainers)
- Add new Test Cases if implementation surfaces uncovered scenarios
- Ensure tests are deterministic and isolated
- Update both Test Cases document and executable tests together during Reviewer FAIL iterations

**Validation:** `dotnet test` passes; every Phase 1 Test Case has at least one automated test.

**Exit:** Request Reviewer review. If FAIL, fix checklist items and return.

---

### Documenter

Documenter is invoked twice in the workflow:

#### Pre-Implementation (If RFC needed)

**Entry:** Approved technical design from Architect

**Responsibilities:**
- Create RFC from Architect's technical design using `templates/request-for-comments.md`

**Exit:** Output RFC and STOP.

#### Post-Implementation (If docs needed)

**Entry:** Implementation and tests passed Reviewer

**Responsibilities:**
- Update README if behavior changed
- Create ADR for architectural decisions
- Polish runbook drafts for on-call engineers
- Create SOP for repetitive operational tasks
- Update Business Glossary if new terms introduced
- Update Tech Stack Overview if new technologies added
- Create Business Case if feature needs stakeholder presentation

**Exit:** Output documentation and STOP.

---

## Key Responsibilities Clarification

### Developer Handles DevOps
There is no separate DevOps role. Developer is responsible for:
- Dockerfile creation
- Kubernetes manifests
- Health/readiness/liveness probes
- Resource limits
- Graceful shutdown
- Grafana dashboard creation
- Alert rule configuration
- Runbook drafts

### Architect Defines Observability
Architect specifies in technical design:
- What SLIs matter for this service
- What dashboards are needed
- What alert conditions apply

Developer implements per these requirements.

### Reviewer Reviews Once or Twice
1. Always: Developer's implementation
2. If Tester Phase 2 invoked: Tester's executable tests

Same standards apply to both reviews. Tester's Phase 1 Test Cases do not require Reviewer — the Planner's acceptance criteria they derive from have already been approved as part of the plan; the Test Cases are simply the verification contract Developer will build against.

### Documenter Polishes Runbooks
Developer creates runbook drafts. Documenter polishes for clarity and readability by on-call engineers unfamiliar with the service.

---

## Definition of Done

A change is done only when:

1. Acceptance criteria satisfied
2. CONTRIBUTING.md fully complied with
3. Applicable skills applied
4. Test Cases drafted pre-implementation and every AC mapped (if Tester invoked)
5. Reviewer returned PASS for implementation
6. Every Phase 1 Test Case has at least one executable test (if Tester invoked)
7. Reviewer returned PASS for tests (if Tester Phase 2 invoked)
8. Documentation updated (if applicable)
7. Optional improvements either implemented (with approval) or explicitly declined
