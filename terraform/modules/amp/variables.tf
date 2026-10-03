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

variable "logs_kms_key_arn" {
  description = "KMS key ARN for AMP's own CloudWatch logging configuration (the logs key from the kms module)."
  type        = string
}

variable "log_retention_days" {
  type    = number
  default = 30
}

variable "security_topic_arn" {
  description = "SNS topic ARN the Alertmanager definition's \"sns\" receiver publishes to. AMP's alert manager supports the sns receiver type natively — no self-hosted Alertmanager needed."
  type        = string
}

variable "sns_region" {
  description = "Region of security_topic_arn, required by AMP's alertmanager sns receiver config."
  type        = string
}

variable "cost_center" {
  description = "Cost center tag."
  type        = string
  default     = "platform-engineering"
}

variable "additional_tags" {
  description = "Additional tags merged onto the workspace."
  type        = map(string)
  default     = {}
}
