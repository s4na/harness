---
name: rails-rubocop
description: Use this skill for Rails RuboCop setup, shared RuboCop gem adoption, lint rules, autocorrect, CI lint enforcement, and explaining style or safety cops.
---

# Rails RuboCop

## Principles

- Distribute shared RuboCop configuration as a gem and consume it with `inherit_gem`.
- Keep project-local overrides rare and documented.
- Run RuboCop in CI and pre-commit hooks; agent hooks are only fast feedback.
- Prefer safety and correctness cops over purely stylistic churn.
- When disabling a cop, explain why the rule does not fit the local context.

## Checklist

- The project uses the shared gem version intentionally.
- Autocorrect is safe for the changed cops.
- CI fails on violations that should not be optional.
