---
name: react-component-design
description: Use this skill for React component design, props APIs, hooks, state ownership, accessibility, composition, React Compiler compatibility, rendering performance, and UI component refactors.
---

# React Component Design

## Principles

- Prefer composition over boolean-prop explosions.
- Keep state as local as possible; lift it only when multiple owners need coordination.
- Design accessible markup first: labels, roles, keyboard behavior, focus, and semantic HTML.
- Keep render logic pure and compatible with React Compiler expectations.
- Separate server data, view state, and derived state.
- Avoid premature memoization; measure before adding complexity.

## Checklist

- Props encode domain intent rather than implementation details.
- Loading, empty, error, and disabled states are explicit.
- Interactive components are keyboard-operable and screen-reader understandable.
- Complex components have focused tests using `react-testing`.
