---
name: rust-project-design
description: Use this skill for Rust crate design, workspace layout, modules, error types, traits, ownership boundaries, async design, feature flags, and public API evolution.
---

# Rust Project Design

## Principles

- Keep crate public APIs small, documented, and semver-aware.
- Use workspaces to separate binaries, libraries, and integration support crates when boundaries are meaningful.
- Prefer explicit error enums for library APIs and contextual error wrappers for binaries.
- Keep feature flags additive and avoid mutually incompatible default features.
- Do not expose internal modules just to make tests easier; use integration tests or test-only helpers carefully.
- Choose async runtimes deliberately and avoid runtime-specific APIs in generic libraries when possible.
