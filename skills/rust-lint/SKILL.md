---
name: rust-lint
description: Use this skill for Rust clippy, rustfmt, cargo-deny, lint levels, CI enforcement, unsafe policy, dependency audits, and explaining Rust lint failures.
---

# Rust Lint

## Principles

- Run `cargo fmt --check`, `cargo clippy -- -D warnings`, and `cargo deny check` in CI.
- Keep lint configuration in versioned templates such as `configs/clippy/`.
- Treat `unsafe` as an architectural decision: document invariants and prefer safe abstractions.
- Audit licenses, advisories, and duplicate dependencies with cargo-deny.
- Use narrowly scoped `allow` attributes with explanations when a lint is intentionally bypassed.
