# networking

Creates the VPC and its three subnet tiers, spread across the given
availability zones:

```
                Internet
                   |
             Internet Gateway
                   |
            Public subnets (ALB, NAT)
                   |
       +-----------+-----------+
       |                       |
  App subnets              (no direct route)
  (FastAPI/Java/workers)
       |
   via NAT -> Internet
       |
  Data subnets (RDS, Redis, Kafka)
  — no internet route at all
```

## What this creates

- 1 VPC (`/16`, DNS support + hostnames enabled)
- 1 Internet Gateway
- Public / app / data subnets, one of each per AZ in `var.availability_zones`
  (CIDR math: the `/16` is carved into `/20`s — public gets netnum `0..n-1`,
  app `4..4+n-1`, data `8..8+n-1`)
- NAT gateway(s): one shared (`single_nat_gateway = true`, cheaper, single
  point of failure — default for dev/staging) or one per AZ
  (`single_nat_gateway = false` — recommended for production)
- Route tables: public (→ IGW), one per AZ for app (→ that AZ's NAT), one
  shared for data (no internet route)
- Gateway VPC endpoints for S3 and DynamoDB (no NAT cost for that traffic)
- VPC flow logs to CloudWatch Logs (IAM role scoped to just this log group)

## What this does NOT create

- Security groups (see `../security-groups/`)
- Load balancer, compute, or DNS records (Phase 7+)
- A second AWS region / cross-region peering (not yet implemented — see
  `../../../ARCHITECTURE.md`)

## Inputs / outputs

See `variables.tf` / `outputs.tf`. Key knobs: `vpc_cidr` (must be a `/16`),
`availability_zones` (>= 2), `single_nat_gateway`, `enable_flow_logs`.

## Example

```hcl
module "networking" {
  source = "../../modules/networking"

  project             = "PesaGuard"
  environment         = "development"
  vpc_cidr            = "10.10.0.0/16"
  availability_zones  = ["us-east-1a", "us-east-1b"]
  single_nat_gateway  = true
}
```

## Testing network isolation

Once applied, verify:

- Data subnets have no route `0.0.0.0/0` (`aws_route_table.data` has no
  such route — check with `aws ec2 describe-route-tables`).
- Resources placed in `data_subnet_ids` get no public IP and cannot reach
  the internet directly.
- App subnets can reach the internet only via NAT (outbound only; nothing
  in a public subnet can initiate a connection into an app or data subnet
  except through explicit security group rules — see `../security-groups/`).
