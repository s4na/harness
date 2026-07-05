---
name: harness-repository-maintenance
description: Use this skill when changing this harness repository structure, apm.yml, adapters, configs, README, distribution paths, package layout, or cross-agent compatibility behavior.
---

# Harness Repository Maintenance

This repository is itself a product: a portable decision-distribution harness for humans and coding agents.

## Repository principles

- Keep `skills/*/SKILL.md` as the source of truth for agent-facing guidance.
- Keep `decisions/` as the source of truth for why a rule exists.
- Keep `configs/` focused on deterministic enforcement artifacts intended for native language ecosystems.
- Keep `adapters/` thin; agent-specific files should bootstrap or integrate, not redefine the rules.
- Update `apm.yml` whenever adding, removing, or renaming a distributable skill.
- Prefer additive, versionable changes over hidden global behavior.

## Change workflow

1. Identify whether the change affects guidance, enforcement, adapters, or ADRs.
2. Update the smallest source of truth first.
3. Link guidance to ADRs and enforcement checks when available.
4. Run syntax/frontmatter checks for every changed skill.
5. Keep initializer files such as `AGENTS.md` and `CLAUDE.md` small and pointer-only.
