# ecs

An ECS cluster (Fargate + Fargate Spot capacity providers) plus a fully
reusable pattern for deploying services to it — task definition, ALB
target group + listener rule, ECS service, and CPU-based autoscaling —
all driven by one `services` map variable.

## Why Fargate, not EC2

This repository has no AMI-baking pipeline, patch automation, or fleet
management for EC2 instances. Fargate removes host management entirely
(no instances to patch, no `security/host-hardening.md` checklist to
apply) at the cost of somewhat higher per-vCPU pricing than EC2. The
`architecture.md` "start with ECS/EC2" guidance is satisfied by ECS on
Fargate; moving to ECS-on-EC2 or EKS later is a capacity-provider and
compute change, not a rewrite of this module's service-definition
interface.

## `services` defaults to `{}` — this is deliberate

No real application image exists in this repository yet (see the root
`README.md`'s boundary rules — FastAPI/Java business logic lives in
separate repos). This module is fully built and ready; **nothing is
instantiated** until an environment's `terraform/live/<env>/` populates
`services` with a real image URI (typically from the `ecr` module's
output) and configuration. That is expected to happen in Phase 9
(deployment automation) or whenever the first application image exists —
whichever comes first — not as part of this phase.

## Two IAM roles, two jobs

- **Execution role** (created by this module): what the *ECS agent* uses
  to pull the image, write logs, and fetch secrets at container launch.
  Scoped via the AWS-managed `AmazonECSTaskExecutionRolePolicy` plus an
  inline policy for exactly the secret ARNs referenced across all
  services' `secrets` maps.
- **Task role** (`task_role_arn`, passed in — reused from
  `terraform/modules/iam/`'s `app_service` role): what *application code*
  runs as at runtime. Not created here, so every service shares the one
  set of least-privilege runtime permissions already defined in the `iam`
  module, rather than this module inventing a second, parallel set.

## Health checks

Every service gets both: a container-level Docker `HEALTHCHECK`
(`curl -f http://localhost:<port><health_check_path>`) so ECS can tell
"process alive" from "service ready", and an ALB target group health
check against the same path — matching `../../../ARCHITECTURE.md`'s
requirement that infrastructure distinguish those two states. The
application image must actually serve `health_check_path` and return 200
when ready; this module cannot enforce that from the infrastructure side.

## Ports beyond the pre-opened one

`terraform/modules/security-groups/`'s `app` security group currently
opens one `app_port` from the ALB. If a service in `var.services` uses a
different `port`, its ALB→ECS traffic will be blocked until
`security-groups`'s `app_port` (or an additional rule) is updated —
this module does not modify security groups itself.

## Example

```hcl
module "ecs" {
  source = "../../modules/ecs"

  project                = "PesaGuard"
  environment             = "production"
  vpc_id                  = module.networking.vpc_id
  app_subnet_ids          = module.networking.app_subnet_ids
  app_security_group_id   = module.security_groups.app_security_group_id
  listener_arn            = module.alb.primary_listener_arn
  task_role_arn           = module.iam.app_service_role_arn
  secrets_kms_key_arn     = module.kms.secrets_key_arn
  logs_kms_key_arn        = module.kms.logs_key_arn

  services = {
    api = {
      image                  = "${module.ecr.repository_urls["fastapi-service"]}:v1.0.0"
      cpu                    = 512
      memory                 = 1024
      port                   = 8000
      desired_count          = 2
      path_pattern           = "/api/*"
      listener_rule_priority = 10
      health_check_path      = "/health"
      secrets = {
        DATABASE_URL = module.rds.master_user_secret_arn
      }
    }
  }
}
```
