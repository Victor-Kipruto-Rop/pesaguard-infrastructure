# acm

A DNS-validated ACM certificate, with validation records created
automatically in the given Route 53 zone.

## Requires an existing zone

This module does not create a Route 53 zone — pass `zone_id` from
`terraform/modules/dns/`. Since only `production` creates the apex zone
(see `terraform/modules/dns/README.md`), only `production` currently has
a `zone_id` to pass here. Dev/staging do not get a certificate from this
module in this phase (see `terraform/live/{dev,staging}/README.md` — they
run the ALB HTTP-only for now).

## Output ARN is the validated one

`certificate_arn` comes from `aws_acm_certificate_validation`, not the
raw `aws_acm_certificate` — so anything consuming this output (the `alb`
module's HTTPS listener) implicitly waits for DNS validation to complete
before it can be created, rather than racing it.

## Example

```hcl
module "acm" {
  source = "../../modules/acm"

  project     = "PesaGuard"
  environment = "production"
  domain_name = var.domain_name
  subject_alternative_names = [
    "api.${var.domain_name}",
    "app.${var.domain_name}",
  ]
  zone_id = module.dns.zone_id
}
```
