# Changelog

All notable changes to this infrastructure repository are documented here,
grouped by implementation phase. This log reflects what has actually been
implemented and validated — not what is planned (see README.md for the
phase roadmap).

## [Unreleased] — Phase 3: Networking

### Added
- `terraform/modules/networking/` — VPC (`/16`), public/app/data subnets
  across N AZs (CIDR math via `cidrsubnet`), Internet Gateway, NAT
  gateway(s) (single shared or one-per-AZ via `single_nat_gateway`), route
  tables (public → IGW, app → NAT per AZ, data → no internet route), S3 +
  DynamoDB gateway VPC endpoints, VPC flow logs to CloudWatch with a
  scoped IAM role.
- `terraform/modules/security-groups/` — least-privilege SGs for ALB, app
  tier, PostgreSQL, Redis, Kafka/Schema Registry, and monitoring,
  referencing each other by security group ID rather than CIDR blocks for
  all internal traffic. No bastion SG — SSM Session Manager is the
  documented path for admin access.
- `terraform/modules/dns/` — Route 53 public hosted zone only (no records
  yet — see the module README for why records wait until Phase 7).
- `terraform/live/{dev,staging,production}/` — root configs instantiating
  the above: dev/staging use a single shared NAT gateway, production uses
  one per AZ and owns the DNS zone.
- `environments/{dev,staging,production}/terraform.tfvars.example` updated
  with real `vpc_cidr`, `availability_zones`, and (production) `domain_name`
  / `create_dns_zone` values.

### Not yet implemented
- No compute, load balancer, or DNS records — nothing yet answers on any
  of these VPCs' subnets (Phase 7).
- No IAM roles beyond the flow-logs role, no KMS, no Secrets Manager
  (Phase 4).
- No RDS/Redis/Kafka (Phase 5/6) — the data-tier subnets and their
  security group exist, but nothing runs in them yet.

### Requires manual action / AWS credentials
- Applying any `terraform/live/<env>` config requires AWS credentials and
  `terraform/bootstrap` already applied for that environment.
- Production's `terraform/live/production` apply additionally requires
  `CONFIRM=yes` and, per `CONTRIBUTING.md`, a second reviewer.
- If `production`'s DNS zone is created, the domain must be delegated at
  the registrar to the zone's name servers (see `terraform/live/production/README.md`).

## [Unreleased] — Phase 2: Terraform Foundation

### Added
- `terraform/bootstrap/` — a real, working Terraform module that creates
  the remote state backend (S3 bucket with versioning + encryption +
  public-access-blocked, DynamoDB lock table with point-in-time recovery)
  for one environment at a time. Uses local state intentionally (see
  `terraform/bootstrap/README.md` for why, and the backup implication).
- `terraform/README.md` documenting the `bootstrap/ modules/ stacks/
  live/` layout and module conventions.
- `environments/{dev,staging,production}/README.md`,
  `terraform.tfvars.example`, and `backend.hcl.example` for all three
  environments.
- `Makefile`: real `plan` / `apply` / `destroy` targets parameterized by
  `DIR` and `ENV`, with production requiring `CONFIRM=yes` on `apply`,
  and `destroy` always requiring `CONFIRM=yes`.
- `.gitignore` updated so `backend.hcl` and `terraform.tfvars` (the real,
  filled-in files) are never committed, while their `.example` templates
  are tracked.

### Not yet implemented
- No `terraform/modules/` (networking, IAM, RDS, etc.) — Phase 3+.
- No `terraform/live/<env>/` root configs — nothing to plan/apply yet
  beyond `bootstrap`.
- CI has no Terraform validation workflow yet (Phase 9); `make validate`
  works locally if the `terraform` CLI is installed.

### Requires manual action
- Run `terraform/bootstrap` once per environment (requires AWS
  credentials) before any remote-backend Terraform can be used.
- Back up each environment's `terraform/bootstrap/terraform.tfstate`
  manually — see `terraform/bootstrap/README.md`.

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
