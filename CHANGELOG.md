# Changelog

All notable changes to this infrastructure repository are documented here,
grouped by implementation phase. This log reflects what has actually been
implemented and validated — not what is planned (see README.md for the
phase roadmap).

## [Unreleased] — Phase 8: Observability

### Added
- `terraform/modules/sns-alerts/` — one SNS topic per alert category
  (infrastructure, database, messaging, application, security), KMS
  encrypted, with a resource policy allowing only CloudWatch Alarms and
  AMP's Alertmanager to publish. **No subscriptions created** — see
  README.md for why that's a deliberate, required manual step.
- `terraform/modules/cloudwatch-alarms/` — golden-signal alarms using
  metrics AWS already publishes for RDS (CPU/storage/connections), Redis
  (per-node CPU/memory — ElastiCache publishes per cache-cluster, not per
  replication group), MSK (`ActiveControllerCount`,
  `OfflinePartitionsCount`), ALB (5xx count, target response time), and
  WAF (blocked-request spike). Works immediately, unlike AMP, since these
  metrics flow natively with no exporter needed.
- `terraform/modules/amp/` — Amazon Managed Prometheus workspace, a
  starter alert rule (`TargetDown`, the one rule meaningful without
  knowing real metric names), and an Alertmanager definition using AMP's
  native `sns_configs` receiver (no self-hosted Alertmanager). Explicitly
  documented as receiving no data yet.
- `terraform/modules/grafana/` — Amazon Managed Grafana, **disabled by
  default** (`create = false`) because `AWS_SSO` auth requires IAM
  Identity Center already enabled account-wide — not something this
  module will silently turn on.
- `redis` module: new `member_cluster_ids` output (ElastiCache alarms are
  per-node). `alb` module: new `alb_arn_suffix` output (the CloudWatch
  dimension form, not the full ARN).
- `iam` module: `enable_observability_access` flag granting
  `aps:RemoteWrite` (scoped to one AMP workspace) and X-Ray write actions
  (not resource-scopable — AWS limitation) to `app_service`, ready for a
  future OTel/ADOT sidecar that does not exist yet.
- `terraform/live/{dev,staging,production}/` wired with all four new
  modules.

### Fixed
- **`terraform_ci` had no permissions for any Phase 7 service** (ECS,
  ECR, ALB, WAF, ACM) — a gap introduced in Phase 7 and only caught now.
  Rather than keep growing the single Phases-1-6 inline policy toward
  IAM's 10,240-character limit, Phase 7 and Phase 8 permissions now live
  in a **second** inline policy (`terraform_ci_phase_7_8`) on the same
  role. Both are currently ~5.4 KB and ~1.7 KB respectively — comfortable
  headroom, and a pattern (split early, don't wait for the limit) that
  should continue if a third policy is ever needed.

### Not yet implemented
- Nothing remote-writes to AMP (no OTel/ADOT sidecar — see
  `terraform/modules/amp/README.md`); the workspace and starter rule
  exist but see no data.
- No ECS/application-level CloudWatch alarms (nothing deployed — Phase 7).
- No log aggregation beyond CloudWatch Logs Insights; no distributed
  tracing.
- Consumer-lag / DLQ-growth alerting (still blocked on the same thing
  noted in `scripts/messaging/README.md` since Phase 6).

### Requires manual action
- **Subscribe someone to every SNS topic** — alarms exist but are
  currently silent. See `terraform/modules/sns-alerts/README.md`.
- Confirm IAM Identity Center is enabled before setting `grafana`'s
  `create = true`.
- AMP/Grafana resource names, the `sns_configs` Alertmanager receiver
  schema, and the ElastiCache/MSK CloudWatch dimension names used here
  have not been validated against a real AWS account from this
  environment (no credentials or `terraform` CLI here) — confirm on
  first `plan`.

## [Unreleased] — Phase 7: Compute

### Added
- `terraform/modules/ecr/` — container registries (`fastapi-service`,
  `java-service`, `worker`), immutable tags, scan-on-push, a lifecycle
  policy (expire untagged after N days, keep the most recent N tagged).
- `terraform/modules/acm/` — DNS-validated ACM certificate; validation
  records written into the `dns` module's zone automatically. The output
  ARN is the *validated* certificate, so consumers implicitly wait on
  validation.
- `terraform/modules/alb/` — internet-facing ALB. HTTPS (TLS 1.3 policy)
  with HTTP→HTTPS redirect when a certificate is provided; HTTP-only
  otherwise. **No target group yet** — both listeners return a fixed 503
  JSON placeholder response rather than pointing at nothing, until a real
  service exists.
- `terraform/modules/waf/` — WAFv2 Web ACL on the ALB: a rate-based rule
  plus the AWS-managed Common and Known-Bad-Inputs rule groups, logged to
  a CloudWatch group this module owns (AWS requires the `aws-waf-logs-`
  name prefix, so the module creates the log group itself rather than
  accepting one as a variable).
- `terraform/modules/ecs/` — ECS cluster (Fargate + Fargate Spot capacity
  providers) and a fully reusable per-service pattern (task definition,
  target group, listener rule, service, CPU-based autoscaling) behind a
  `services` map that defaults to `{}`. Two IAM roles per deployment: an
  execution role this module creates (ECS agent: pull image, write logs,
  fetch only the secrets referenced by `services`) and the existing
  `app_service` role from `terraform/modules/iam/`, reused as the task
  role application code runs as.
- `terraform/modules/dns/` — ALB ALIAS record support
  (`create_alb_records`, `alb_record_names`), with a `local.zone_id` that
  works whether this instance created the zone or was told to reuse one.
- `terraform/live/production/` additionally gets a **second instance** of
  the `dns` module (`module.dns_records`) to write the ALB alias records,
  specifically to avoid a `dns → alb → acm → dns` dependency cycle that a
  single combined instance would create.
- `terraform/live/{dev,staging}/` get `ecr`, `alb` (HTTP-only — no zone to
  validate a cert against), `waf`, and `ecs`; `production` additionally
  gets `acm` and the DNS alias records.

### Changed
- `security-groups`: no change to the kafka ports from Phase 6, but this
  phase's `ecs` module README documents that any service port other than
  the pre-opened `app_port` needs a security-groups change too.

### Not yet implemented
- No real application service in any environment — `services = {}`
  everywhere (see `terraform/modules/ecs/README.md`). Both ALB listeners
  serve a placeholder 503 response.
- ALB access logging (deferred — would conflict with
  `object-storage`'s existing bucket policy on the same bucket; see
  `terraform/modules/alb/README.md`).
- Dev/staging have no TLS (HTTP-only) because neither owns a DNS zone.
- Any CloudWatch alarms on ECS/ALB/WAF metrics (Phase 8).
- EC2/EKS compute paths (Fargate only, by deliberate choice — see
  `terraform/modules/ecs/README.md`).

### Requires manual action / AWS credentials
- `kafka_version` (`3.7.x`), MSK/ECS instance types, and ACM/Route53
  interactions have still not been validated against a real AWS account
  from this environment (no AWS credentials or `terraform` CLI here).
- Populating `terraform/modules/ecs/`'s `services` map with a real image
  requires an image already pushed to `ecr`'s output repository URL.

## [Unreleased] — Phase 6: Messaging

### Added
- `terraform/modules/msk/` — Amazon MSK cluster: IAM-only client auth
  (no plaintext, no SASL/SCRAM secrets), TLS in transit, KMS at rest
  (new `messaging` key), broker logs to CloudWatch (logs key), enhanced
  monitoring, and a broker config with `auto.create.topics.enable=false`
  and `unclean.leader.election.enable=false`.
- `terraform/modules/glue-schema-registry/` — AWS Glue Schema Registry
  (registry container only; schemas are registered by application repos)
  plus an optional private interface VPC endpoint with its own
  security group.
- `terraform/modules/kms/` — fifth key, `messaging`.
- `scripts/messaging/topics.yaml` + `apply-topics.sh` — 8 primary topics,
  each with `-retry` and `-dlq` companions (24 total). Dry run by
  default (`APPLY=yes` required), create-only (`--if-not-exists`; never
  alters or deletes a topic), DLQ retention never shorter than its
  primary, `REPLICATION_FACTOR_CAP` for clusters with fewer than 3
  brokers. ShellCheck clean; exercised in dry-run and missing-prereq
  paths only.
- `terraform/modules/iam/` — `app_service` gets MSK data-plane access
  (Connect/Describe/Read/Write/consumer groups — deliberately **no**
  Create/Delete/AlterTopic) and Glue registry access scoped to one
  registry, behind boolean flags (`enable_msk_access`,
  `enable_glue_registry_access`) because the ARNs are unknown at plan time
  and cannot gate a `for_each`.
- `terraform_ci` policy extended to cover the services Phases 5 and 6
  introduced (S3 buckets, RDS, ElastiCache, MSK, Glue registry, KMS grants
  scoped by key alias, service-linked roles). **This was a gap since
  Phase 5**: before this change CI could not have applied RDS/Redis/S3.
- `terraform/live/{dev,staging,production}/` wired with both modules;
  per-env broker sizing in `environments/*/terraform.tfvars.example`
  (dev/staging 2 brokers, production 3).

### Changed
- `security-groups`: `kafka_ports` default is now `[9098]` (MSK TLS+IAM)
  instead of placeholder ports `[9092, 9093]`; the Schema Registry ingress
  rule was removed (`schema_registry_port` is now unused — Glue is an AWS
  API, not a port on this group).
- Removed a broken doc link in `terraform/modules/iam/README.md`
  (`security/policies/host-hardening.md` -> `security/host-hardening.md`).
- Fixed `terraform/live/production/README.md`, which had silently missed
  the Phase 4 and Phase 5 module list updates.

### Not yet implemented
- Consumer-lag and DLQ-growth alerting (Phase 8).
- DLQ replay tooling. Replaying financial events without an agreed
  idempotency contract risks duplicate transactions, so this is
  intentionally not written yet.
- Cross-region replication; multi-VPC/cross-account client access.
- Any test against a live MSK cluster or real AWS account.

### Requires manual action / AWS credentials
- Topic creation needs a host with network access to the private subnets
  (use SSM Session Manager) and a Kafka distribution with `kafka-topics.sh`
  plus the `aws-msk-iam-auth` library; use an operator role, not the
  runtime `app_service` role.
- Dev/staging: run `apply-topics.sh` with `REPLICATION_FACTOR_CAP=2`.
- MSK and Glue version strings / instance types have **not** been
  validated against the AWS API — confirm `3.7.x` and the broker instance
  type are available in your region on first `plan`.
- `terraform_ci` is untested against a real apply; expect to add a missing
  action on first run. It is roughly half of the 10,240-character inline
  policy limit — later phases (compute, edge) should split it into
  multiple policies rather than grow this one.

## [Unreleased] — Phase 5: Data Infrastructure

### Added
- `terraform/modules/object-storage/` — S3 buckets (`backups`, `artifacts`,
  `logs` by default), each with versioning, SSE-KMS (the `backups` key),
  full public-access block, a deny-insecure-transport bucket policy, and
  lifecycle expiration of old versions.
- `terraform/modules/rds/` — RDS PostgreSQL: gp3 encrypted storage with
  autoscaling, `manage_master_user_password = true` (RDS/Secrets Manager
  owns the master credential — Terraform never sees or sets it),
  automated backups + PITR, Performance Insights, PostgreSQL log export,
  `rds.force_ssl` enforced via a custom parameter group.
- `terraform/modules/redis/` — ElastiCache Redis replication group:
  at-rest + in-transit encryption, a Terraform-generated AUTH token
  stored in a secret this module owns, configurable node count /
  automatic failover.
- `terraform/live/{dev,staging,production}/` wired to instantiate all
  three, plus updated `iam` module calls so `app_service`'s secret/S3
  permissions cover the new RDS master-password secret, the Redis
  auth-token secret, and the new S3 buckets.
- `environments/*/terraform.tfvars.example` updated: `secret_names`
  trimmed to just `kafka/credentials` (database and Redis credentials are
  now self-managed by their own modules, avoiding a Secrets Manager name
  collision), plus per-environment RDS/Redis sizing (dev: single-AZ
  `db.t4g.micro` / 1-node Redis; staging: single-AZ, one size up;
  production: Multi-AZ `db.r6g.large`, deletion-protected, 2-node Redis
  with automatic failover).

### Not yet implemented
- No Kafka/Redpanda or Schema Registry (Phase 6).
- No compute (Phase 7) — nothing yet connects to these databases.
- No CloudWatch alarms on RDS/Redis metrics (deferred to Phase 8 so
  alerting has somewhere real to send notifications, rather than SNS
  topics with no subscriber).
- No automated, tested restore drill (Phase 10) — the RPO/RTO figures in
  `terraform/modules/rds/README.md` are AWS platform defaults, not yet
  measured for this project.

### Requires manual action / AWS credentials
- Applying any `terraform/live/<env>` config now provisions billable
  resources (RDS, ElastiCache, S3) — review `terraform plan` output
  carefully, especially for production.
- After first apply, verify RDS/Redis credentials are reachable only via
  their respective Secrets Manager ARNs by the `app_service` role — no
  credential is ever written to a Terraform output value in plaintext.

## [Unreleased] — Phase 4: IAM & Security

### Added
- `terraform/modules/kms/` — four KMS keys (secrets, logs, backups,
  database), each with rotation enabled, an alias, and a policy granting
  the account root plus optional named administrators; the logs key
  additionally grants the CloudWatch Logs service principal, scoped by
  encryption-context condition to this project/environment's log groups.
- `terraform/modules/iam/` — GitHub Actions OIDC provider (created once,
  by production; other environments reference its ARN), a `terraform_ci`
  role scoped to what this repo's modules currently manage (state
  bucket/lock table, networking, Route 53, KMS, IAM under the project
  prefix, Secrets Manager under the project/environment prefix,
  CloudWatch Logs under `/pesaguard/<env>/*`), an `app_service` role +
  instance profile (SSM-only admin access, secrets/log/metric
  permissions), a `monitoring` role + instance profile (read-only), and a
  `backup_operator` role (RDS snapshot + KMS permissions).
- `terraform/modules/secrets/` — Secrets Manager containers for
  database/redis/kafka credentials, encrypted with the KMS secrets key.
  Terraform writes a random placeholder value once (so the secret isn't
  left unusable) and then ignores further changes to it — real values are
  always set out-of-band, never generated from or committed to this repo.
- `terraform/live/{dev,staging,production}/` wired to instantiate `kms`,
  `secrets`, and `iam` (production also sets `create_oidc_provider = true`
  since it owns the account-wide OIDC provider).
- `security/` — `management-access.md` (why no SSH; SSM Session Manager;
  OIDC summary), `host-hardening.md` (EC2 checklist for Phase 7),
  `container-security.md` (image/container checklist for Phase 6/7).
- `environments/*/terraform.tfvars.example` updated with `github_org`,
  `github_repo`, `allowed_github_refs`, `secret_names`.

### Not yet implemented
- No RDS/Redis/Kafka to actually attach these keys/roles/secrets to yet
  (Phase 5/6) — the IAM policies reference resource-name patterns those
  phases will create, not real ARNs.
- No compute (Phase 7) — the `app_service`/`monitoring` instance profiles
  exist but nothing assumes them yet.
- `terraform_ci`'s policy will need expanding as later phases add
  services it must manage (RDS, ElastiCache, ECS, etc.) — it is
  intentionally scoped to Phases 1–4 only right now, not a blanket
  `AdministratorAccess`.
- No GuardDuty/Security Hub/Config (left for a later hardening pass —
  see Phase 11 in the README roadmap).

### Requires manual action
- Apply `terraform/live/production` first (or at least its `iam` module)
  to create the GitHub OIDC provider before dev/staging's CI roles are
  usable — then copy production's `oidc_provider_arn` output into
  dev/staging's `existing_oidc_provider_arn` variable.
- Set real values in every Secrets Manager container created here (AWS
  Console or CLI — see `security/management-access.md`); Terraform never
  writes a real credential.

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
