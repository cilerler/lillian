---
mode: agent
description: Convenes independent AI assistants (Claude, Codex, Antigravity) to perform cross-vendor peer reviews of plans, designs, or code
---

# Cross-Vendor Examine

Convenes the AI assistants installed on this machine — each from a different vendor — as independent peer reviewers of a document, plan, or decision, then reports where they agree, where they disagree, and how to resolve splits.

Load and follow `.github/skills/cross-vendor-examine/SKILL.md` for the complete review protocol, peer discovery rules, CLI execution guardrails, and synthesis format.

## Overview

Use this prompt when you want to get a second opinion from another AI vendor, run a plan or decision past Claude/Codex, or surface cross-vendor disagreements before committing to a major change.

## Execution Workflow

1. **Step 1 — Discover Peers**: Probe installed CLIs (`agy`, `claude`, `codex`). Drop the host CLI from discovery results and ask the user which peer assistant(s) to convene.
2. **Step 2 — Write Host Analysis First**: Write and save the host assistant's independent analysis before invoking peers to prevent self-review contamination.
3. **Step 3 & 4 — Formulate & Deliver Brief**: Compose the prompt per Step 4 rules (setting settled decisions, asking for exact replacement text, and requesting host adjudication), then deliver via CLI with strict tool and permission guardrails.
4. **Step 5 — Relay & Synthesize**: Quote peer responses verbatim. Synthesize consensus, new findings, and reasoned adjudication without majority voting bias.
5. **Step 6 — Bounded Confirmation Pass**: Run at most 1 confirmation pass (2 total rounds max) if changes are applied, requiring explicit consent for any further rounds.
