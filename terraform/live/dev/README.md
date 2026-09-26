# terraform/live/dev

Root Terraform configuration for the `development` environment. Instantiates:

- `../../modules/networking` — VPC, subnets, NAT (single, shared), flow logs
- `../../modules/security-groups` — least-privilege SGs for ALB/app/data/monitoring

Not yet instantiated here (added as their phases land): DNS zone, RDS,
Redis, Kafka, compute, load balancer, observability stack.

## Usage

```bash
# One-time, after terraform/bootstrap has been applied for dev and
# environments/dev/backend.hcl has been filled in:
terraform -chdir=terraform/live/dev init -backend-config=../../../environments/dev/backend.hcl

terraform -chdir=terraform/live/dev plan  -var-file=../../../environments/dev/terraform.tfvars
terraform -chdir=terraform/live/dev apply -var-file=../../../environments/dev/terraform.tfvars
```

Or via the root `Makefile`:

```bash
make plan  DIR=terraform/live/dev ENV=dev
make apply DIR=terraform/live/dev ENV=dev
```

## Requires

- `terraform/bootstrap` already applied for `development`
  (see `environments/dev/README.md`).
- AWS credentials with permission to create VPC/subnet/NAT/security-group
  resources.
