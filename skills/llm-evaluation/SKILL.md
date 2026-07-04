---
name: llm-evaluation
description: Use this skill for LLM evals, prompt regression tests, golden datasets, grading rubrics, model comparison, hallucination checks, agent behavior tests, and measuring prompt or RAG quality.
---

# LLM Evaluation

## Principles

- Evaluate behavior against task-specific acceptance criteria, not generic vibes.
- Keep a small golden set for fast regression checks and a larger set for release decisions.
- Include negative cases, ambiguity, missing context, and adversarial inputs.
- Prefer deterministic validators for structured output and rubric-based judges for qualitative behavior.
- Track both quality and operational metrics such as latency, tool calls, cost, and citation coverage.

## Workflow

1. Define the failure modes the eval must catch.
2. Create representative fixtures with expected properties or outputs.
3. Choose validators: exact match, schema validation, unit tests, human rubric, or LLM judge.
4. Run baseline and changed prompts/models on the same set.
5. Record the decision and threshold in an ADR when it affects project policy.
