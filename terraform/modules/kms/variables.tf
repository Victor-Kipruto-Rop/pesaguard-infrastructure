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

variable "key_deletion_window_days" {
  description = "Waiting period before a deleted KMS key is actually destroyed."
  type        = number
  default     = 30
}

variable "enable_key_rotation" {
  description = "Whether to enable automatic annual key rotation."
  type        = bool
  default     = true
}

variable "additional_key_admin_arns" {
  description = "IAM principal ARNs (beyond the account root) allowed to administer these keys."
  type        = list(string)
  default     = []
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
