---
name: work-item-generator
type: guidance
applies_to:
  - Planner
  - Developer
  - Architect
mandatory: conditional
triggers:
  - work item
  - initiative
  - epic
  - feature
  - story
  - bug
  - spike
  - enhancement
  - task
  - create issue
  - create ticket
  - file a bug
  - log a bug
  - report a bug
references:
  - templates/initiative.md
  - templates/epic.md
  - templates/feature.md
  - templates/story.md
  - templates/bug.md
  - templates/spike.md
  - templates/enhancement.md
  - templates/task.md
summary: Interactive generator for work items (initiatives, epics, features, stories, bugs, spikes, enhancements, tasks) that gathers context through targeted questions and produces structured documents.
---

# Work Item Generator

Generates structured work item documents by gathering context through targeted questions and producing output from the appropriate template.

## Work Item Hierarchy

Work items are organized into two tiers. Product-side items define *what* to build. Developer-side items define *how* to build it. Tasks break developer items into concrete steps.

```
Product Side                    Developer Side
─────────────                   ──────────────
🎯 Initiative                   💡 Story ──────┐
  └─ 🚀 Epic                   🪲 Bug ────────┼─ ✔️ Task(s)
       └─ 🎁 Feature           🔬 Spike ──────┤
                                🛠️ Enhancement ┘
```

## Work Item Types

| Type | Emoji | Tier | Purpose |
|------|-------|------|---------|
| Initiative | 🎯 | Product | A high-level strategic goal or large-scale project |
| Epic | 🚀 | Product | A large body of work for a major product component |
| Feature | 🎁 | Product | A distinct, shippable product capability or service |
| Story | 💡 | Developer | A request, idea, or new functionality |
| Bug | 🪲 | Developer | An unexpected problem or behavior |
| Spike | 🔬 | Developer | A time-boxed research task to reduce uncertainty |
| Enhancement | 🛠️ | Developer | An improvement to refactoring or technical debt |
| Task | ✔️ | Developer | A specific piece of work (child of Story, Bug, Spike, or Enhancement) |

## Shared Classification Fields

These fields appear on templates depending on the tier. Product-side items carry Value Area, Value Ranking, and Priority. Developer-side items (Story, Bug, Spike, Enhancement) carry all five. Tasks carry only Effort.

### Impact (developer-side only, single value)

The primary dimension this work affects. Each item has exactly one Impact.

| Impact | Emoji | Description |
|--------|-------|-------------|
| Data | 🗃️ | Data integrity, accuracy, models |
| Functionality | 🧬 | New capabilities or bug fixes |
| User Experience | 🖱️ | Usability, workflow, intuitive interactions |
| Performance & Stability | ⚖️ | Speed, reliability, system health |
| User Interface | 🎨 | Visual styling, layout, aesthetics |

### Value Area

| Value Area | Emoji | Description |
|------------|-------|-------------|
| Architecture | 👷 | Internal value to the system or development team |
| Business | 🧑‍💼 | Direct value to end-users or customers |

### Value Ranking

| Ranking | Emoji | Weight | Description |
|---------|-------|--------|-------------|
| Platinum | 🪨 | 1 | Critical, high-impact, primary business goal |
| Gold | 🥇 | 2 | Significant ROI or customer value |
| Silver | 🥈 | 3 | Clear, moderate value improvements |
| Bronze | 🥉 | 4 | Nice-to-have, minor fixes |

### Priority

| Priority | Emoji | Weight | Description |
|----------|-------|--------|-------------|
| Urgent | 🔴 | 1 | Production down or work blocked |
| High | 🟡 | 2 | Critical, primary team focus |
| Medium | 🟢 | 3 | Necessary, near-future value |
| Low | 🔵 | 4 | Non-critical, time-permitting work |

### Effort (developer-side only)

Story points using the Fibonacci sequence: **1, 2, 3, 5, 8, 13, 21**

Effort is estimated at the developer-item and task level. Product-side items derive their effort from the sum of their children.

### Links

Standard relationship types between work items:

| Relationship | Inverse |
|-------------|---------|
| blocks | is blocked by |
| duplicates | is duplicated by |

## Workflow

### Step 1: Determine the Type

If the user hasn't specified a type, ask them to pick one.

If the type is implied by their message (e.g. "something is broken" implies Bug, "we should investigate" implies Spike), confirm the inferred type before proceeding.

### Step 2: Gather Missing Information

Each type has required and optional fields. Parse what the user has already provided, then ask only for what's missing. Group related questions together and ask in a single prompt rather than one at a time. Mark which questions are optional so the user can skip them.

The required fields per type are listed below. Read the corresponding template for the full structure.

#### Initiative (🎯)
**Required:** Title, Vision/Strategic Goal, Business Objectives
**Ask if missing:** Value Area, Value Ranking, Priority, Success Metrics, Scope, Timeline, Stakeholders, Links

#### Epic (🚀)
**Required:** Title, Description, Business Value
**Ask if missing:** Value Area, Value Ranking, Priority, Acceptance Criteria, Success Metrics, Target Timeline, Child Features, Links

#### Feature (🎁)
**Required:** Title, Description, User/Customer Value, Acceptance Criteria
**Ask if missing:** Value Area, Value Ranking, Priority, Dependencies, Design Considerations, Out of Scope, Links

#### Story (💡)
**Required:** Title, User Story statement (As a ... I want ... so that ...), Acceptance Criteria
**Ask if missing:** Impact, Value Area, Value Ranking, Priority, Effort, Definition of Done, Notes/Context, Links

#### Bug (🪲)
**Required:** Title, Expected Behavior, Actual Behavior, Steps to Reproduce
**Ask if missing:** Impact, Value Area, Value Ranking, Priority, Effort, Environment, Frequency, Screenshots/Logs, Workaround, Links

#### Spike (🔬)
**Required:** Title, Question/Hypothesis, Timebox
**Ask if missing:** Impact, Value Area, Value Ranking, Priority, Effort, Context/Background, Expected Output, Success Criteria, Links

#### Enhancement (🛠️)
**Required:** Title, Current State, Proposed Improvement, Justification
**Ask if missing:** Impact, Value Area, Value Ranking, Priority, Effort, Affected Areas, Risks, Migration Plan, Links

#### Task (✔️)
**Required:** Title, Description, Acceptance Criteria
**Ask if missing:** Effort, Links

### Step 3: Generate the Document

Once you have the required information:

1. Read the corresponding template from `templates/`
2. Fill in all provided fields
3. Leave optional sections with placeholder markers for the user to fill later
4. Present the completed document to the user

## Guidelines

- **Be conversational.** Ask questions naturally, not like a form. If the user gives a paragraph explaining a bug, extract the relevant parts rather than asking them to repeat themselves in a structured format.
- **Infer where possible.** If the user says "the button doesn't work on mobile Safari," you already have environment info (mobile Safari) and partial reproduction context. Don't re-ask for things they've already told you.
- **Suggest Impact.** If the user doesn't specify Impact, suggest one based on context. A bug about data corruption is clearly 🗃️ Data. A request for a new API endpoint is 🧬 Functionality. A complaint about slow load times is ⚖️ Performance & Stability.
- **Keep it lean.** Don't pad the output with boilerplate the user will just delete. If a section has no content, omit it rather than leaving "N/A" everywhere.
