# Security Policy

## Reporting a vulnerability

If you discover a security vulnerability in this infrastructure repository
(misconfigured resources, exposed secrets, overly broad IAM policies,
insecure defaults in a Terraform module, etc.):

1. **Do not open a public GitHub issue.**
2. Email the maintainer directly at the address listed on the
   [repository owner's GitHub profile](https://github.com/Victor-Kipruto-Rop)
   with a description of the issue and, if possible, steps to reproduce.
3. You will receive an acknowledgement as soon as possible. Please allow
   time for a fix before any public disclosure.

## Secret handling

This repository must never contain:

- Passwords, access tokens, or API keys
- AWS access keys or long-lived credentials
- Private keys or certificates containing private material
- Database connection strings with embedded credentials
- Terraform state files (which can contain sensitive resource attributes)

Secrets are managed exclusively through **AWS Secrets Manager** and/or
**AWS SSM Parameter Store**, referenced from Terraform/Ansible/CI by ARN
or parameter name — never by value.

If a secret is accidentally committed:

1. Rotate/revoke the credential immediately, before cleaning git history.
2. Remove it from history (e.g. `git filter-repo`) and force-push.
3. Open a private report as above so the incident can be tracked.

## Supported versions

This repository targets the current `main` branch only. There are no
long-term-supported branches at this stage of the project.

## Infrastructure change security

- All infrastructure changes go through pull requests (see
  [CONTRIBUTING.md](./CONTRIBUTING.md)).
- CI runs static analysis (`tfsec`, `Checkov`, `Trivy`, `ShellCheck`, YAML
  and Terraform validation) once the corresponding workflows are added in
  later phases.
- Changes affecting the `production` environment require explicit
  approval and are never auto-applied from an arbitrary pull request.

## Dependency updates

Dependency and module version updates are tracked via Dependabot
(`.github/dependabot.yml`).
