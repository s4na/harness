---
name: go-project-layout
description: Use this skill for Go repository layout, packages, cmd/internal/pkg boundaries, modules, interfaces, error handling, context propagation, and dependency organization.
---

# Go Project Layout

## Principles

- Keep packages cohesive and named by what they provide, not by layer suffixes alone.
- Use `internal/` to enforce private boundaries.
- Keep `cmd/` thin and move reusable behavior into packages.
- Accept interfaces at consumers; return concrete types from constructors when practical.
- Pass `context.Context` through request-scoped and I/O-bound operations.
- Wrap errors with actionable context without losing sentinel behavior when callers rely on it.

## Checklist

- Package imports do not create cycles or hidden global initialization.
- Tests are close to packages and use external tests for public API behavior.
- Configuration and logging are injected rather than read from globals deep in packages.
