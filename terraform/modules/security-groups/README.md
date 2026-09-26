# security-groups

Least-privilege security groups for every tier, referencing each other by
security group ID rather than CIDR block wherever the traffic stays inside
the VPC.

```
Internet
   |  443/80 from public_ingress_cidrs
  ALB SG
   |  app_port, SG-to-SG only
  App SG -----------------------------------+
   |  postgres_port          |  redis_port  |  kafka_ports, schema_registry_port
Postgres SG               Redis SG        Kafka SG
(no internet egress)    (no internet egress) (no internet egress)

Monitoring SG: ingress only from within the VPC CIDR (not from the ALB or
the internet); egress open for external alert notifications.
```

## Groups created

| Group | Ingress | Egress |
|---|---|---|
| `alb` | 80/443 from `public_ingress_cidrs` (default `0.0.0.0/0`) | VPC CIDR only |
| `app` | `app_port` from `alb`; all ports from itself (service-to-service) | `0.0.0.0/0` (NAT-routed — needed for external APIs, S3, RDS, Redis, Kafka) |
| `postgres` | `postgres_port` from `app` | VPC CIDR only |
| `redis` | `redis_port` from `app` | VPC CIDR only |
| `kafka` | `kafka_ports` + `schema_registry_port` from `app`; broker-to-broker from itself | VPC CIDR only |
| `monitoring` | `monitoring_ports` from VPC CIDR only (not from ALB) | `0.0.0.0/0` (alert notification integrations) |

No `0.0.0.0/0` is used for service-to-service communication — only the ALB's
public listener and the app/monitoring tiers' outbound internet access use
it, both intentionally and documented above.

## Management access

No bastion / SSH security group is created here. Administrative access to
instances should go through **AWS Systems Manager Session Manager**, which
does not require an inbound security group rule at all (see
`../../../ARCHITECTURE.md` and Phase 4). If a bastion later proves
necessary, add a dedicated `bastion` security group scoped to a specific
source CIDR — do not reuse the `app` security group for it.

## Inputs / outputs

See `variables.tf` / `outputs.tf`. Ports (`app_port`, `postgres_port`,
`redis_port`, `kafka_ports`, `schema_registry_port`, `monitoring_ports`)
are all variables — no port numbers are hard-coded outside this module's
defaults.

## Example

```hcl
module "security_groups" {
  source = "../../modules/security-groups"

  project        = "PesaGuard"
  environment    = "development"
  vpc_id         = module.networking.vpc_id
  vpc_cidr_block = module.networking.vpc_cidr_block
}
```
