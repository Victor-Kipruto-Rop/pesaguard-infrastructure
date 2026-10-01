# Architecture

This document describes the **target** architecture for PesaGuard's
infrastructure. It is written before most of the infrastructure exists, so
it distinguishes between what is implemented and what is planned. Check
[CHANGELOG.md](./CHANGELOG.md) for current implementation status.

## Repository boundaries

```
pesaguard                          → application/business platform
api.pesaguard.victorkipruto.com    → FastAPI API
developer-platform                 → developer-facing platform
<java services repo>               → Java microservices
pesaguard-infrastructure (this repo) → AWS + networking + databases +
                                        messaging + deployment + security +
                                        observability + backups + DR
docs.pesaguard.victorkipruto.com   → developer documentation
status.pesaguard.victorkipruto.com → public service status
```

This repository is the control plane. It never contains application
business logic (transaction processing, fraud detection, reconciliation
rules, UI code).

## Target high-level architecture

```
Internet
   |
Route 53 (DNS)
   |
WAF
   |
Application Load Balancer (TLS termination)
   |
Private application subnets
   |
   +------------------------+------------------------+
   |                        |                         |
FastAPI services      Java services              Workers
   |                        |                         |
   +------------+-----------+------------+------------+
                |                        |
         Internal services       Kafka (Amazon MSK)
                |                        |
   +------------+------------+   +-------+--------+
   |                         |   |                |
PostgreSQL (RDS)          Redis  Schema Registry  DLQ/Retry topics
```

```
                        Observability
        +-----------+-----------+-----------+
        |           |           |           |
   Prometheus    Grafana   OpenTelemetry   Loki
        |           |           |
        +-----------+-----------+
                    |
               Alertmanager

                        Recovery
        +-----------+-----------+
        |           |           |
     Backups        DR       Restore
```

## Trust boundaries

| Boundary | Description |
|---|---|
| Internet ↔ Edge | Only Route 53, WAF, and the ALB's HTTPS listener are internet-facing. |
| Edge ↔ Application | ALB forwards to private-subnet targets only; no direct internet route to app instances. |
| Application ↔ Data | Databases, Redis, and Kafka brokers live in private data subnets with no public IP and no route to the internet gateway. |
| Application ↔ Management | Administrative access uses AWS Systems Manager Session Manager / IAM, not public SSH. |
| Everything ↔ Observability | Metrics/log/trace pipelines are one-way (push) from services to the observability stack; the observability stack has no write access back into application data stores. |

## Failure domains & availability

- Resources are distributed across multiple Availability Zones within
  `us-east-1`.
- Databases use Multi-AZ where supported (RDS PostgreSQL).
- The module structure keeps region-specific values (region, AZs, CIDR
  ranges, domain names) as variables so a second AWS region can be added
  later without restructuring existing modules — this repository does not
  yet implement multi-region or active-active deployment. Until Phase 10+
  says otherwise, assume **single-region, single-AZ-failure-tolerant**
  only.

## Environments

`development`, `staging`, `production` — each with isolated Terraform
state, configuration, secrets, and resources. Production must never be
reachable from development configuration or credentials.

## Terraform module conventions

Every reusable module contains:

```
module-name/
├── main.tf
├── variables.tf
├── outputs.tf
├── versions.tf
└── README.md
```

with `data.tf` / `locals.tf` added where useful. Modules take
environment-specific values as variables — no environment-specific values
are hard-coded into a reusable module.

## Standard resource tags

Every AWS resource created by this repository must carry:

```
Project=PesaGuard
Environment=<development|staging|production>
ManagedBy=Terraform
Owner=PesaGuard
Component=<component>
Service=<service>
CostCenter=<cost-center>
DataClassification=<classification>
```

## Data flows (planned)

```
API request → auth → transaction service → event publication →
Kafka (MSK) → consumer → database → notification
```

Trace ID / span ID / correlation ID / request ID are propagated across
this flow (OpenTelemetry, Phase 8). Sensitive financial data is never
placed in tracing attributes or logs.

## Messaging (implemented in Phase 6)

- **Broker platform:** Amazon MSK, in the data-tier subnets. Redpanda /
  self-hosted Kafka was considered and not chosen: this repo has no compute
  until Phase 7, and MSK removes broker patching/disk management. Swapping
  it later means a new module alongside `terraform/modules/msk/`, since
  consumers depend only on the bootstrap-broker string and security group.
- **Authentication:** SASL/IAM only, TLS in transit, KMS at rest. There is
  no plaintext listener and no SASL/SCRAM credential to rotate.
- **Schema registry:** AWS Glue Schema Registry (regional AWS API, optional
  private interface endpoint) — not a self-hosted service. Schemas are
  registered by the owning application repositories.
- **Topics:** declared in `scripts/messaging/topics.yaml` and created
  (create-only, never altered/deleted) by `scripts/messaging/apply-topics.sh`,
  each with `-retry` and `-dlq` companions. Topics are deliberately not
  Terraform resources.
- **Not yet implemented:** consumer-lag / DLQ-growth alerting (Phase 8),
  idempotency-safe DLQ replay tooling (blocked on an idempotency contract
  with the application repos), cross-region replication.

## Compute and edge (implemented in Phase 7)

- **Compute platform:** ECS on Fargate (not EC2) — see
  `terraform/modules/ecs/README.md` for why. No AMI pipeline or host
  fleet exists or is planned until/unless Fargate proves insufficient.
- **Edge:** Internet → Route 53 → WAFv2 → ALB (HTTPS, TLS 1.3 policy,
  HTTP→HTTPS redirect) → ECS target groups. Production has a real ACM
  certificate and DNS records; dev/staging run the ALB **HTTP-only**
  because neither owns a DNS zone to validate a certificate against (see
  `terraform/live/{dev,staging}/README.md`) — acceptable only because
  nothing is deployed behind them yet.
- **No application deployed yet.** Every environment's `ecs` module call
  has `services = {}`. Both ALB listeners return a fixed 503 placeholder
  response rather than pointing at a target group with nothing behind it.
  This document will be updated, honestly, once a real service exists —
  until then, "deployment model status" below still describes the actual
  state, not the intended one.
- **ALB access logs are not yet enabled** — see `terraform/modules/alb/README.md`
  for the cross-module bucket-policy conflict that deferred it to Phase 8/9.

## Recovery paths (planned, detailed in Phase 10)

```
Service failure → AZ failure → Database failure → Messaging failure → Region failure
```

Recovery Point Objective (RPO) and Recovery Time Objective (RTO) targets
per environment are defined in `disaster-recovery/` once that phase lands,
and are configurable rather than hard-coded.

## Deployment model status

**Current (as of Phase 7):** the compute platform exists (ECS on Fargate,
one cluster per environment, an ALB in front of it, WAF attached) but no
application service is deployed to it — `services = {}` in every
environment's `ecs` module call. Single-region only; "active-active" and
"active-passive" are both inapplicable until a second region exists (see
"Failure domains & availability" above). This section will be updated
again, honestly, once a real service is deployed — it will not claim
capabilities that don't yet exist.

ECS was chosen on Fargate rather than EC2 specifically so this repository
never needs an AMI-baking pipeline or host-patching automation; moving to
EKS later is possible without restructuring `terraform/modules/ecs/`'s
service-definition interface, per `terraform/modules/ecs/README.md`.
