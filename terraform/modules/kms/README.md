# kms

Creates five separate customer-managed KMS keys per environment, each with
automatic annual rotation enabled and a `deletion_window_in_days` safety
window:

| Key | Purpose | Alias |
|---|---|---|
| `secrets` | Secrets Manager secret encryption | `alias/<project>-<env>-secrets` |
| `logs` | CloudWatch Logs encryption | `alias/<project>-<env>-logs` |
| `backups` | S3 backup buckets, RDS/DB snapshots | `alias/<project>-<env>-backups` |
| `database` | RDS/Redis storage-at-rest encryption | `alias/<project>-<env>-database` |
| `messaging` | MSK broker storage encryption | `alias/<project>-<env>-messaging` |

Separate keys per purpose mean a compromised or over-broadly-granted role
for one purpose (say, reading backups) cannot also decrypt secrets or
database storage — blast radius is contained per key.

## Authorization model

Each key's policy only contains:

1. **`EnableIAMUserPermissions`** — delegates authorization to IAM. This
   key policy statement grants the AWS account root full `kms:*`, which
   in AWS's model means "IAM policies attached to roles/users in this
   account decide who can actually use this key" — it does **not** mean
   the root user can silently decrypt everything outside of IAM control.
2. **`AllowKeyAdmins`** (optional) — additional principals
   (`additional_key_admin_arns`) who can administer (not necessarily use)
   the keys, e.g. a platform team role.
3. **`logs` key only: `AllowCloudWatchLogs`** — CloudWatch Logs requires
   this explicit service-principal statement; IAM alone is not sufficient
   for that service. Scoped to this environment's log group prefix via an
   encryption-context condition.

Actual per-role usage grants (`kms:Decrypt`, `kms:GenerateDataKey`, etc. on
a specific key ARN) are written in `../iam/` — this module intentionally
does not know which application/service roles exist, avoiding a circular
module dependency.

## Inputs / outputs

See `variables.tf` / `outputs.tf`. All five key ARNs/IDs are output for
use by other modules (`iam`, and RDS/Redis/S3/MSK).

## Example

```hcl
module "kms" {
  source = "../../modules/kms"

  project     = "PesaGuard"
  environment = "development"
}
```
