---
name: intent-record
description: "Create, review, and maintain Intent Record (IR) knowledge bundles: OKF-compatible Markdown/YAML records that preserve provenance from human utterances (L0) through AI interpretation drafts (L1) to human ratification (L2). Use when asked to set up an IR/ADR-like knowledge base, draft an IR from utterances, validate IR lifecycle/status/link fields, design action-types that prevent AI echo chambers, or manage derived caches for RAG/indexes."
---

# Intent Record

## Core rule

Treat L0 utterances and L2 human ratifications as truth. Treat L1 interpretations, summaries, tags, embeddings, indexes, and digests as AI-derived candidates or caches until a human ratifies them.

## Bundle layout

Create or maintain an OKF v0.1-compatible bundle under `knowledge/` unless the user specifies another root:

```text
knowledge/
├── index.md
├── log.md
├── ontology/
│   ├── object-types.yaml
│   ├── link-types.yaml
│   └── action-types.yaml
├── utterances/YYYY/MM/*.md
├── intents/ir-####-slug.md
├── decisions/dr-####-slug.md
└── derived/
    ├── summaries/
    ├── index/
    └── digests/
```

Keep `derived/` fully reproducible and safe to delete. Do not treat databases, vector stores, summaries, or indexes as truth.

## Layer model

- **L0 Utterance**: immutable append-only human primary speech/text. AI transcription cleanup belongs below truth unless the human accepts it as the utterance artifact.
- **L1 Interpretation**: AI- or human-authored candidate interpretation. It must include `derived_from` references to L0 spans. Reject interpretations without L0 references.
- **L2 Ratification**: append-only human-only approval activity. AI may prepare drafts or flag issues, but must never ratify, deprecate truth, or silently change truth status.

## IR file requirements

Use YAML frontmatter plus Markdown body. Always include OKF fields `type`, `title`, `description`, and `timestamp`, even though OKF v0.1 only requires `type`.

Required IR extension fields:

- `id`: stable ID such as `ir-0042`.
- `status`: `draft`, `ratified`, `deprecated`, or `superseded`.
- `derived_from`: one or more L0 source paths and spans.
- `interpreted_by`: AI/human agent, timestamp, and optional `acted_on_behalf_of`.
- `ratified_by`: required only when status is `ratified`, `deprecated`, or `superseded`; agent must be human.
- `links`: only link types defined in `ontology/link-types.yaml`.
- `review_after`: recommended date for staleness checks.

Body sections should include:

1. `## 原文抜粋(L0)` with exact or minimally excerpted source quotes.
2. `## 解釈された意図(L1)` with the interpreted intent.
3. `## 明示されなかった前提(L1)` listing assumptions the AI filled in.
4. `## 承認メモ(L2)` for human approval notes; leave as pending/TODO in drafts.

The “明示されなかった前提” section is mandatory and should be prominent because LLM interpretation always introduces assumptions.

## Lifecycle workflow

1. Append the human utterance under `utterances/YYYY/MM/`.
2. Draft an IR in `intents/` with `status: draft` and explicit L0 `derived_from` spans.
3. Check existing IRs for conflicts and add `links.conflicts_with` when needed.
4. Ask for or record human ratification. Only a human may change status to `ratified` or deprecate/supersede truth.
5. Rebuild `derived/` caches after ratification or ontology changes.
6. On `review_after` or new utterances, flag stale/conflicting IRs by drafting a new IR or issue note; do not mutate truth automatically.

## Ontology/action constraints

Model action permissions in `ontology/action-types.yaml`:

- `append_utterance`: human only, append-only.
- `draft_interpretation`: human or AI, must reference `utterances/`, status must be `draft`.
- `ratify`: human only.
- `deprecate`: human only, require `reason` and `superseded_by` or explicit null.
- `flag_staleness`: AI allowed, output is a draft interpretation/flag only.
- `rebuild_derived`: AI or CI allowed for `derived/` only.

## Validation checklist

Before finishing IR work, verify:

- Every IR has OKF fields and valid YAML frontmatter.
- Every L1 interpretation has at least one L0 `derived_from` reference.
- No AI agent appears as `ratified_by.agent`.
- Deprecated/superseded records specify a successor or explicit null with reason.
- `derived/` contains only reproducible artifacts.
- Decisions in `decisions/` reference at least one IR.

For a fuller schema example, read `references/ir-format.md`.
