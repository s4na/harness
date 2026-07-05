---
name: ts-lib-design
description: Use this skill for TypeScript library design, package exports, tsdown bundling, declaration generation, isolatedDeclarations, ESM/CJS packaging, public API boundaries, and npm publishing.
---

# TypeScript Library Design

## Principles

- Design the public API before arranging internal files.
- Use `exports` in `package.json` to define explicit supported entry points.
- Prefer ESM-first packages; add CJS only when consumers require it.
- Bundle with tsdown and keep declaration generation compatible with `isolatedDeclarations`.
- Do not expose internal paths accidentally through broad export globs.
- Add type-level tests or compile fixtures for public API guarantees.

## Checklist

- `package.json` has `type`, `exports`, `types`, and `files` configured deliberately.
- Build output is reproducible and excludes tests, stories, and source-only fixtures.
- Breaking changes are reflected in versioning and release notes.
