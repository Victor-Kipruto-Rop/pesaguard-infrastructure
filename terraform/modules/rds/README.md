# rds

Single-instance (optionally Multi-AZ) RDS PostgreSQL, in the data-tier
subnets from `terraform/modules/networking/`, reachable only from the
`postgres` security group's ingress rule (app tier only — see
`terraform/modules/security-groups/`).

## Master password: RDS-managed, not Terraform-managed

This module never sets `master_password`. Instead it uses
[`manage_master_user_password = true`](https://docs.aws.amazon.com/AmazonRDS/latest/UserGuide/rds-secrets-manager.html),
so **RDS itself** creates and owns a Secrets Manager secret
(`rds!db-<id>`) holding the master credential, encrypted with the
`secrets` KMS key. Benefits over Terraform generating the password:

- The password is never a Terraform Terraform state.
- AWS can rotate it natively without a `terraform apply`.
- Reading it requires `secretsmanager:GetSecretValue` on that specific
  secret ARN (`master_user_secret_arn` output) — grant this to the
  `app_service` IAM role, not broader access.

## What this creates

- `aws_db_subnet_group` across the given data-tier subnets
- `aws_db_parameter_group` (SSL required — `rds.force_ssl = 1` — and slow
  query logging at 1s)
- `aws_db_instance`: gp3 storage (encrypted, KMS), storage autoscaling up
  to `max_allocated_storage`, automated backups (`backup_retention_period`,
  point-in-time recovery within that window), Performance Insights, and
  PostgreSQL log export to CloudWatch Logs

## RPO / RTO (default configuration)

| | Default | Notes |
|---|---|---|
| RPO | Up to 5 minutes | AWS's continuous backup / transaction log shipping for PITR |
| RTO | Typically 10-30+ minutes | Time to restore-to-point-in-time or promote a Multi-AZ standby; varies with instance size and data volume — not yet measured empirically for this project |

These are AWS platform defaults, not yet validated by an actual restore
drill. A tested, documented RTO/RPO (per `../../../CHANGELOG.md` Phase 10)
is not implemented until the DR phase runs a real restore.

## Restoring to a point in time (manual, until Phase 10 scripts this)

```bash
aws rds restore-db-instance-to-point-in-time \
  --source-db-instance-identifier <name_prefix>-postgres \
  --target-db-instance-identifier <name_prefix>-postgres-restored \
  --restore-time <ISO8601 timestamp>
```

This creates a **new** instance — it does not overwrite the original.
Point application configuration at the restored instance only after
verifying its data, then decide whether to decommission the original.

## Not yet implemented

- Read replicas (add if/when read scaling is needed — not premature here)
- Cross-region snapshot copy (multi-region is not yet implemented at all
  — see `../../../ARCHITECTURE.md`)
- Automated, tested restore drills (Phase 10)

## Example

```hcl
module "rds" {
  source = "../../modules/rds"

  project              = "PesaGuard"
  environment          = "production"
  subnet_ids           = module.networking.data_subnet_ids
  security_group_id    = module.security_groups.postgres_security_group_id
  storage_kms_key_arn  = module.kms.database_key_arn
  secrets_kms_key_arn  = module.kms.secrets_key_arn

  instance_class           = "db.r6g.large"
  multi_az                 = true
  deletion_protection      = true
  skip_final_snapshot      = false
  backup_retention_period  = 30
}
```
