---
name: rails-app-design
description: Use this skill for Rails application architecture, controllers, models, services, jobs, validations, callbacks, transactions, ActiveRecord boundaries, and Rails code organization.
---

# Rails App Design

## Principles

- Keep controllers thin: authenticate, authorize, parse input, call domain/application code, and render.
- Put invariants close to the model, but avoid callback chains that hide side effects.
- Use transactions around multi-record state changes.
- Prefer explicit service/application objects for workflows spanning multiple aggregates or external systems.
- Keep background jobs idempotent and retry-safe.
- Use database constraints for invariants that must survive concurrency.

## Checklist

- Authorization and tenancy boundaries are enforced before data access.
- Validation errors are user-actionable.
- External side effects are not performed inside transactions unless deliberately safe.
