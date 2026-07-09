# Calibration briefs — golden fixtures for the pressure-test skill

Run these after any edit to SKILL.md or the council persona agents. They assert **mechanics, not verdicts**: a fixture fails if any hard mechanical check fails, regardless of what the Judge decides. Checks marked *(behavioral)* are expected-but-not-guaranteed content outcomes — investigate a miss, but don't auto-fail the run.

**Degraded-mode variants.** On a no-web platform, the Researcher checks become: blind mode is disclosed, zero URLs appear, and every Researcher figure is prefixed UNVERIFIED. On a no-subagent platform, expect five clearly labeled sequential sections, no auto-triggered review, and — if a review was explicitly requested — a disclosed self-review.

## Fixture 1 — weak commercial idea (contract + citation checks)

**Brief:** A $9/month Chrome extension that converts PDFs to Word documents, sold to general consumers. No distribution edge. Budget $2K, wants first dollar in 30 days.

Checks:
- All five responses follow the STANCE/POINTS/MUST-HEAR/DIVERGENCE/BUILD contract, each under 300 words, with an integer BUILD score.
- The Researcher attaches a URL to every number and named competitor; the Judge's rationale contains no uncited figure. *(no-web platforms: apply the degraded-mode variant instead)*
- The Buyer names at least one concrete free alternative. *(behavioral)*
- The verdict includes a cheapest 48-hour test even if the call is KILL.
- Confidence is consistent with the deterministic anchor rule given the observed BUILD spread and (if a review ran) the convergence definition.

## Fixture 2 — contested commercial idea (spread + review checks)

**Brief:** A commission-tracking mobile app for real-estate agents at $15/month, built by a solo senior .NET engineer whose spouse is an agent — built-in domain expertise and distribution into one brokerage. Budget: time only; wants first dollar in 90 days.

**Run this fixture with `--review`** so the peer-review machinery is always exercised, regardless of the spread the run happens to produce.

Checks:
- At least one persona returns a non-"none" DIVERGENCE line. *(behavioral)*
- Persona self-references are stripped before lettering; letters do not follow the convening order; a shuffle note precedes assignment; the letter→persona mapping appears nowhere before Step 3 and is stated when the Judge rules.
- Each review answers exactly the three questions, under 200 words, referencing responses by letter — not the STANCE/POINTS contract.
- The verdict's "Blind spot the review caught" line appears **if and only if** the round ran (requested or auto-triggered).
- Separately, on any parallel-capable run of this brief *without* `--review` where the BUILD spread lands ≥ 5: the review auto-triggers and is announced in one line. (Skip this check on sequential-fallback platforms, where the auto-trigger is disabled.)

## Fixture 3 — non-commercial idea (adaptation checks)

**Brief:** Migrate a multi-billion-row SQL Server ETL platform from self-managed Kubernetes to a managed cloud database service. Team of four, 12-month window; the current system is stable but ops-heavy.

Checks:
- Step 1 uses "who has to live with it" and "first result" instead of buyer/first-dollar questions.
- The Buyer role-plays the on-call engineer (or equivalent), not a purchaser, and is not asked to name a price (the price question is gated to commercial briefs).
- The verdict uses **Cost read** (effort, opportunity cost, reversibility); no pricing or time-to-first-dollar language leaks in.
- The 48-hour test validates the riskiest assumption without starting the migration.
