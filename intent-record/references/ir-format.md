# Intent Record reference

## Example frontmatter

```yaml
---
type: intent-record
title: ナレッジベースのメンテナンス方針
description: RAGは派生キャッシュとし、truthは発話+承認済み意図の2層で持つ方針。
tags: [knowledge-ops, architecture]
timestamp: "2026-07-05T15:02:00+09:00"
id: ir-0042
status: ratified
derived_from:
  - source: utterances/2026/07/2026-07-05-voice-001.md
    span: "L12-L48"
interpreted_by:
  agent: "ai:claude-fable-5"
  at: "2026-07-05T14:30:00+09:00"
  acted_on_behalf_of: "human:kazuki"
ratified_by:
  agent: "human:kazuki"
  at: "2026-07-05T15:02:00+09:00"
  amendments: true
links:
  refines: [ir-0038]
  conflicts_with: []
  superseded_by: null
review_after: "2026-10-05"
---
```

## Example body

```markdown
## 原文抜粋(L0)

> 発話ログからの引用。改変禁止。

## 解釈された意図(L1)

RAGインデックスは派生キャッシュであり、真実のデータベースは「人間の一次発話」と「承認済みの意図」で構成する。

## 明示されなかった前提(L1)

- 対象は個人とチーム両方のナレッジベースと解釈した。
- 保存期間については言及がなかった。

## 承認メモ(L2)

- 人間の承認者が記入する。ドラフトでは未承認であることを書く。
```

## OKF / PROV-O / Palantir mapping

- OKF owns the container: directory-as-bundle, one concept per Markdown file, YAML frontmatter, Markdown graph links, `index.md`, `log.md`, and git distribution.
- PROV-O vocabulary inspires provenance: L0/L1 entities, interpretation and ratification activities, agents, `derived_from`, and `acted_on_behalf_of`.
- IR owns truth boundaries, lifecycle, ratification, permissions, staleness, and derived-cache policy.
- Palantir Ontology inspires separation between static schema and action/mutation definitions.

## Importing non-IR OKF bundles

Treat imported OKF content as L1/unratified until a human reviews and ratifies it. Use the IR workflow as a quarantine process for imported knowledge.

## Tags

Use `tags` as OKF frontmatter. Tags may also be first-class concept files. AI tagging is L1/draft work; creating new ontology vocabulary should require human ratification.
