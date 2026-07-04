# harness

AI development harness for preserving approved design decisions as reusable assets across coding agents and human contributors.

## Goals

- Capture repeated architectural decisions as Agent Skills and ADRs.
- Keep skills agent-neutral by using the `skills/*/SKILL.md` layout.
- Promote risky conventions into deterministic lint, git hook, and CI checks.
- Keep agent-specific adapters thin and optional.

## Repository layout

```text
harness/
├── apm.yml
├── skills/
├── decisions/
├── configs/
└── adapters/
```

## Layers

1. **Probabilistic guidance**: `skills/` explains design rules to coding agents.
2. **Deterministic enforcement**: `configs/` holds lint and check implementations intended for native package-manager distribution.
3. **Adapters**: `adapters/` contains thin agent-specific integration glue.

## Initial decisions

- `decisions/0001-no-status-column.md`: avoid generic `status` columns.
- `decisions/0002-voidzero-stack.md`: prefer the VoidZero/Vite+ TypeScript toolchain when feasible.
