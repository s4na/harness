# ADR 0002: Use the VoidZero Toolchain for TypeScript Projects

## Status
Accepted

## Context
TypeScript projects often duplicate configuration across formatting, linting, testing, bundling, and type checking tools. This increases maintenance cost and causes inconsistent local and CI behavior.

## Decision
Use Vite+ (`vp`) as the preferred single entry point for TypeScript projects when the project stack supports it. Centralize tool configuration in `vite.config.ts`, run `vp check` for formatting, linting, and type checking, and use tsdown for library bundling.

## Consequences
- Projects get one standard command for local checks and CI.
- Shared Oxlint/Oxfmt configuration can be distributed through npm packages.
- Because Vite+ is still evolving, projects that cannot adopt it may use Oxlint, Oxfmt, Vitest, and tsdown directly while keeping the same shared configuration package.
