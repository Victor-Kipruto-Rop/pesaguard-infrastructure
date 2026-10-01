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

variable "alb_arn" {
  description = "ARN of the ALB to associate this Web ACL with."
  type        = string
}

variable "rate_limit_per_5min" {
  description = "Max requests per 5-minute window per source IP before the rate-based rule blocks it."
  type        = number
  default     = 3000
}

variable "logs_kms_key_arn" {
  description = "KMS key ARN for the WAF log group (the logs key from the kms module)."
  type        = string
}

variable "log_retention_days" {
  description = "CloudWatch Logs retention for WAF logs."
  type        = number
  default     = 30
}

variable "cost_center" {
  description = "Cost center tag."
  type        = string
  default     = "platform-engineering"
}

variable "additional_tags" {
  description = "Additional tags merged onto the Web ACL."
  type        = map(string)
  default     = {}
}
