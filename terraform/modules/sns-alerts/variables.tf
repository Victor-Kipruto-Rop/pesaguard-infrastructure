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

variable "topics" {
  description = "Alert categories to create a topic for. Kept separate so each can have a different on-call destination (e.g. security alerts routed differently from infrastructure alerts)."
  type        = list(string)
  default     = ["infrastructure", "database", "messaging", "application", "security"]
}

variable "kms_key_arn" {
  description = "KMS key ARN for topic encryption (the secrets key from the kms module — SNS message bodies can carry resource identifiers and metric values, not full secrets, but encrypting at rest costs nothing to do)."
  type        = string
}

variable "cost_center" {
  description = "Cost center tag."
  type        = string
  default     = "platform-engineering"
}

variable "additional_tags" {
  description = "Additional tags merged onto every topic."
  type        = map(string)
  default     = {}
}
