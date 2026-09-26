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
         Internal services       Kafka/Redpanda
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
Kafka/Redpanda → consumer → database → notification
```

Trace ID / span ID / correlation ID / request ID are propagated across
this flow (OpenTelemetry, Phase 8). Sensitive financial data is never
placed in tracing attributes or logs.

## Recovery paths (planned, detailed in Phase 10)

```
Service failure → AZ failure → Database failure → Messaging failure → Region failure
```

Recovery Point Objective (RPO) and Recovery Time Objective (RTO) targets
per environment are defined in `disaster-recovery/` once that phase lands,
and are configurable rather than hard-coded.

## Deployment model status

**Current:** not yet implemented — no compute, no deployed workloads.

**Planned Phase 7+:** ECS/EC2 as the initial compute strategy, with the
module boundaries designed so a future move to EKS/Kubernetes does not
require restructuring the repository. This document will be updated to
state plainly whether active-active or active-passive is actually
implemented once that work lands — it will not claim capabilities that
don't yet exist.
