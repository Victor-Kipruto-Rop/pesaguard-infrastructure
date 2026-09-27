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
  description = "KMS key ARN used to encrypt these secrets (the secrets key from the kms module)."
  type        = string
}

variable "secret_names" {
  description = "Names of secret containers to create, e.g. [\"database/credentials\", \"redis/auth-token\", \"kafka/credentials\"]. Stored under <project>/<environment>/<name>. Only the container is created here — values are set out-of-band (console, CLI, or a rotation Lambda), never by Terraform."
  type        = list(string)
}

variable "recovery_window_days" {
  description = "Days before a deleted secret is permanently destroyed (0 disables the recovery window — not recommended outside development)."
  type        = number
  default     = 30
}

variable "cost_center" {
  description = "Cost center tag."
  type        = string
  default     = "platform-engineering"
}

variable "additional_tags" {
  description = "Additional tags merged onto every secret."
  type        = map(string)
  default     = {}
}
