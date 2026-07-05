# ADR 0001: Avoid Generic `status` Columns

## Status
Accepted

## Context
Generic `status` columns tend to accumulate unrelated lifecycle states, hide important timestamps, and make transitions hard to audit. Teams repeatedly need to explain why a new enum value is risky and how the same state should be represented instead.

## Decision
Do not add generic `status` columns for domain lifecycle state. Prefer explicit timestamp columns such as `approved_at`, `rejected_at`, `archived_at`, or domain-specific state transition records when history, actors, or reasons matter.

## Consequences
- Queries can filter by explicit lifecycle milestones.
- State transitions are easier to audit and validate.
- Schema changes require clearer naming and migration planning.
- Exceptions are allowed only when integrating with an external protocol that already defines a status value, or when an ADR documents why explicit timestamps or transitions are not suitable.
