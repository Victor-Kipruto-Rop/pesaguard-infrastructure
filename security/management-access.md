# Management access

## No public SSH

This repository does not create a bastion host or any security group rule
that opens SSH (port 22) from the internet — see
`terraform/modules/security-groups/README.md`. Every EC2-based role
created in `terraform/modules/iam/` attaches
`AmazonSSMManagedInstanceCore`, so administrators use **AWS Systems
Manager Session Manager** instead:

```bash
aws ssm start-session --target <instance-id>
```

Benefits over SSH:

- No inbound port to expose, patch, or forget to close.
- Every session is logged to CloudTrail and (optionally) to an S3/
  CloudWatch Logs session log — auditable by default.
- Access is controlled entirely by IAM (`ssm:StartSession` policy),
  so revoking a person's AWS access revokes their instance access too;
  no separate SSH key lifecycle to manage.
- Works even when an instance has no public IP (all of this repo's
  app/data-tier instances are in private subnets — see
  `terraform/modules/networking/`).

If a genuine future need for SSH arises (e.g. a tool that only works over
SSH), create a dedicated `bastion` security group scoped to specific
source IPs and a specific purpose — do not add SSH access to the shared
`app` security group, and do not reuse an existing role for it.

## IAM / OIDC summary

- Human AWS console/CLI access should go through SSO or IAM roles with
  MFA — this repository does not provision human IAM users.
- CI/CD (GitHub Actions) authenticates via OIDC federation
  (`terraform/modules/iam` — `aws_iam_openid_connect_provider`), not
  long-lived AWS access keys. The trust policy restricts which GitHub
  repository and ref (branch) may assume the Terraform CI role.
- See `terraform/modules/iam/README.md` for the full role list and what
  each one can and cannot do.

## Secrets

Administrators needing to set or rotate a real secret value (the
Secrets Manager containers created by `terraform/modules/secrets/` hold
placeholders only) use the AWS Console or CLI directly:

```bash
aws secretsmanager put-secret-value \
  --secret-id PesaGuard/development/database/credentials \
  --secret-string '{"username":"...","password":"..."}'
```

This requires `secretsmanager:PutSecretValue` on that specific secret ARN
— scope who has that permission carefully; see
`terraform/modules/secrets/README.md`.
