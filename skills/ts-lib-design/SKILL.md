---
name: ts-lib-design
description: Use this skill for ts lib design tasks, project conventions, implementation review, and related configuration changes in this domain. Combine it with core skills when schema, ADR, or review rules also apply.
---

# ts lib design

This skill captures the default harness guidance for ts lib design work.

## Guidance

- Keep agent-specific behavior thin and prefer repository-standard tools that humans and CI also run.
- Link non-obvious conventions to ADRs in `decisions/`.
- Promote repeated guidance into deterministic lint, test, hook, or CI checks when failures would be costly.
- Use native package-manager distribution for enforcement configuration rather than relying on agent installation alone.

## When not to use

Do not use this skill for unrelated domains unless the task explicitly spans this stack.
