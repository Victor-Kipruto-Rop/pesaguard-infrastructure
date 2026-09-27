# Security documentation

This directory holds infrastructure-facing security policy and hardening
guidance — not incident response (see [../INCIDENT-RESPONSE.md](../INCIDENT-RESPONSE.md),
added in a later phase) and not vulnerability reporting (see
[../SECURITY.md](../SECURITY.md)).

| Document | Covers |
|---|---|
| [management-access.md](./management-access.md) | Why SSH is not used, how administrative access works (SSM Session Manager), IAM/OIDC summary |
| [host-hardening.md](./host-hardening.md) | EC2 hardening checklist for when Phase 7 introduces EC2-based compute |
| [container-security.md](./container-security.md) | Container security requirements for when Phase 6/7 introduce Docker images and container deployment |

Encryption (KMS), IAM policy design, and secrets handling are documented
alongside the Terraform that implements them:
[terraform/modules/kms/README.md](../terraform/modules/kms/README.md),
[terraform/modules/iam/README.md](../terraform/modules/iam/README.md),
[terraform/modules/secrets/README.md](../terraform/modules/secrets/README.md).

Network segmentation (security groups, subnet tiers) is documented in
[terraform/modules/security-groups/README.md](../terraform/modules/security-groups/README.md)
and [terraform/modules/networking/README.md](../terraform/modules/networking/README.md).

Subdirectories such as `policies/`, `waf/`, `threat-detection/`, and
`compliance/` are added when the corresponding phase actually implements
something there (WAF in Phase 7, GuardDuty/Security Hub in a hardening
pass) — this repository does not create empty policy folders ahead of
having real policy to put in them.
