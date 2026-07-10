---
name: work-item-generator
description: Interactive generator for work items (initiatives, epics, features, stories, bugs, spikes, enhancements, tasks) that gathers context through targeted questions and produces structured documents. Use when creating work items or filing issues, tickets, or bug reports.
type: guidance
applies_to:
  - Planner
  - Developer
  - Architect
mandatory: conditional
mandatory_when:
  - Creating work items (initiatives, epics, features, stories, bugs, spikes, enhancements, tasks)
  - Filing bugs or logging issues
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

Work items are organized into two tiers. Product-side items define *what* to build. Developer-side items define *how* to build it. A Feature is the parent of Stories, Bugs, Spikes, and Enhancements — that link connects the two tiers. Tasks break developer items into concrete steps.

```
🎯 Initiative
  └─ 🚀 Epic
       └─ 🎁 Feature
            ├─ 💡 Story ──────┐
            ├─ 🪲 Bug ────────┼─ ✔️ Task(s)
            ├─ 🔬 Spike ──────┤
            └─ 🛠️ Enhancement ┘
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
| Enhancement | 🛠️ | Developer | An improvement to refactoring or technical debt reduction |
| Task | ✔️ | Developer | A specific piece of work (child of Story, Bug, Spike, or Enhancement) |

## Classification Fields

All classification fields are **optional**. Offer them when relevant, but accept whatever the user provides. If a field is not provided, **omit it entirely** from the generated output — no empty placeholders, no "N/A" rows.

The creator may be a non-technical user documenting a need, or a developer in a rush capturing a situation. Classification is typically refined later during backlog refinement, not at creation time.

### Area Path

A hierarchical label indicating which part of the product or codebase this item belongs to (e.g., `Backend/Auth`, `Frontend/Dashboard`). Applicable to all types.

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

Formula: `MapToClosestFibonacci(Hours × Complexity × Risk)` — estimate the raw hours, multiply by the two factors below, then snap to the nearest Fibonacci value.

| Factor | Scale |
|--------|-------|
| Complexity | 1.0 = routine work · 1.5 = unfamiliar territory or many moving parts · 2.0 = novel problem or algorithmically hard |
| Risk | 1.0 = isolated change · 1.5 = touches shared code or data · 2.0 = critical path, data migration, or hard to reverse |

Effort is estimated at the developer-item and task level. Product-side items derive their effort from the sum of their children.

### Links

Standard relationship types between work items:

| Relationship | Inverse |
|-------------|---------|
| is parent of | is child of |
| blocks | is blocked by |
| duplicates | is duplicated by |

Parent-child links form the hierarchy shown above (Initiative → Epic → Feature → Story/Bug/Spike/Enhancement → Task) and are the links the Effort children-sum rule rolls up through.

## Workflow

### Step 1: Determine the Type

If the user hasn't specified a type, ask them to pick one.

If the type is implied by their message (e.g. "something is broken" implies Bug, "we should investigate" implies Spike), confirm the inferred type before proceeding.

**Gentle steering:** If the description sounds like a different type than what the user picked, gently suggest the better fit. For example:
- A "bug" that describes how something *could* work better (but isn't broken) is likely an **Enhancement**.
- A request for a "new feature" that is really about refactoring internal code is likely an **Enhancement** (see [Enhancement vs. Bug](#enhancement-vs-bug) below).
- A "story" with no clear user benefit might be a **Task** or **Spike**.

Accept the user's choice if they insist — the goal is to guide, not gate-keep.

### Step 2: Gather Content

Each type has content fields that describe the work itself. Parse what the user has already provided, then ask only for what's missing. Group related questions together and ask in a single prompt rather than one at a time.

Classification fields (Area Path, Impact, Value Area, Value Ranking, Priority, Effort) are **never required at creation time**. If the user provides them, include them. If not, omit them silently. You may offer to help fill them in if the conversation feels unhurried, but never block on them.

The content fields per type are listed below. Read the corresponding template for the full structure.

#### Initiative (🎯)
**Gather:** Title, Vision/Strategic Goal, Business Objectives
**Offer if relevant:** Success Metrics, Scope, Timeline, Stakeholders, Links

#### Epic (🚀)
**Gather:** Title, Description, Business Value
**Offer if relevant:** Acceptance Criteria, Success Metrics, Target Timeline, Child Features, Links

#### Feature (🎁)
**Gather:** Title, Description, User/Customer Value, Acceptance Criteria
**Offer if relevant:** Dependencies, Design Considerations, Out of Scope, Links

#### Story (💡)
**Gather:** Title, User Story statement (As a ... I want ... so that ...), Acceptance Criteria
**Offer if relevant:** Definition of Done, Notes/Context, Links

#### Bug (🪲)
**Gather:** Title, Expected Behavior, Actual Behavior, Steps to Reproduce
**Offer if relevant:** Environment, Frequency, Screenshots/Logs, Workaround, Links

#### Spike (🔬)
**Gather:** Title, Question/Hypothesis, Timebox
**Offer if relevant:** Context/Background, Expected Output, Success Criteria, Links

#### Enhancement (🛠️)
**Gather:** Title, Current State, Proposed Improvement, Justification
**Offer if relevant:** Affected Areas, Risks, Migration Plan, Links

#### Task (✔️)
**Gather:** Title, Description, Acceptance Criteria
**Offer if relevant:** Links

### Step 3: Generate the Document

Once you have enough content:

1. Read the corresponding template from `templates/`
2. Fill in all provided fields
3. Include classification fields **only** if the user provided them
4. **Omit** any section that has no content — no empty tables, no placeholder rows, no "N/A"
5. Present the completed document to the user

## Guidelines

- **Offer, don't enforce.** Classification fields are helpful but never mandatory at creation time. If the user provides them, include them. If not, omit them entirely. Never block generation on missing classification data.
- **Be conversational.** Ask questions naturally, not like a form. If the user gives a paragraph explaining a bug, extract the relevant parts rather than asking them to repeat themselves in a structured format.
- **Infer where possible.** If the user says "the button doesn't work on mobile Safari," you already have environment info (mobile Safari) and partial reproduction context. Don't re-ask for things they've already told you.
- **Suggest, don't assign.** If context makes an Impact or Priority obvious, you may suggest it (e.g., "This sounds like a 🗃️ Data impact — want me to include that?"). Accept "no" gracefully and omit the field.
- **Keep it lean.** Don't pad the output with boilerplate the user will just delete. If a section has no content, omit it rather than leaving "N/A" everywhere.
- **Gently steer.** If the user's description doesn't match their chosen type, suggest the better fit — but accept their decision. The goal is guidance, not gatekeeping.

## Enhancement vs. Bug {#enhancement-vs-bug}

An **Enhancement** (🛠️) covers refactoring, tech debt reduction, and improvements to existing functionality that isn't broken. A **Bug** (🪲) is something that is objectively broken or behaves differently than specified.

If someone files a "bug" that describes how something *could* work better rather than something that's actually broken, gently suggest it might be an Enhancement. Conversely, if an "enhancement" describes broken behavior, suggest Bug instead.
