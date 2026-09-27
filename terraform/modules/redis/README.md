# redis

ElastiCache for Redis (replication group), in the data-tier subnets,
reachable only from the `redis` security group's ingress rule (app tier
only).

## AUTH token

Unlike RDS, ElastiCache has no equivalent to `manage_master_user_password`
— the AUTH token value must come from somewhere. This module generates it
once with `random_password` and stores it in a Secrets Manager secret it
owns (`<project>/<environment>/redis/auth-token`), encrypted with the
`secrets` KMS key. `ignore_changes` on `auth_token` means a later
`terraform apply` won't rotate it incidentally — rotate deliberately by
tainting `random_password.auth_token` (or removing and reapplying) as a
planned change, then redeploy dependent applications with the new value.

This is different from the generic placeholder pattern in
`terraform/modules/secrets/`: here Terraform is the sole owner and
generator of an internal-only credential, not standing in for a value
that must come from a human or a third party.

## Encryption & topology

- `at_rest_encryption_enabled` and `transit_encryption_enabled` are both
  always on (required for `auth_token` to be usable).
- `num_cache_clusters = 1` (default) is a single node with **no
  failover** — acceptable for development, not for production.
- Set `num_cache_clusters >= 2` and `automatic_failover_enabled = true`
  for staging/production. A `precondition` blocks apply if you set
  failover on without enough nodes.

## Not a system of record

Per `../../../ARCHITECTURE.md`, Redis here is for caching, rate limiting,
and transient state — never the source of truth for financial transaction
data.

## Example

```hcl
module "redis" {
  source = "../../modules/redis"

  project             = "PesaGuard"
  environment         = "production"
  subnet_ids          = module.networking.data_subnet_ids
  security_group_id   = module.security_groups.redis_security_group_id
  secrets_kms_key_arn = module.kms.secrets_key_arn

  node_type                  = "cache.r6g.large"
  num_cache_clusters         = 2
  automatic_failover_enabled = true
  snapshot_retention_limit   = 7
}
```
