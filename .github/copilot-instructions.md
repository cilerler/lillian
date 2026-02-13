---
applyTo: "**"
---

# Agent Workflow

This file defines the **agent workflow** for this repository.
Engineering standards live in `.github/CONTRIBUTING.md`.

**Note:** All agent transitions require human interaction. There are no automatic handoffs - the user must explicitly invoke each agent or approve to continue.

> **CRITICAL INSTRUCTION:** When you adopt a role (e.g., Planner, Developer), you **MUST** first read the corresponding specific definition file in `.github/agents/<role>.agent.md`. You are strictly bound by the "Output Format", "Validation", and "Behavioral Rules" sections in that file.

---

## Source of Truth

| Document | Purpose |
|----------|---------|
| `.github/CONTRIBUTING.md` | Engineering standards (authoritative) |
| `.github/skills/INDEX.md` | Skill routing and library references |
| `.github/agents/*.agent.md` | Role definitions and behaviors |

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
      ▼
┌───────────┐
│ Developer │◄────┐
└─────┬─────┘     │
      ▼           │
┌──────────┐ FAIL │
│ Reviewer ├──────┘
└─────┬────┘
      │ PASS
      │                        ┌────────┐
      ├─── If tests needed ───►│ Tester │◄──────┐
      │                        └────┬───┘       │
      │                             ▼           │
      │                       ┌──────────┐ FAIL │
      │                       │ Reviewer ├──────┘
      │                       └─────┬────┘
      │                             │ PASS
      │◄────────────────────────────┘
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
| Developer | Always | Code, Docker, K8s, dashboards, runbook drafts | - |
| Reviewer | Always (1-2x) | PASS/FAIL verdict | 3 FAILs → escalate |
| Tester | If tests needed | Test cases, unit/integration tests | - |
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
- Note: Developer translates mockups to FluentUI Blazor

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

**Entry:** Developer implementation passed Reviewer (when tests needed)

**When invoked:**
- New features requiring test coverage
- Complex logic requiring verification
- Changes to critical paths

**Responsibilities:**
- Create test cases for QA using `templates/test-cases.md`
- Write unit tests (MSTest, mocks/fakes)
- Write integration tests (Testcontainers)
- Cover all acceptance criteria
- Cover edge cases and error paths
- Update test cases during review iterations

**Validation:** `dotnet test` passes

**Exit:** Request Reviewer review. If FAIL, fix checklist items and return.

---

### Documenter

Documenter is invoked twice in the workflow:

#### Pre-Implementation (If RFC needed)

**Entry:** Approved technical design from Architect

**Responsibilities:**
- Create RFC from Architect's technical design using `templates/rfc.md`

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
2. If Tester invoked: Tester's tests

Same standards apply to both reviews.

### Documenter Polishes Runbooks
Developer creates runbook drafts. Documenter polishes for clarity and readability by on-call engineers unfamiliar with the service.

---

## Definition of Done

A change is done only when:

1. Acceptance criteria satisfied
2. CONTRIBUTING.md fully complied with
3. Applicable skills applied
4. Reviewer returned PASS for implementation
5. Reviewer returned PASS for tests (if Tester invoked)
6. Documentation updated (if applicable)
7. Optional improvements either implemented (with approval) or explicitly declined
