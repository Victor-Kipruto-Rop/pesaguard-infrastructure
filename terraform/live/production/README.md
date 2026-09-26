# terraform/live/production

Root Terraform configuration for the `production` environment. Instantiates:

- `../../modules/networking` — VPC, subnets, **one NAT gateway per AZ** (HA)
- `../../modules/security-groups` — least-privilege SGs for ALB/app/data/monitoring
- `../../modules/dns` — the apex Route 53 hosted zone (production owns it;
  dev/staging are expected to reuse it for subdomains once Phase 7 adds
  records)

Not yet instantiated here (added as their phases land): RDS, Redis, Kafka,
compute, load balancer, observability stack.

## Usage

```bash
terraform -chdir=terraform/live/production init -backend-config=../../../environments/production/backend.hcl
terraform -chdir=terraform/live/production plan  -var-file=../../../environments/production/terraform.tfvars
```

`apply` against production requires `CONFIRM=yes` via the Makefile
(`make apply DIR=terraform/live/production ENV=production CONFIRM=yes`) —
see [CONTRIBUTING.md](../../../CONTRIBUTING.md) for the human-approval
expectation this does not replace.

## After first apply

1. Note the `dns_name_servers` output.
2. Delegate `domain_name` at your registrar to those name servers.
3. Nothing will resolve until Phase 7 adds actual DNS records pointing at
   the load balancer.

## Requires

- `terraform/bootstrap` already applied for `production`.
- AWS credentials with permission to create VPC/subnet/NAT/security-group/
  Route 53 resources.
- A second reviewer per [CONTRIBUTING.md](../../../CONTRIBUTING.md) for
  any production apply.
