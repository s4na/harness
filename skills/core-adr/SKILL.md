---
name: core-adr
description: Use this skill whenever a new architectural decision, design rule, exception, convention, or repeated review comment should be recorded in decisions/ as an ADR. Trigger words include ADR, architecture decision, design decision, convention, exception, rule, standardize, and document why.
---

# Core ADR

Use this skill to turn a design decision into a durable repository asset.

## When to create or update an ADR

- The same explanation or review comment has been repeated twice.
- A rule affects multiple projects, agents, or future migrations.
- A decision has a non-obvious tradeoff or exception path.
- A deterministic enforcement layer should be added later.

## ADR format

Create `decisions/NNNN-short-title.md` with:

1. Title
2. Status (`Proposed`, `Accepted`, `Superseded`)
3. Context
4. Decision
5. Consequences
6. Exceptions, if any
7. Links to skills or enforcement checks that implement the decision

Keep ADRs concise and link skills back to the ADR that justifies them.
