# Terraform layout

```
terraform/
├── bootstrap/     # Creates the remote state backend itself (S3 + DynamoDB).
│                  # Implemented in Phase 2. Uses LOCAL state — see bootstrap/README.md.
│
├── modules/       # Reusable, environment-agnostic building blocks
│                  # (networking, iam, rds, redis, kafka, ecs, ...).
│                  # Populated starting Phase 3. Each module: main.tf,
│                  # variables.tf, outputs.tf, versions.tf, README.md.
│                  # No environment-specific values are hard-coded here.
│
├── stacks/        # Compositions of modules grouped by concern (core,
│                  # data, compute, messaging, observability, security,
│                  # edge). Populated as the corresponding phase lands.
│
└── live/          # Per-environment root configurations that instantiate
    ├── dev/        stacks with that environment's variables and remote
    ├── staging/    state backend (environments/<env>/backend.hcl).
    └── production/ Populated as stacks are built.
```

## Why `bootstrap/` is separate

Terraform needs somewhere to store its state before it can manage the
S3 bucket + DynamoDB table that normally *hold* that state — a
chicken-and-egg problem. `terraform/bootstrap/` solves this by using
local state (intentionally, see `terraform/bootstrap/README.md`) to
create the remote-state infrastructure once per environment. Everything
under `terraform/live/` then uses that remote backend via
`environments/<env>/backend.hcl`.

## Conventions (all modules/stacks/live configs)

- `terraform fmt` and `terraform validate` must pass (`make fmt`,
  `make validate`).
- No environment-specific values hard-coded into a reusable module —
  pass them as variables from `terraform/live/<env>`.
- Every resource carries the standard tag set from
  [../ARCHITECTURE.md](../ARCHITECTURE.md#standard-resource-tags).
- `required_version` and `required_providers` are pinned in
  `versions.tf`, not scattered across `main.tf`.
