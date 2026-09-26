# bootstrap

Creates the remote state backend (S3 bucket + DynamoDB lock table) for one
environment. Run this **once per environment**, before anything in
`terraform/live/<env>/` can use a remote backend.

## Why this uses local state

Terraform needs a place to store state before it can create the resources
that normally hold that state — this module can't depend on the backend
it's creating. So `bootstrap/` intentionally keeps its own state **local**
(`terraform.tfstate` in this directory, gitignored).

This means:

- **Back up `terraform/bootstrap/terraform.tfstate` yourself** (e.g. copy
  it to a secure location, or a dedicated bucket created by hand) after
  running this module. Losing it means Terraform loses track of the
  bucket/table it created — the resources still exist in AWS, but you'd
  need to `terraform import` them to manage them again.
- Only run `apply` here from one place (a single operator's machine or a
  single CI job with access to that local state) to avoid two people
  creating divergent backends for the same environment.
- `prevent_destroy = true` is set on both the bucket and the table so an
  accidental `terraform destroy` in this directory can't take out
  Terraform's own state store.

## Usage

```bash
cd terraform/bootstrap
terraform init
terraform plan  -var-file=../../environments/dev/terraform.tfvars
terraform apply -var-file=../../environments/dev/terraform.tfvars
```

Repeat per environment (`dev`, `staging`, `production`), each with its own
`terraform.tfvars` (copy from `environments/<env>/terraform.tfvars.example`).

After `apply`, copy the `backend_hcl` output into
`environments/<env>/backend.hcl` (not committed — see
`backend.hcl.example` in that directory) so that
`terraform/live/<env>/` can initialize against this backend once Phase 3+
stacks exist there.

## Inputs / outputs

See `variables.tf` and `outputs.tf`. Notably, `backend_hcl` prints a
ready-to-paste backend config block after `apply`.

## Requires

- AWS credentials with permission to create S3 buckets, DynamoDB tables,
  and (for KMS-encrypted state) a KMS key — the default AWS-managed key
  is used here unless overridden in a later phase.
- One `apply` per environment; not shared across environments.
