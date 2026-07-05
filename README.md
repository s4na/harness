# harness

AI development harness for preserving approved design decisions as reusable assets across coding agents and human contributors.

This repository is not only a directory scaffold. It contains opinionated, best-practice-oriented design principles for skills, schema design, code review, TypeScript tooling, Rails, React, Terraform, Go, Rust, and LLM systems. The intent is to start with practical defaults, record exceptions as ADRs, and promote repeated or risky guidance into deterministic checks.

## Goals

- Capture repeated architectural decisions as Agent Skills and ADRs.
- Keep skills agent-neutral by using the `skills/*/SKILL.md` layout.
- Promote risky conventions into deterministic lint, git hook, and CI checks.
- Keep agent-specific adapters thin and optional.
- Give agents a comfortable repository-local initializer through `AGENTS.md` and `CLAUDE.md` without duplicating policy.

## Repository layout

```text
harness/
├── AGENTS.md
├── CLAUDE.md
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

## Skill domains

- `core-*`: review, ADR, and schema principles shared by all projects.
- `harness-*`: repository-local skills for maintaining this harness.
- `llm-*`: prompt engineering, RAG design, evals, and agent tooling.
- `rails-*`, `ts-*`, `react-*`, `tf-*`, `go-*`, `rust-*`: stack-specific implementation and enforcement guidance.

## Initial decisions

- `decisions/0001-no-status-column.md`: avoid generic `status` columns.
- `decisions/0002-voidzero-stack.md`: prefer the VoidZero/Vite+ TypeScript toolchain when feasible.
