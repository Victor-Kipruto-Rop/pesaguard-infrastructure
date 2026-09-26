# Contributing

This repository is the infrastructure/control-plane for PesaGuard. Changes
here affect real cloud resources, so the bar for review is higher than for
application code.

## Before you open a pull request

- Confirm the change belongs in this repository (infrastructure,
  networking, deployment, security, observability, backup/DR) and not in
  an application repository (FastAPI, Java services, frontend).
- Run local validation for whatever you touched:
  - Terraform: `make fmt`, `make validate`, `make lint`
  - Shell scripts: `shellcheck`
  - YAML: `yamllint`
- Never commit secrets, `.tfstate` files, or real credentials. Use
  `.env.example` / variable placeholders instead.

## Pull request expectations

- One logical change per PR (e.g. "add Redis module" rather than "add
  Redis, rework VPC, and update CI").
- Describe **what** changed, **why**, and the **blast radius** (which
  environments/resources are affected).
- Include the `terraform plan` output (or a summary) for infrastructure
  changes once the CI plan workflow is in place.
- Tag the relevant `CODEOWNERS` reviewer(s).

## Environment safety rules

- Changes to `environments/production/**` require explicit review and
  approval before merge — no auto-apply.
- Never point a `development` or `staging` configuration at a production
  resource ARN, endpoint, or credential.
- Destructive operations (`terraform destroy`, database drops, topic
  deletion) must be called out explicitly in the PR description and
  require a second reviewer.

## Style

- Terraform modules follow the standard layout: `main.tf`, `variables.tf`,
  `outputs.tf`, `versions.tf`, `README.md` (see
  [ARCHITECTURE.md](./ARCHITECTURE.md) for the full module conventions).
- Shell scripts use `set -euo pipefail` and validate prerequisites before
  acting.
- All AWS resources must carry the standard tag set defined in
  ARCHITECTURE.md (`Project`, `Environment`, `ManagedBy`, `Owner`,
  `Component`, `Service`, `CostCenter`, `DataClassification`).

## Commit messages

Use a short imperative summary, e.g.:

```
Add VPC module with public/private/data subnets
Fix Redis security group egress rule
Document RDS backup/restore runbook
```
