# waf

A regional WAFv2 Web ACL associated with the ALB, providing:

- **Rate-based rule** — blocks a source IP once it exceeds
  `rate_limit_per_5min` requests in a rolling 5-minute window (AWS WAF's
  rate-based rules are always evaluated over a 5-minute window; that
  window is not configurable).
- **`AWSManagedRulesCommonRuleSet`** — AWS-managed protection against
  common injection/exploitation patterns (OWASP Top 10-ish coverage).
- **`AWSManagedRulesKnownBadInputsRuleSet`** — AWS-managed protection
  against known-malicious request patterns (log4j-style exploit strings,
  etc.).
- **Logging** to a CloudWatch Logs group this module creates and owns,
  named `aws-waf-logs-<project>-<environment>` — AWS **requires** the
  `aws-waf-logs-` prefix for WAF log destinations, so the group is created
  here rather than accepted as a variable, to make that requirement
  impossible to violate by misconfiguration.

## What this does NOT do

- **Authentication.** WAF filters request patterns; it has no concept of
  "is this caller allowed to call this API." Application-level auth is
  unaffected by and not a substitute for this module (see
  `../../../ARCHITECTURE.md` — rate limiting exists at multiple layers).
- **Per-endpoint policy.** All rules apply uniformly to everything behind
  the ALB in this phase. Differentiated policy (stricter limits on
  `/auth/*`, looser on public read endpoints) is a real candidate for a
  later hardening pass, not implemented now.
- **Bot control / fraud rule groups.** AWS's paid managed rule groups
  (Bot Control, Account Takeover Prevention) are not enabled — evaluate
  cost/benefit before adding them; this module's `rule` blocks are the
  place to add them.

## Example

```hcl
module "waf" {
  source = "../../modules/waf"

  project          = "PesaGuard"
  environment      = "production"
  alb_arn          = module.alb.alb_arn
  logs_kms_key_arn = module.kms.logs_key_arn
}
```
