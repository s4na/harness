---
name: core-code-review
description: Use this skill for pull request review, code review, diff review, quality review, or when asked to inspect changes without rewriting code. Classify findings as Blocking, Should fix, or Nit and focus on actionable evidence.
---

# Core Code Review

Use this skill when reviewing a patch or pull request. Do not rewrite the code unless explicitly asked; identify risks and cite the relevant files or commands.

## Review severity

- **Blocking**: correctness, security, data loss, broken builds, migrations that cannot run, or violations of accepted ADRs.
- **Should fix**: maintainability, missing tests, incomplete edge cases, confusing naming, or likely future defects.
- **Nit**: style and small readability suggestions that should not block merging.

## Procedure

1. Read the diff and the surrounding code needed to validate behavior.
2. Run the smallest relevant tests or static checks when available.
3. Report only findings that are reproducible or strongly supported by the code.
4. Include file references, expected behavior, actual behavior, and a concrete fix direction.

For detailed prompts and checklist items, read `references/review-checklist.md`.
