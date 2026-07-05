---
name: go-lint
description: Use this skill for golangci-lint setup, Go lint rules, staticcheck, govet, CI lint enforcement, shared Go lint configuration, and explaining lint failures.
---

# Go Lint

## Principles

- Use golangci-lint as the single CI entry point for Go static checks.
- Keep shared configuration versioned and reproducible.
- Treat `govet`, `staticcheck`, race-prone patterns, and error handling checks as high priority.
- Avoid disabling linters globally; prefer narrow inline suppressions with reasons.
- Run `go test ./...` separately from lint so test failures and static failures are clear.
