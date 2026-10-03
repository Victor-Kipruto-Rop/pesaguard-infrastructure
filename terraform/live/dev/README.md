# terraform/live/dev

Root Terraform configuration for the `development` environment. Instantiates:

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
- `../../modules/ecr` — container registries (fastapi-service/java-service/worker)
- `../../modules/alb` — Application Load Balancer, **HTTP-only** (no DNS zone to validate a cert against yet)
- `../../modules/waf` — WAFv2 Web ACL (rate limiting + AWS managed rule groups) on the ALB
- `../../modules/ecs` — ECS cluster (Fargate); `services = {}` — no application deployed yet
- `../../modules/sns-alerts` — SNS topics per alert category (no subscriptions created — see its README)
- `../../modules/amp` — Amazon Managed Prometheus workspace + starter alert rule + Alertmanager→SNS routing (no data flowing in yet)
- `../../modules/cloudwatch-alarms` — golden-signal alarms on RDS/Redis/MSK/ALB/WAF, all wired to the SNS topics
- `../../modules/grafana` — Amazon Managed Grafana, **disabled by default** (requires IAM Identity Center)

Not yet instantiated here: real application services (populate the `ecs`
module's `services` map once an image exists — see
`../../modules/ecs/README.md`). SNS topics have no subscribers until someone
subscribes manually (see `terraform/modules/sns-alerts/README.md`).

## Manual step after production's `iam` module is applied

This environment does **not** create the account-wide GitHub OIDC
provider (`create_oidc_provider = false`) — production does. After
applying `terraform/live/production`, copy its `oidc_provider_arn` output
into this file's `existing_oidc_provider_arn` (currently empty) before
`terraform_ci_role_arn` here will actually work for GitHub Actions.

## Usage

```bash
# One-time, after terraform/bootstrap has been applied for dev and
# environments/dev/backend.hcl has been filled in:
terraform -chdir=terraform/live/dev init -backend-config=../../../environments/dev/backend.hcl

terraform -chdir=terraform/live/dev plan  -var-file=../../../environments/dev/terraform.tfvars
terraform -chdir=terraform/live/dev apply -var-file=../../../environments/dev/terraform.tfvars
```

Or via the root `Makefile`:

```bash
make plan  DIR=terraform/live/dev ENV=dev
make apply DIR=terraform/live/dev ENV=dev
```

## Requires

- `terraform/bootstrap` already applied for `development`
  (see `environments/dev/README.md`).
- AWS credentials with permission to create VPC/subnet/NAT/security-group
  resources.
