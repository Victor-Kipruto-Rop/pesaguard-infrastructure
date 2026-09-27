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

variable "kms_key_arn" {
  description = "KMS key ARN used for SSE-KMS on every bucket (the backups key from the kms module)."
  type        = string
}

variable "buckets" {
  description = "Buckets to create. name is a suffix (final bucket name is <project>-<environment>-<name>-<account_id>); noncurrent_version_expiration_days controls how long old versions are kept before permanent deletion."
  type = list(object({
    name                              = string
    noncurrent_version_expiration_days = number
  }))
  default = [
    { name = "backups", noncurrent_version_expiration_days = 90 },
    { name = "artifacts", noncurrent_version_expiration_days = 365 },
    { name = "logs", noncurrent_version_expiration_days = 90 },
  ]
}

variable "cost_center" {
  description = "Cost center tag."
  type        = string
  default     = "platform-engineering"
}

variable "additional_tags" {
  description = "Additional tags merged onto every bucket."
  type        = map(string)
  default     = {}
}
