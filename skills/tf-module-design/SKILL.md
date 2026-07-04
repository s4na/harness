---
name: tf-module-design
description: Use this skill for Terraform module design, variables, outputs, provider boundaries, state layout, naming, versioning, remote modules, and reusable infrastructure interfaces.
---

# Terraform Module Design

## Principles

- Design modules around stable infrastructure capabilities, not one-off resources.
- Keep inputs minimal, typed, validated, and documented.
- Expose outputs that callers need; do not leak every underlying resource attribute.
- Pin provider and module versions deliberately.
- Keep state boundaries aligned with ownership and blast radius.
- Avoid hidden provider configuration inside reusable modules unless explicitly documented.

## Checklist

- Variables have types, descriptions, and validation for risky values.
- Module changes are backward compatible or versioned as breaking changes.
- Security-sensitive defaults are safe by default.
