---
name: tf-plan-review
description: Use this skill for Terraform plan review, infrastructure diffs, resource replacement analysis, drift, IAM/security changes, cost impact, and CI review of terraform plan output.
---

# Terraform Plan Review

## Review priorities

- Destructive changes, replacements, and state moves.
- IAM, networking, public exposure, encryption, and secret handling.
- Cost, quota, and regional impact.
- Drift that suggests manual changes outside Terraform.
- Provider upgrades and generated diff noise.

## Procedure

1. Summarize creates, updates, deletes, and replacements.
2. Identify blast radius and rollback strategy.
3. Verify security-sensitive changes against policy.
4. Require human approval for destructive or privilege-expanding changes.
