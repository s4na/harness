---
name: rails-schema-design
description: Use this skill for Rails migrations, ActiveRecord schema changes, table additions, column additions, enums, status columns, and lifecycle state modeling. It applies core schema principles to Rails and includes a status-column checker.
---

# Rails Schema Design

Use this together with `core-schema-principles` for Rails database work.

## Rules

- Do not add generic `status` columns; see `decisions/0001-no-status-column.md`.
- Prefer explicit timestamp columns and ActiveRecord scopes named after domain milestones.
- Use transition models when history or audit metadata matters.
- Run `ruby skills/rails-schema-design/scripts/check_schema.rb` against migrations or schema files before opening a PR.

## CI integration

After installing this harness through APM, run the same script from the installed skill path so local skill guidance and CI enforcement share one implementation.
