# glue-schema-registry

Schema Registry for PesaGuard's event schemas (Avro/JSON Schema/Protobuf),
implemented as **AWS Glue Schema Registry** rather than a self-hosted
service.

## Why Glue instead of Confluent/Redpanda Schema Registry

A self-hosted schema registry needs compute (Phase 7 doesn't exist yet)
and its own HA/backup story. Glue Schema Registry is a regional AWS
service (like S3 or Secrets Manager) reachable via the AWS API and IAM —
no servers to run, patch, or back up, and it natively supports Avro, JSON
Schema, and Protobuf, matching `../../../ARCHITECTURE.md`'s requirements.

## What this creates

- `aws_glue_registry` — the registry container. **No schemas are defined
  here** — schema definitions belong to the application repositories that
  own the events (per this repo's boundary rules — see the root
  `README.md`), registered via their own CI or the AWS SDK against this
  registry's name/ARN.
- Optionally (`create_vpc_endpoint = true`, the default), a private
  interface VPC endpoint + dedicated security group so app-tier calls to
  the Glue API stay inside the VPC instead of routing through NAT.

## Access control

Grant `glue:GetSchemaVersion`, `glue:GetSchemaByDefinition`,
`glue:RegisterSchemaVersion`, `glue:CreateSchema`, `glue:GetRegistry`, and
`glue:ListSchemas` — scoped to this module's `registry_arn` (and the
schemas within it) — to the `app_service` role in
`terraform/modules/iam/`. Do not grant `glue:*` broadly; the Glue service
also covers ETL jobs and crawlers unrelated to schemas.

## Example

```hcl
module "glue_schema_registry" {
  source = "../../modules/glue-schema-registry"

  project                = "PesaGuard"
  environment             = "production"
  vpc_id                  = module.networking.vpc_id
  vpc_cidr_block          = module.networking.vpc_cidr_block
  subnet_ids              = module.networking.app_subnet_ids
  app_security_group_id   = module.security_groups.app_security_group_id
}
```
