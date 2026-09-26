# production environment

Serves real PesaGuard traffic and real financial transaction data. Changes
here require explicit review and approval — see
[CONTRIBUTING.md](../../CONTRIBUTING.md#environment-safety-rules).

## Setup

1. `cd terraform/bootstrap && terraform init && terraform apply -var-file=../../environments/production/terraform.tfvars`
   (only needed once, to create this environment's state backend — this
   apply should be run deliberately, not as part of routine automation).
2. Copy the `backend_hcl` output into `environments/production/backend.hcl`.
3. Copy `terraform.tfvars.example` to `terraform.tfvars` and fill in
   values. Production tfvars values should be reviewed by a second person
   before first use.
4. Once `terraform/live/production/` exists (Phase 3+), run
   `terraform -chdir=terraform/live/production init -backend-config=../../environments/production/backend.hcl`.

## Isolation rules

- Uses its own state, its own AWS resources, and its own secrets — never
  shares credentials, ARNs, or endpoints with development or staging.
- No pull request may auto-apply against this environment (see
  `.github/workflows/` once CI/CD is implemented in Phase 9) — production
  changes require explicit human approval.
- Destructive operations (`terraform destroy`, database drops, topic
  deletion) require a documented runbook and a second reviewer. See
  [CONTRIBUTING.md](../../CONTRIBUTING.md).

## Recovery objectives

RPO/RTO targets for production are defined in `disaster-recovery/` once
Phase 10 lands. Until then, no disaster-recovery guarantees exist for this
environment because no production infrastructure has been provisioned yet.

## Not yet implemented

No compute, networking, or data resources exist for this environment yet
(only the state backend, once `bootstrap` has been applied). See the root
[CHANGELOG.md](../../CHANGELOG.md) for phase status.
