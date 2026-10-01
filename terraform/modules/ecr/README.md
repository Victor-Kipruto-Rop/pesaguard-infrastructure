# ecr

Container registries for the images application repositories build and
push. This module only reserves the registry location and its scan/
lifecycle policy — it never builds, pushes, or defines what's inside an
image (that's the application repositories' CI, not this one).

## What this creates

- One `aws_ecr_repository` per entry in `repository_names` (default:
  `fastapi-service`, `java-service`, `worker`), named
  `<project>/<environment>/<name>` (lowercase).
- `image_tag_mutability = "IMMUTABLE"` — no repository in this registry
  accepts a re-pushed tag (no floating `:latest`), matching
  `security/container-security.md`'s "immutable, versioned tags"
  requirement at the registry level, not just by convention.
- Scan-on-push enabled for every repository.
- A lifecycle policy: untagged images expire after
  `untagged_image_expiry_days` (default 14); tagged images beyond the
  most recent `tagged_image_keep_count` (default 20, matched against tags
  prefixed `v`, `sha-`, or `release-`) also expire.

## Push access

Grant `ecr:GetAuthorizationToken` (account-wide, that action doesn't
support resource scoping) plus `ecr:BatchCheckLayerAvailability`,
`ecr:PutImage`, `ecr:InitiateLayerUpload`, `ecr:UploadLayerPart`,
`ecr:CompleteLayerUpload` scoped to `repository_arns` — to the CI/CD
identity that builds application images (an application repo's own
OIDC-federated role, not necessarily `terraform_ci` from this repo, since
that role manages infrastructure, not application image builds).

## Example

```hcl
module "ecr" {
  source = "../../modules/ecr"

  project     = "PesaGuard"
  environment = "production"
}
```
