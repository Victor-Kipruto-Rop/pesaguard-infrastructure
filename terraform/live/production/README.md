# terraform/live/production

Root Terraform configuration for the `production` environment. Instantiates:

- `../../modules/networking` — VPC, subnets, **one NAT gateway per AZ** (HA)
- `../../modules/security-groups` — least-privilege SGs for ALB/app/data/monitoring
- `../../modules/dns` — the apex Route 53 hosted zone (production owns it;
  dev/staging are expected to reuse it for subdomains once Phase 7 adds
  records)
- `../../modules/kms` — secrets/logs/backups/database/messaging encryption keys
- `../../modules/secrets` — Secrets Manager containers (values set out-of-band)
- `../../modules/iam` — CI/CD, app-service, monitoring, backup-operator roles;
  **production creates the account-wide GitHub OIDC provider**
- `../../modules/object-storage` — S3 buckets (backups/artifacts/logs)
- `../../modules/rds` — PostgreSQL (Multi-AZ, deletion-protected, RDS-managed master password)
- `../../modules/redis` — ElastiCache Redis (2 nodes, automatic failover, Terraform-generated AUTH token)
- `../../modules/msk` — Amazon MSK (3 brokers, IAM auth only, TLS, KMS-encrypted); topics via `scripts/messaging/`
- `../../modules/glue-schema-registry` — AWS Glue Schema Registry (+ private interface endpoint)

Not yet instantiated here (added as their phases land): compute,
load balancer, observability stack.

## Usage

```bash
terraform -chdir=terraform/live/production init -backend-config=../../../environments/production/backend.hcl
terraform -chdir=terraform/live/production plan  -var-file=../../../environments/production/terraform.tfvars
```

`apply` against production requires `CONFIRM=yes` via the Makefile
(`make apply DIR=terraform/live/production ENV=production CONFIRM=yes`) —
see [CONTRIBUTING.md](../../../CONTRIBUTING.md) for the human-approval
expectation this does not replace.

## After first apply

1. Note the `dns_name_servers` output.
2. Delegate `domain_name` at your registrar to those name servers.
3. Nothing will resolve until Phase 7 adds actual DNS records pointing at
   the load balancer.

## Requires

- `terraform/bootstrap` already applied for `production`.
- AWS credentials with permission to create VPC/subnet/NAT/security-group/
  Route 53 resources.
- A second reviewer per [CONTRIBUTING.md](../../../CONTRIBUTING.md) for
  any production apply.
