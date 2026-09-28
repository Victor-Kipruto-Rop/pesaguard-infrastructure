# msk

Amazon MSK (managed Kafka) cluster: brokers in the data-tier subnets,
reachable only from the `kafka` security group's ingress rule (app tier
and broker-to-broker only, no internet route).

## Why MSK instead of self-hosted Kafka/Redpanda

This repository has no compute yet (Phase 7), and self-hosting
Kafka/Redpanda well (broker lifecycle, disk management, upgrades,
monitoring) is itself a significant operational undertaking. MSK gives
brokers, storage, patching, and CloudWatch integration as a managed AWS
service now, without waiting on Phase 7. If a self-hosted alternative
becomes necessary later (cost, feature needs), that's a new module
alongside this one — not a rewrite of everything that depends on it,
since consumers only need the bootstrap-broker string and the security
group.

## Authentication: IAM only

The cluster enables **only** SASL/IAM client authentication
(`client_authentication.sasl.iam = true`) — no plaintext listener, no
separately-managed SASL/SCRAM username/password pairs to rotate. Access
control is IAM policy on `kafka-cluster:*` actions scoped to this
cluster's ARN (granted to the `app_service` role in
`terraform/modules/iam/`), consistent with how this repo handles AWS API
access everywhere else. Clients need the
[`aws-msk-iam-auth`](https://github.com/aws/aws-msk-iam-auth) library
(Java) or an equivalent for their language/runtime.

## What this creates

- `aws_msk_cluster` — brokers across the given subnets (one broker per
  subnet per "set"; `number_of_broker_nodes` must be a multiple of
  `length(subnet_ids)`), gp-equivalent EBS storage per broker, TLS
  encryption in transit (client↔broker and broker↔broker), KMS encryption
  at rest (the `messaging` key), enhanced monitoring, broker logs to
  CloudWatch.
- `aws_msk_configuration` — `auto.create.topics.enable=false` (topics are
  created deliberately — see below, not by a typo'd client), a
  replication factor / min-insync-replicas pair sized to the broker
  count, and `unclean.leader.election.enable=false` (never silently lose
  committed data for availability).

## Topics are not Terraform resources

Kafka topics are managed via a versioned manifest and script, **not** a
Terraform provider, deliberately:

- Terraform-managing topics would require the Terraform run (local or
  CI) to have network line-of-sight into this cluster's private subnets
  at every `plan`/`apply` — an operational dependency this repo doesn't
  otherwise have.
- Topic configuration (partitions, retention) changes more often and more
  operationally than the cluster itself; coupling it to the infrastructure
  apply cycle adds risk for little benefit.

See `../../../scripts/messaging/` for the topic manifest and apply script,
and `../../../scripts/messaging/README.md` for the DLQ/retry topic
pattern and consumer-lag monitoring status (deferred to Phase 8).

## Not yet implemented

- Consumer lag monitoring / alerting (Phase 8 — needs the observability
  stack to have somewhere to send alerts).
- Cross-region replication (MSK Replicator or MirrorMaker 2) — multi-region
  is not implemented anywhere in this repo yet.
- Multi-VPC / cross-account client access.

## Example

```hcl
module "msk" {
  source = "../../modules/msk"

  project            = "PesaGuard"
  environment        = "production"
  subnet_ids         = module.networking.data_subnet_ids
  security_group_id  = module.security_groups.kafka_security_group_id
  kms_key_arn        = module.kms.messaging_key_arn
  logs_kms_key_arn   = module.kms.logs_key_arn

  broker_instance_type   = "kafka.m5.large"
  number_of_broker_nodes = 3
  broker_ebs_volume_size = 500
}
```
