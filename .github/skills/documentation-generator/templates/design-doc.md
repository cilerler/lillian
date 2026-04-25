# Design Doc: [Title]

## Metadata

**Date:** [YYYYMMDD]
**Status:** [current value]
**Authors:** [Names]
**Reviewers:** [Names]

## Status

<!-- Choose one: Draft | In Review | Approved | Implemented | Superseded | Archived -->

| Status | Description |
|--------|-------------|
| Draft | Still under development; feedback and changes expected. |
| In Review | Design has been submitted and is under active review. |
| Approved | Design agreed upon; implementation can begin or is in progress. |
| Implemented | Design has been implemented in production. |
| Superseded | Design replaced by a newer Design Doc. |
| Archived | Design is no longer applicable. |

## Context and Scope

[Describe the context of this design. How does it fit into the larger system?]

### Goals

- [Goal 1 - what this design tries to achieve]
- [Goal 2]
- [Goal 3]

### Non-Goals

- [Non-goal 1 - what this design explicitly does NOT try to achieve]
- [Non-goal 2]

## Overview

[Provide a high-level summary of the design. A reader should understand the approach after this section.]

## Detailed Design

[The bulk of the document. Explain the design, its tradeoffs, and consequences. Structure this section as appropriate for your specific design.]

### Component 1

[Description]

### Component 2

[Description]

### Relationship to Other Systems

[How does this design interact with existing systems?]

## Cross-Cutting Concerns

### Security

[How does the design address security?]

### Privacy

[How does the design handle user data?]

### Scalability

[How will this scale?]

### Monitoring

[How will this be monitored?]

## Testing Strategy

[How will this be tested? Coverage approach across unit / integration / E2E. Performance and load test approach. Any chaos or fault-injection plan. Test data strategy if non-obvious.]

- **Unit:** [scope, framework]
- **Integration:** [scope, framework]
- **E2E:** [critical user journeys]
- **Performance:** [targets, scenarios]
- **Other (security, accessibility, chaos):** [as relevant]

## Alternatives Considered

### Alternative 1: [Name]

[Description and why it was not chosen]

### Alternative 2: [Name]

[Description and why it was not chosen]

## Metrics

[How will success be measured? What metrics will be tracked?]

| Metric | Target | How Measured |
|--------|--------|--------------|
| [Metric 1] | [Target value] | [Measurement method] |

## Rollout Plan

[Phased release approach. Feature flags. Migration steps. Backward-compatibility handling. Deprecation path for old code paths or APIs.]

- **Phase 1 ([scope]):** [what ships, behind which flag, to whom]
- **Phase 2 ([scope]):** [next ramp]
- **Phase 3 ([scope]):** [GA / cleanup]
- **Migration:** [data migration steps; old → new compatibility window]
- **Deprecation:** [what gets removed and when]

## Timeline

| Phase | Target Date | Description |
|-------|-------------|-------------|
| Design Finalization | [YYYYMMDD] | |
| Implementation | [YYYYMMDD] | |
| Testing | [YYYYMMDD] | |
| Rollout | [YYYYMMDD] | |

## Open Questions

- [Question that must be resolved before implementation]
- [Decision deferred to later phase]

## References

- [Link to related documentation]
- [Link to related RFC or ADR]
