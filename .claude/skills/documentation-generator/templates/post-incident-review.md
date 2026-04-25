# Post Incident Review: [Title]

## Metadata

**Incident Date:** [YYYYMMDD HH:MM UTC]
**Severity:** [SEV-1 | SEV-2 | SEV-3 | SEV-4]
**Author:** [Name]
**Date:** [YYYYMMDD]

## Status

<!-- Choose one: Draft | Awaiting Root Cause | In Review | Pending Approval | Approved | Completed | Follow-up Required | Closed | Canceled | Obsolete | Reopened -->

> Post Incident Review (aka Postmortem).

| Status | Description |
|--------|-------------|
| Draft | The Post Incident Review is being written. Initial facts are collected. |
| Awaiting Root Cause | The incident is known but root cause is still being investigated. |
| In Review | The draft is under internal or peer review. |
| Pending Approval | Awaiting sign-off from leads or responsible engineers. |
| Approved | Approved and ready to publish or share. |
| Completed | The Post Incident Review is published. Action items are assigned but not all are closed. |
| Follow-up Required | Additional remediation steps remain open. |
| Closed | All actions are resolved. The incident lifecycle is fully completed. |
| Canceled | The Post Incident Review was intentionally abandoned. No further work will be done. |
| Obsolete | Superseded by a newer or merged Post Incident Review. |
| Reopened | Incident was previously closed or canceled but has reoccurred or evolved. |

## Summary

[Brief description of what happened, how long it lasted, and what was impacted.]

## Detection

[How was the incident detected? Automated alerts, user reports, etc.]

## Impact

- [Quantified impact metric 1]
- [Quantified impact metric 2]
- [Quantified impact metric 3]

## Customer Impact

- [How customers were affected]
- [Customer communication details]

## Communications

- [Status page update details]
- [Internal communication channels used]
- [External communication if any]

## Timeline (UTC)

| Time | Event |
|------|-------|
| HH:MM | [Event description] |
| HH:MM | [Event description] |
| HH:MM | [Event description] |
| HH:MM | [Event description] |

## Root Cause

[Detailed explanation of what caused the incident. Be specific and technical.]

## Resolution and Recovery

[How did we respond? What steps were taken to resolve the incident?]

## What Went Well

- [Positive aspect 1]
- [Positive aspect 2]
- [Positive aspect 3]

## What Went Wrong

- [Problem 1]
- [Problem 2]
- [Problem 3]

## Where We Got Lucky

*Near-misses or fortunate circumstances that prevented worse outcomes. Document these to surface fragile systems before the next incident — the goal is to recognize how much stability depended on luck rather than engineering, so the same luck isn't required next time.*

- [Fortunate circumstance: e.g., the failing service was already behind a feature flag that happened to be off for 90% of traffic]
- [Fortunate circumstance: e.g., the on-call engineer happened to be online when the alert fired at 03:00]
- [Fortunate circumstance: e.g., the corrupt write hit a partition that hadn't been queried in 6 hours, giving us a recovery window]

## Corrective Measures

*What did we do to fix the current problem?*

- [Corrective measure 1]
- [Corrective measure 2]

## Preventative Measures

*How are we preventing similar issues in the future?*

- [Preventative measure 1]
- [Preventative measure 2]
- [Preventative measure 3]

## Action Items

| Action | Owner | Due Date | Status |
|--------|-------|----------|--------|
| [Action 1] | [Team/Person] | [YYYYMMDD] | [Open/Done] |
| [Action 2] | [Team/Person] | [YYYYMMDD] | [Open/Done] |
| [Action 3] | [Team/Person] | [YYYYMMDD] | [Open/Done] |

## References

- [Incident chat log]
- [Status page update (archived)]
- [Related monitoring dashboards]
- [Related runbooks]
