# Business Glossary

## Overview

This document defines key business and technical terms used across teams. It serves as the single source of truth for shared terminology.

## Terms

| Term | Acronym | Synonyms | Definition | Business Rules / Calculation | Example | Related Terms | Owner / SME |
|------|---------|----------|------------|------------------------------|---------|---------------|-------------|
| [Term] | [Short form, if any] | [Other names used for the same concept across teams] | [Clear definition] | [How it's calculated or rules that apply] | [Concrete example] | [Related terms] | [Team/Person responsible] |

## Example Entries

| Term | Acronym | Synonyms | Definition | Business Rules / Calculation | Example | Related Terms | Owner / SME |
|------|---------|----------|------------|------------------------------|---------|---------------|-------------|
| Active User | — | Engaged User, MAU Candidate | A registered user who has performed a meaningful action within a specific timeframe. | The user must have at least one session record in the UserSessions table within the last 30 calendar days. | A user who logged in on June 15th is considered "Active" until July 15th. | User, Churn, Engagement | Product Management |
| Annual Recurring Revenue | ARR | — | The total value of all active subscription contract revenue, normalized to a one-year period. | (Sum of monthly subscription fees × 12) + Sum of annual subscription fees. Does not include one-time fees. | 10 customers paying $50/mo and 2 paying $5,000/yr = $16,000 ARR | MRR, Revenue | Finance |
| Qualified Lead | — | Sales-Ready Lead | A potential customer vetted and deemed ready for sales engagement. | A lead becomes "Qualified" when they have: 1) Requested a demo, OR 2) Lead score exceeds 75. | A contact fills out "Request Demo" form and CRM status updates. | Lead, Conversion | Sales / Marketing |
| Service Health | — | Service Status, Component Health | Status indicator of whether a microservice is operating within acceptable parameters. | Based on uptime, error rate (<1% 5xx), and response time (<500ms P95). Calculated from Prometheus metrics. | UserProfileService shows "Unhealthy" due to >5% 5xx errors. | SLA, Uptime, Monitoring | SRE / DevOps |
| Feature Flag | — | Feature Toggle, Feature Switch | A toggle in the codebase that allows enabling or disabling specific functionality at runtime. | Flags stored in config store (Redis/LaunchDarkly). Default must be OFF unless tested in staging. | New payment method controlled via `EnableNewCheckout=true` for Beta testers. | Rollout, A/B Testing | Engineering |

## Categories

### Business Metrics

Terms related to business performance and KPIs.

### Technical Terms

Terms related to system architecture and engineering.

### Domain Terms

Terms specific to the business domain.

### Process Terms

Terms related to workflows and procedures.

## Guidelines for Adding New Terms

1. **Term** - Use the most common canonical name. If the canonical form is the abbreviation (e.g., "ARR"), prefer the full expansion as the term and put the abbreviation in Acronym.
2. **Acronym** - Short form, if one is in widespread use. Leave `—` if none.
3. **Synonyms** - Other names different teams use for the *same* concept. Capturing these prevents the same concept being defined twice under different names.
4. **Definition** - Write a clear, concise definition that a non-expert can understand
5. **Business Rules** - Document any calculations, thresholds, or rules that apply
6. **Example** - Provide a concrete example that illustrates the term
7. **Related Terms** - Link to *related but distinct* terms (not synonyms — those go in the Synonyms column)
8. **Owner** - Assign a team or person responsible for maintaining the definition

## Revision History

| Version | Date | Author | Changes |
|---------|------|--------|---------|
| 1.0 | [YYYYMMDD] | [Name] | Initial version |
