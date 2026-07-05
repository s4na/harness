---
name: ts-toolchain
description: Use this skill for TypeScript toolchain work, Vite+, vp check, vite.config.ts, Oxlint, Oxfmt, Vitest, tsgolint, package scripts, staged hooks, CI checks, and VoidZero stack adoption or fallback planning.
---

# TypeScript Toolchain

Use Vite+ (`vp`) as the default single entry point when the framework supports it. See `decisions/0002-voidzero-stack.md`.

## Principles

- Centralize tool configuration in `vite.config.ts` when using Vite+.
- Make `vp check` the canonical local and CI command for formatting, linting, and type checking.
- Keep shared Oxlint/Oxfmt rules in a versioned npm package such as `@org/oxlint-config`.
- Use staged hooks for fast feedback, but treat CI as the enforcement boundary.
- If Vite+ cannot support the framework, use Oxlint, Oxfmt, Vitest, and tsdown directly with the same shared config package.

## Checklist

- Add or update package scripts for the canonical check command.
- Ensure CI runs the same check as local development.
- Avoid parallel ESLint/Prettier configs unless a documented migration requires them.
