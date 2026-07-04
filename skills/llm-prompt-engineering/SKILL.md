---
name: llm-prompt-engineering
description: Use this skill for prompt engineering, system prompts, developer prompts, agent instructions, LLM task design, few-shot examples, structured outputs, prompt evaluation, prompt injection resistance, and writing or reviewing skill descriptions.
---

# LLM Prompt Engineering

Use this skill when writing instructions for an LLM or agent.

## Prompt design principles

- **State the job and success criteria first**: the model should know what outcome it is optimizing for before seeing details.
- **Separate policy, context, and task data**: make immutable rules distinct from user-provided or retrieved content.
- **Prefer concrete workflows**: use ordered steps when sequence matters; use checklists when coverage matters.
- **Constrain output shape**: define schemas, headings, examples, or validation rules for outputs consumed by tools or humans.
- **Minimize hidden assumptions**: require the model to ask or state assumptions only when they affect correctness.
- **Design for refusal and escalation**: specify what to do when data is missing, unsafe, contradictory, or outside scope.
- **Test prompts like code**: keep representative fixtures and compare behavior before and after prompt changes.

## Anti-patterns

- Mixing trusted instructions with untrusted retrieved text without boundaries.
- Asking for "best" without defining criteria.
- Burying critical constraints after long examples.
- Depending on chain-of-thought disclosure rather than observable checks, summaries, or citations.
- Using examples that conflict with the written rule.

## Workflow

1. Define the target user, task, constraints, and failure modes.
2. Write the shortest instruction that makes the desired behavior testable.
3. Add examples only for ambiguous behavior or output format.
4. Add an evaluation prompt or fixture for regression testing.
5. Promote recurring prompt rules into this skill or an ADR.

Read `references/prompt-review-checklist.md` before reviewing prompt changes.
