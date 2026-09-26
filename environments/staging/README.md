# staging environment

Pre-production environment used to validate infrastructure and application
changes under production-like conditions before they reach production.

## Setup

1. `cd terraform/bootstrap && terraform init && terraform apply -var-file=../../environments/staging/terraform.tfvars`
   (only needed once, to create this environment's state backend).
2. Copy the `backend_hcl` output into `environments/staging/backend.hcl`.
3. Copy `terraform.tfvars.example` to `terraform.tfvars` and fill in values.
4. Once `terraform/live/staging/` exists (Phase 3+), run
   `terraform -chdir=terraform/live/staging init -backend-config=../../environments/staging/backend.hcl`.

## Isolation rules

- Uses its own state, its own AWS resources, and its own secrets —
  never references development or production resource ARNs.
- Sized closer to production than development, but may run smaller
  instance classes / lower replica counts to control cost.
- Should not hold real customer data. Use synthetic/anonymized data for
  testing.

## Not yet implemented

No compute, networking, or data resources exist for this environment yet
(only the state backend, once `bootstrap` has been applied). See the root
[CHANGELOG.md](../../CHANGELOG.md) for phase status.
