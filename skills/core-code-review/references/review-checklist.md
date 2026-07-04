# Review Checklist

- Does the change preserve existing public behavior unless the PR says otherwise?
- Are migrations reversible and safe for existing data?
- Are domain states represented according to `decisions/0001-no-status-column.md`?
- Are tests present at the right level and do they fail without the change?
- Are errors handled at the boundary where callers can act on them?
- Are new dependencies justified and pinned through the project package manager?
