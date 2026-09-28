# terraform/live/staging

Root Terraform configuration for the `staging` environment. Instantiates:

- `../../modules/networking` — VPC, subnets, NAT (single, shared), flow logs
- `../../modules/security-groups` — least-privilege SGs for ALB/app/data/monitoring
- `../../modules/kms` — secrets/logs/backups/database encryption keys
- `../../modules/secrets` — Secrets Manager containers (values set out-of-band)
- `../../modules/iam` — CI/CD, app-service, monitoring, backup-operator roles
- `../../modules/object-storage` — S3 buckets (backups/artifacts/logs)
- `../../modules/rds` — PostgreSQL (Multi-AZ per env config, RDS-managed master password)
- `../../modules/redis` — ElastiCache Redis (Terraform-generated AUTH token)
- `../../modules/msk` — Amazon MSK (IAM auth only, TLS, KMS-encrypted); topics via `scripts/messaging/`
- `../../modules/glue-schema-registry` — AWS Glue Schema Registry (+ private interface endpoint)

Not yet instantiated here (added as their phases land): DNS record wiring,
compute, load balancer, observability stack.

## Manual step after production's `iam` module is applied

Copy production's `oidc_provider_arn` output into this file's
`existing_oidc_provider_arn` (currently empty) before this environment's
`terraform_ci_role_arn` will work for GitHub Actions.

## Usage

```bash
terraform -chdir=terraform/live/staging init -backend-config=../../../environments/staging/backend.hcl
terraform -chdir=terraform/live/staging plan  -var-file=../../../environments/staging/terraform.tfvars
terraform -chdir=terraform/live/staging apply -var-file=../../../environments/staging/terraform.tfvars
```

Or: `make plan DIR=terraform/live/staging ENV=staging` / `make apply ...`.

## Requires

- `terraform/bootstrap` already applied for `staging`.
- AWS credentials with permission to create VPC/subnet/NAT/security-group
  resources.
