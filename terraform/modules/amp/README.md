# amp

Amazon Managed Service for Prometheus (AMP) — a managed Prometheus-
compatible workspace, with a starter rule group and an Alertmanager
definition that routes alerts to SNS natively (AMP's Alertmanager
supports an `sns_configs` receiver — no self-hosted Alertmanager needed).

## This workspace currently receives no data

Nothing in this repository remote_writes Prometheus metrics into AMP yet:
every environment's ECS `services` map is empty (see
`terraform/modules/ecs/README.md`), so there is no running container to
instrument. This module exists so the platform piece is ready — the
moment a real service is deployed, add an OpenTelemetry/ADOT sidecar
container to its task definition (not yet implemented — a natural
Phase 9+ addition to `terraform/modules/ecs/`) configured to
`remote_write` to this module's `remote_write_endpoint` output, using the
`app_service` IAM role (see `terraform/modules/iam/`'s
`enable_observability_access` flag, which grants `aps:RemoteWrite` scoped
to this workspace's ARN).

## The starter rule group is a template

`TargetDown` (`up == 0` for 5 minutes) is the one alert that's meaningful
regardless of what's being scraped — anything else requires knowing real
application metric names, which don't exist yet (no app is instrumented).
Replace/extend `aws_prometheus_rule_group_namespace.starter`'s YAML once
real services exist and you know what their metrics are actually called.

## Alertmanager routes everywhere to one topic for now

The definition in `main.tf` has one route and one receiver (the
`security` SNS topic, chosen as a default — not a judgment that every
alert is a security alert). Once there are real alerts worth routing
differently (e.g. by `severity` or `team` label), extend the `route`
tree; AMP's Alertmanager supports the same routing-tree semantics as
upstream Prometheus Alertmanager.

## Example

```hcl
module "amp" {
  source = "../../modules/amp"

  project             = "PesaGuard"
  environment         = "production"
  logs_kms_key_arn    = module.kms.logs_key_arn
  security_topic_arn  = module.sns_alerts.topic_arns["security"]
  sns_region          = var.region
}
```
