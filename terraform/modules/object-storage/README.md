# object-storage

Creates one or more S3 buckets — by default `backups`, `artifacts`, and
`logs` — sharing the same security baseline:

- Versioning enabled
- SSE-KMS encryption (using the `backups` key from `terraform/modules/kms/`)
- Public access fully blocked (all four block-public-access settings)
- Bucket policy denying any request that isn't over TLS
- Lifecycle rule expiring noncurrent (old) object versions after
  `noncurrent_version_expiration_days` (per-bucket, default 90/365/90)

## What this does NOT do

- Cross-region replication (not yet implemented — see
  `../../../ARCHITECTURE.md` multi-region status)
- Glacier/Intelligent-Tiering transitions (kept simple for now; add a
  `transition` block per bucket if cost data justifies it later)
- Access logging to a dedicated log bucket (candidate for Phase 8/9
  hardening, not added now to avoid an unused bucket-of-logs before
  anything reads it)

## Example

```hcl
module "object_storage" {
  source = "../../modules/object-storage"

  project     = "PesaGuard"
  environment = "development"
  kms_key_arn = module.kms.backups_key_arn
}
```

Override `buckets` to add/remove buckets or change retention:

```hcl
  buckets = [
    { name = "backups",   noncurrent_version_expiration_days = 90 },
    { name = "artifacts", noncurrent_version_expiration_days = 365 },
    { name = "logs",      noncurrent_version_expiration_days = 90 },
    { name = "dr-exports", noncurrent_version_expiration_days = 180 },
  ]
```

## Inputs / outputs

See `variables.tf` / `outputs.tf`. `bucket_arns` / `bucket_names` are maps
keyed by the `name` you gave each bucket, for wiring into
`terraform/modules/iam/` (`app_s3_bucket_arns`, `backup_s3_bucket_arns`).
