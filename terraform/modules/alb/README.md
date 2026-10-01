# alb

An internet-facing Application Load Balancer in the public subnets, with
no application attached yet.

## Why it has no target group

No real application image or service exists in this repository yet (see
the root `README.md` boundary rules — application code lives elsewhere).
Rather than wire up a target group pointing at nothing, or a placeholder
service pretending to be real, both listeners default to a **fixed
503 JSON response** (`{"error": "no_application_deployed", ...}`) until
Phase 9 CI/CD (or whoever deploys the first real ECS service) adds a
listener rule and target group via `terraform/modules/ecs/`.

## HTTP vs HTTPS

- If `certificate_arn` is set (production, via `terraform/modules/acm/`):
  the HTTP listener (port 80) 301-redirects to HTTPS; the HTTPS listener
  (port 443, TLS 1.3-capable policy `ELBSecurityPolicy-TLS13-1-2-2021-06`)
  serves the placeholder response.
- If `certificate_arn` is empty (dev/staging currently — see
  `terraform/live/{dev,staging}/README.md`, since only production owns a
  DNS zone to validate a certificate against): the ALB is **HTTP-only**.
  This is acceptable only because nothing is deployed behind it yet and
  no DNS record points at it publicly. Do not extend this HTTP-only mode
  to a real deployed service — get dev/staging a certificate (e.g. a
  subdomain of production's zone) before deploying anything real to them.

## Access logs: not yet enabled

See the comment in `main.tf` — enabling ALB access logs means adding an
S3 bucket policy statement that would conflict with the one
`terraform/modules/object-storage/` already manages on the same bucket.
Deferred to Phase 8/9 rather than shipped half-correct.

## Example

```hcl
module "alb" {
  source = "../../modules/alb"

  project            = "PesaGuard"
  environment        = "production"
  vpc_id             = module.networking.vpc_id
  public_subnet_ids  = module.networking.public_subnet_ids
  security_group_id  = module.security_groups.alb_security_group_id
  certificate_arn    = module.acm.certificate_arn
  enable_deletion_protection = true
}
```
