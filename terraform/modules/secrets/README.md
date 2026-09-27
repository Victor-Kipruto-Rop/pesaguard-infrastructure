# secrets

Creates Secrets Manager **secret containers** for a list of names — never
real secret values.

## Why a placeholder value at all

Secrets Manager requires a secret to have at least one version before most
operations on it work cleanly. This module writes a single random
placeholder version (`{"status": "PLACEHOLDER_NOT_A_REAL_SECRET", ...}`)
so the container is usable immediately, then sets
`lifecycle { ignore_changes = [secret_string] }` so Terraform never
overwrites whatever real value someone puts there afterward, and never
diffs on/exposes that real value in a `plan`.

**A `terraform apply` after this module runs will never touch a secret's
real value.** Only the container's metadata (KMS key, tags, recovery
window) is managed here.

## Setting real values

After `apply`, someone with access to actual credentials sets the real
value — via the AWS Console, `aws secretsmanager put-secret-value`, or a
rotation Lambda (Phase 10) — for each secret in `secret_names_full`. This
repository never generates or stores what that real value is.

## Naming

Secrets are named `<project>/<environment>/<name>`, e.g.
`PesaGuard/development/database/credentials`. This namespacing is what
lets `../iam/`'s `app_service` role be scoped to
`secret:<project>/<environment>/*` rather than every secret in the account.

## Inputs / outputs

See `variables.tf` / `outputs.tf`. `secret_arns` feeds directly into the
`iam` module's `secret_arns` variable for tighter per-secret policy
scoping (optional — the `iam` module falls back to the same prefix
wildcard if you don't wire this through).

## Example

```hcl
module "secrets" {
  source = "../../modules/secrets"

  project     = "PesaGuard"
  environment = "development"
  kms_key_arn = module.kms.secrets_key_arn

  secret_names = [
    "database/credentials",
    "redis/auth-token",
    "kafka/credentials",
  ]
}
```
