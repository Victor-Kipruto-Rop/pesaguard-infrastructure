# terraform/live/staging

Root Terraform configuration for the `staging` environment. Instantiates:

- `../../modules/networking` — VPC, subnets, NAT (single, shared), flow logs
- `../../modules/security-groups` — least-privilege SGs for ALB/app/data/monitoring

Not yet instantiated here (added as their phases land): DNS zone, RDS,
Redis, Kafka, compute, load balancer, observability stack.

## Usage

```bash
terraform -chdir=terraform/live/staging init -backend-config=../../../environments/staging/backend.hcl
terraform -chdir=terraform/live/staging plan  -var-file=../../../environments/staging/terraform.tfvars
terraform -chdir=terraform/live/staging apply -var-file=../../../environments/staging/terraform.tfvars
```

Or: `make plan DIR=terraform/live/staging ENV=staging` / `make apply ...`.

## Requires

- `terraform/bootstrap` already applied for `staging`.
- AWS credentials with permission to create VPC/subnet/NAT/security-group
  resources.
