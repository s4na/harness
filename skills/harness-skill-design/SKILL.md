---
name: harness-skill-design
description: Use this skill when creating or editing Agent Skills, SKILL.md frontmatter, skill descriptions, references, scripts, trigger wording, or progressive-disclosure structure in this harness repository.
---

# Harness Skill Design

This skill defines best practices for maintaining the harness itself.

## Design principles

- **One skill, one concern**: keep a skill focused enough that an agent can decide when to load it.
- **Trigger aggressively but precisely**: descriptions must include the task, when to use it, and likely trigger words. Avoid vague descriptions like "best practices" alone.
- **Optimize for composition**: domain skills may overlap. State when another skill should be loaded rather than trying to duplicate it.
- **Progressive disclosure**: keep `SKILL.md` concise and move checklists, examples, and long rationales to `references/`.
- **Decision traceability**: link non-obvious rules to an ADR in `decisions/`.
- **Escalate repeated failures**: if a rule is repeatedly missed or costly when missed, add a deterministic check in `scripts/`, `configs/`, hooks, or CI.

## Required skill structure

1. Frontmatter with `name` and a high-signal `description`.
2. A short purpose statement.
3. Concrete rules or workflow steps.
4. "When not to use" or composition guidance when the domain can be confused with another.
5. ADR links for decisions that are not obvious industry defaults.
6. References to supporting files instead of long inline material.

## Review checklist

Before committing a skill change:

- Confirm the description contains task words an agent or user will actually say.
- Confirm the skill states what to do, not only what to avoid.
- Confirm examples are domain-specific enough to guide implementation.
- Confirm enforcement candidates are called out when the guidance should become non-optional.
