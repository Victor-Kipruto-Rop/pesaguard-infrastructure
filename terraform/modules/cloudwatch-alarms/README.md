# cloudwatch-alarms

Golden-signal alarms on metrics AWS already publishes natively for RDS,
Redis, MSK, the ALB, and WAF — no agent, exporter, or scrape target
required, so these work from the moment the underlying resources exist
(unlike the `amp` module's rule groups, which need something to actually
remote_write Prometheus metrics first).

## What's covered and why

| Resource | Alarms | Signal |
|---|---|---|
| RDS | CPU, free storage, connection count | Saturation |
| Redis | Per-node CPU (`EngineCPUUtilization`), per-node memory (`DatabaseMemoryUsagePercentage`) | Saturation |
| MSK | `ActiveControllerCount` (must be exactly 1), `OfflinePartitionsCount` (must be 0) | Errors |
| ALB | Target 5xx count, average target response time | Errors, Latency |
| WAF | Blocked request count spike | Security |

Each alarm's `alarm_actions`/`ok_actions` point at one of the
`sns-alerts` topics, chosen by category (database/messaging/
infrastructure/security).

## Deliberately not covered in this phase

- **ECS/application-level alarms** — every environment's `ecs` module has
  `services = {}` (see `terraform/modules/ecs/README.md`); there is
  nothing running to alarm on yet. Add service-level CPU/memory/health
  alarms once a real service exists.
- **Per-broker MSK metrics** (CPU, disk, request latency) — these need a
  `Broker ID` dimension per broker and scale with cluster size; add them
  if/when this repo has somewhere real to view per-broker detail
  (Grafana, once `terraform/modules/grafana/` is enabled).
- **Consumer lag / DLQ growth** — still blocked on the same thing noted in
  `scripts/messaging/README.md`: nothing consumes these topics yet.
- **Redis `UnHealthyHostCount` / ALB target-group-level alarms** — no
  target group exists yet for the same reason as the ECS point above.

## Example

```hcl
module "cloudwatch_alarms" {
  source = "../../modules/cloudwatch-alarms"

  project     = "PesaGuard"
  environment = "production"

  database_topic_arn       = module.sns_alerts.topic_arns["database"]
  messaging_topic_arn      = module.sns_alerts.topic_arns["messaging"]
  infrastructure_topic_arn = module.sns_alerts.topic_arns["infrastructure"]
  security_topic_arn       = module.sns_alerts.topic_arns["security"]

  rds_instance_id         = module.rds.db_instance_id
  redis_cache_cluster_ids = module.redis.member_cluster_ids
  msk_cluster_name        = module.msk.cluster_name
  alb_arn_suffix          = module.alb.alb_arn_suffix
  waf_web_acl_name        = "${var.project}-${var.environment}-waf"
}
```
