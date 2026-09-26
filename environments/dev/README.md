# development environment

Sandbox environment for infrastructure changes and application integration
testing. Not held to production SLAs.

## Setup

1. `cd terraform/bootstrap && terraform init && terraform apply -var-file=../../environments/dev/terraform.tfvars`
   (only needed once, to create this environment's state backend).
2. Copy the `backend_hcl` output into `environments/dev/backend.hcl`.
3. Copy `terraform.tfvars.example` to `terraform.tvars` and fill in values.
4. Once `terraform/live/dev/` exists (Phase 3+), run
   `terraform -chdir=terraform/live/dev init -backend-config=../../environments/dev/backend.hcl`.

## Isolation rules

- Uses its own state, its own AWS resources, and its own secrets —
  never references staging or production resource ARNs.
- Must never hold production credentials or production data.
- Safe to `terraform destroy` and rebuild; no uptime guarantees.

## Not yet implemented

No compute, networking, or data resources exist for this environment yet
(only the state backend, once `bootstrap` has been applied). See the root
[CHANGELOG.md](../../CHANGELOG.md) for phase status.
