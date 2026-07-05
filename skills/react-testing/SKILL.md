---
name: react-testing
description: Use this skill for React component tests, Vitest browser mode, Testing Library, ARIA snapshots, accessibility assertions, UI state tests, and component-level regression tests. Do not use for Playwright E2E planning unless component tests are also involved.
---

# React Testing

## Principles

- Test user-observable behavior instead of implementation details.
- Prefer Vitest browser mode for components that depend on real browser behavior.
- Use accessible queries and ARIA snapshots to lock important semantics.
- Keep component tests small; move cross-page flows to E2E tests.
- Assert loading, error, empty, and permission states when they affect users.

## Checklist

- Tests fail without the behavior change.
- Queries reflect how users or assistive technology find the UI.
- Mock boundaries are explicit and do not hide integration defects.
