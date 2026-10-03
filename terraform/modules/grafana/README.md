# grafana

Amazon Managed Grafana (AMG) workspace — **disabled by default**
(`create = false`).

## Why disabled by default

AMG's `AWS_SSO` authentication provider requires **IAM Identity Center**
(AWS SSO) to already be enabled for the AWS account/organization. That is
an account-level, often organization-wide setting with implications far
beyond this one project — not something a project-scoped Terraform
module should silently enable as a side effect of standing up a
dashboard. Confirm Identity Center is enabled (and that you're
comfortable with who it grants access to) before setting `create = true`.

## What this creates (when enabled)

- An IAM role for the workspace, scoped to read from AMP
  (`aps:QueryMetrics` and friends, resource-scoped to one workspace ARN)
  and CloudWatch (metrics/logs read, which don't support resource-level
  scoping, hence `resources = ["*"]` on that statement only).
- `aws_grafana_workspace` with `PROMETHEUS` and `CLOUDWATCH` data sources
  pre-authorized, `SERVICE_MANAGED` permissions (AMG manages its own
  internal RBAC), current-account access only.

## Example

```hcl
module "grafana" {
  source = "../../modules/grafana"

  project           = "PesaGuard"
  environment       = "production"
  create            = true # only after confirming IAM Identity Center is enabled
  amp_workspace_arn = module.amp.workspace_arn
}
```
