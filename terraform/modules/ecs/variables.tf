variable "project" {
  description = "Project name."
  type        = string
  default     = "PesaGuard"
}

variable "environment" {
  description = "Environment: development, staging, or production."
  type        = string

  validation {
    condition     = contains(["development", "staging", "production"], var.environment)
    error_message = "environment must be one of: development, staging, production."
  }
}

variable "vpc_id" {
  type = string
}

variable "app_subnet_ids" {
  description = "Application-tier private subnet IDs (from the networking module)."
  type        = list(string)
}

variable "app_security_group_id" {
  description = "Application-tier security group ID (from the security-groups module). Its ingress rule already opens app_port from the ALB — every service in var.services should use that same port unless the security-groups module is also updated."
  type        = string
}

variable "listener_arn" {
  description = "ALB listener ARN to attach per-service listener rules to (the alb module's primary_listener_arn output)."
  type        = string
}

variable "task_role_arn" {
  description = "IAM role ARN application code runs as (the iam module's app_service_role_arn — reused, not created here)."
  type        = string
}

variable "secrets_kms_key_arn" {
  description = "KMS key ARN used to decrypt secrets injected into containers (the secrets key from the kms module)."
  type        = string
}

variable "logs_kms_key_arn" {
  description = "KMS key ARN for per-service CloudWatch Logs groups (the logs key from the kms module)."
  type        = string
}

variable "log_retention_days" {
  type    = number
  default = 30
}

variable "enable_container_insights" {
  type    = bool
  default = true
}

variable "services" {
  description = <<-EOT
    Map of service name => definition. Empty by default: this repository
    has no real application image yet (see README.md) — Phase 9 CI/CD (or
    whoever deploys the first real service) populates this per environment.
    Fields:
      image                   - full image URI (e.g. an ecr module output)
      cpu / memory            - Fargate task size (must be a valid pairing)
      port                    - container port; must match what the
                                 app_security_group_id's ingress rule allows
      desired_count           - initial task count
      path_pattern            - ALB listener rule path pattern, e.g. "/api/*"
      listener_rule_priority  - unique priority across all services
      health_check_path       - ALB target group + container health check path
      environment             - map of plain (non-secret) env vars
      secrets                 - map of env var name => Secrets Manager ARN
      autoscaling_min/max     - task count bounds
      autoscaling_target_cpu  - target CPU % for autoscaling
  EOT
  type = map(object({
    image                   = string
    cpu                     = number
    memory                  = number
    port                    = number
    desired_count           = number
    path_pattern            = string
    listener_rule_priority  = number
    health_check_path       = string
    environment             = optional(map(string), {})
    secrets                 = optional(map(string), {})
    autoscaling_min         = optional(number, 1)
    autoscaling_max         = optional(number, 4)
    autoscaling_target_cpu  = optional(number, 60)
  }))
  default = {}
}

variable "cost_center" {
  description = "Cost center tag."
  type        = string
  default     = "platform-engineering"
}

variable "additional_tags" {
  description = "Additional tags merged onto every resource in this module."
  type        = map(string)
  default     = {}
}
