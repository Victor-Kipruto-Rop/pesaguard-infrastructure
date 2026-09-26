# PesaGuard Infrastructure

Infrastructure and control-plane repository for PesaGuard.

This repository owns cloud infrastructure, networking, compute, databases,
messaging, secrets, observability, deployment automation, backups, and
disaster recovery for the PesaGuard platform.

It does **not** contain application business logic. Application code
(FastAPI services, Java microservices, frontends, the developer portal)
lives in their own repositories and consumes the infrastructure defined
here.

## Scope

| This repo owns | This repo does NOT own |
|---|---|
| VPC, subnets, routing, DNS | FastAPI application code |
| IAM, KMS, Secrets Manager | Java microservice business logic |
| RDS PostgreSQL, Redis, S3 | Fraud-detection algorithms |
| Kafka/Redpanda, Schema Registry infra | Reconciliation business rules |
| ECS/EC2/EKS compute platform | Frontend/UI code |
| Load balancing, WAF, TLS | Developer portal application |
| Observability stack (metrics/logs/traces/alerts) | Application SQL migrations |
| Backups & disaster recovery | |
| CI/CD infrastructure & deployment policy | |

## Cloud target

- **Primary cloud:** AWS
- **Primary region:** `us-east-1`
- **Multi-region:** not yet implemented; the module structure is designed
  so a second region can be added without restructuring the repo (see
  [ARCHITECTURE.md](./ARCHITECTURE.md)).

## Environments

- `development`
- `staging`
- `production`

Each environment has isolated Terraform state, configuration, secrets, and
(where practical) IAM permissions. See `environments/<env>/README.md`
(added in Phase 2) for details.

## Repository status

This repository is being built in phases so that every directory contains
real, working content rather than empty placeholders. Current status:

- [x] Phase 1 — Repository foundation (this commit)
- [ ] Phase 2 — Terraform foundation
- [ ] Phase 3 — Networking
- [ ] Phase 4 — IAM & security
- [ ] Phase 5 — Data infrastructure
- [ ] Phase 6 — Messaging
- [ ] Phase 7 — Compute
- [ ] Phase 8 — Observability
- [ ] Phase 9 — Deployment automation
- [ ] Phase 10 — Backup & disaster recovery
- [ ] Phase 11 — Production hardening

See [CHANGELOG.md](./CHANGELOG.md) for what has actually landed, and
[ARCHITECTURE.md](./ARCHITECTURE.md) for the target design.

## Getting started (local development)

Local development tooling is introduced starting in Phase 2/7 (Docker
Compose for infra dependencies). Until then:

```bash
make help
```

lists the commands currently implemented in the [Makefile](./Makefile).

## Documentation

- [ARCHITECTURE.md](./ARCHITECTURE.md) — target system architecture
- [SECURITY.md](./SECURITY.md) — vulnerability reporting & secret handling
- [CONTRIBUTING.md](./CONTRIBUTING.md) — how to propose infrastructure changes
- [CHANGELOG.md](./CHANGELOG.md) — what has been implemented, phase by phase

## License

See [LICENSE](./LICENSE).
