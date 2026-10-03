# sns-alerts

One SNS topic per alert category (default: `infrastructure`, `database`,
`messaging`, `application`, `security`), KMS-encrypted, with a resource
policy allowing CloudWatch Alarms and AMP's Alertmanager to publish —
nothing else.

## No subscriptions are created here

Who gets paged is an operational decision this repository cannot make on
the project's behalf (a person's email, a team's Slack webhook, a
PagerDuty integration key — none of these belong in version control as
plain Terraform values, and guessing wrong means alerts silently go
nowhere). Subscribe manually per topic:

```bash
aws sns subscribe \
  --topic-arn <topic_arns["database"]> \
  --protocol email \
  --notification-endpoint oncall@example.com
```

or add subscription endpoints via a separate, environment-specific
Terraform configuration that isn't checked in (or is checked in with
real, reviewed values once the project has a real on-call destination).
**An alarm with no subscriber is silent** — treat adding subscriptions as
a required manual step after first `apply`, not an optional one.

## Example

```hcl
module "sns_alerts" {
  source = "../../modules/sns-alerts"

  project     = "PesaGuard"
  environment = "production"
  kms_key_arn = module.kms.secrets_key_arn
}
```
