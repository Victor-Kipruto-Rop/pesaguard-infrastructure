# Changelog

All notable changes to this infrastructure repository are documented here,
grouped by implementation phase. This log reflects what has actually been
implemented and validated — not what is planned (see README.md for the
phase roadmap).

## [Unreleased] — Phase 1: Repository Foundation

### Added
- Repository scaffolding: `README.md`, `LICENSE` (MIT), `SECURITY.md`,
  `CONTRIBUTING.md`, `ARCHITECTURE.md`, this `CHANGELOG.md`.
- `.gitignore`, `.dockerignore`, `.editorconfig`.
- `Makefile` with initial targets (`help`, `fmt`, `validate`, `lint`,
  `clean`) — infrastructure-provisioning targets (`plan`, `apply`,
  `dr-test`, etc.) are added starting in Phase 2 as the corresponding
  tooling lands, so they are documented rather than stubbed.
- GitHub repository configuration: `.github/CODEOWNERS`,
  `.github/dependabot.yml`, issue templates for infrastructure changes,
  incidents, and security reports.

### Not yet implemented
- Terraform modules, environments, and remote state (Phase 2)
- Networking (VPC, subnets, security groups, DNS) (Phase 3)
- IAM, KMS, Secrets Manager (Phase 4)
- Data infrastructure: RDS, Redis, S3, backups (Phase 5)
- Messaging: Kafka/Redpanda, Schema Registry, DLQ (Phase 6)
- Compute: ECS/EC2/EKS, load balancing, autoscaling (Phase 7)
- Observability: Prometheus, Grafana, OpenTelemetry, alerting (Phase 8)
- CI/CD workflows for plan/apply/security scanning/drift detection (Phase 9)
- Backup and disaster recovery automation (Phase 10)
- Production hardening review (Phase 11)

### Requires manual configuration (once relevant phases land)
- AWS account(s) and IAM bootstrap credentials for Terraform
- Domain registration/delegation for `victorkipruto.com` subdomains in
  Route 53
- AWS Secrets Manager values (no secrets are ever committed to this repo)
