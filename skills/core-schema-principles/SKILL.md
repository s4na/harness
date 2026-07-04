---
name: core-schema-principles
description: Use this skill for database schema design, migrations, table creation, column additions, enums, status fields, lifecycle state, state machines, and data modeling in any language. Always consult this before adding status-like columns.
---

# Core Schema Principles

This skill defines language-independent database design rules.

## Decisions

- Do not add generic `status` columns for domain lifecycle state.
- Prefer explicit `xxx_at` timestamp columns for important milestones.
- Use a transition table when history, actor, reason, ordering, or auditability matters.
- If an external API requires a status value, document the exception and keep the external vocabulary at the boundary.

The rationale and exception policy are recorded in `decisions/0001-no-status-column.md`.

## Workflow

1. Identify the lifecycle events the model needs to represent.
2. Name explicit columns for stable milestones, such as `approved_at` or `archived_at`.
3. Choose a transition table when the sequence of changes is domain data.
4. Reject new generic status columns unless an ADR documents the exception.

Read `references/state-machine.md` when designing a transition table.
