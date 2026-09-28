# iam

Creates the GitHub Actions OIDC trust and the service-facing IAM roles
this project needs so far. No long-lived AWS access keys are used
anywhere — CI/CD authenticates via OIDC, and application/monitoring
workloads assume roles via their EC2 instance profile or ECS task role.

## Roles created

| Role | Assumed by | Purpose |
|---|---|---|
| `<project>-<env>-terraform-ci` | GitHub Actions (OIDC) | `terraform plan`/`apply` from CI, scoped to this repo + allowed refs |
| `<project>-<env>-app-service` | `ecs-tasks.amazonaws.com` or `ec2.amazonaws.com` | FastAPI/Java services/workers: read secrets, decrypt secrets/logs keys, write logs, publish metrics; optionally MSK data-plane access (`enable_msk_access`) and Glue Schema Registry access (`enable_glue_registry_access`) |
| `<project>-<env>-monitoring` | `ecs-tasks.amazonaws.com` or `ec2.amazonaws.com` | Prometheus/Grafana/Alertmanager: describe EC2 for service discovery, read CloudWatch metrics/logs |
| `<project>-<env>-backup-operator` | `backup.amazonaws.com`, `events.amazonaws.com` | Scheduled snapshot/backup automation |

`app_service` and `monitoring` also get an **instance profile** (for the
EC2 compute path) and the AWS-managed `AmazonSSMManagedInstanceCore`
policy, so Session Manager works without any inbound SSH security group
rule (see `../../../security/host-hardening.md`).

## MSK and Glue access (optional, flag-gated)

`enable_msk_access` grants `app_service` `kafka-cluster:Connect`,
`DescribeCluster`, `DescribeTopic`, `ReadData`, `WriteData`, `AlterGroup`,
and `DescribeGroup` on the given cluster's topics and consumer groups. It
deliberately **omits** `CreateTopic`/`DeleteTopic`/`AlterTopic` — topic
lifecycle is an operator action (`scripts/messaging/apply-topics.sh`).
`enable_glue_registry_access` grants schema read/register actions scoped to
one registry and its schemas, not `glue:*`.

These are separate booleans rather than being inferred from whether the
ARN variable is set, because the ARNs are unknown at plan time on a first
apply and Terraform cannot use an unknown value to decide whether a
`for_each` statement exists.

## GitHub OIDC

`aws_iam_openid_connect_provider` is **account-wide** — creating it twice
in the same AWS account fails. Set `create_oidc_provider = true` in
exactly one environment (this repo's convention: production, mirroring
how `../dns` handles the apex zone) and pass its ARN via
`existing_oidc_provider_arn` everywhere else.

The CI/CD role's trust policy restricts `sub` claims to
`repo:<github_org>/<github_repo>:<ref>` for each ref in
`allowed_github_refs` — e.g. restrict production's role to
`["ref:refs/heads/main"]` so no other branch or fork can assume it.

## Policy scope and what's still "*"

Policies are scoped to specific resource ARNs wherever AWS supports it
(the state bucket, the lock table, this environment's log group prefix,
this environment's secret prefix, specific KMS key ARNs, IAM role/profile
names under `<project>-*`). A few statements still use `Resource = "*"`,
each with a comment explaining why:

- EC2 networking mutate actions (`CreateVpc`, `CreateSubnet`, etc.) — AWS
  does not support resource-level ARN scoping for most EC2 API actions.
- `route53:*` — Route 53 zones are global and not yet scoped to a specific
  zone ID at this phase.
- `cloudwatch:PutMetricData` / read-only `Describe*`/`List*`/`Get*` calls —
  these APIs don't support resource-level scoping; the metrics statement
  is scoped by namespace via a condition instead.
- `rds:CreateDBSnapshot` and friends — narrowed to specific DB instance
  ARNs once Phase 5 creates them.

## Inputs / outputs

See `variables.tf` / `outputs.tf`. Note this module takes KMS key ARNs
and Terraform state bucket/table ARNs as inputs — it does not create
those itself (see `../kms/` and `../../bootstrap/`).

## Example

```hcl
module "iam" {
  source = "../../modules/iam"

  project     = "PesaGuard"
  environment = "production"
  region      = "us-east-1"

  create_oidc_provider = true
  github_org           = "Victor-Kipruto-Rop"
  github_repo          = "pesaguard-infrastructure"
  allowed_github_refs  = ["ref:refs/heads/main"]

  secrets_kms_key_arn  = module.kms.secrets_key_arn
  logs_kms_key_arn     = module.kms.logs_key_arn
  backups_kms_key_arn  = module.kms.backups_key_arn
  database_kms_key_arn = module.kms.database_key_arn

  state_bucket_arn = "arn:aws:s3:::pesaguard-tfstate-production-<account-id>"
  lock_table_arn   = "arn:aws:dynamodb:us-east-1:<account-id>:table/pesaguard-tflock-production"
}
```
