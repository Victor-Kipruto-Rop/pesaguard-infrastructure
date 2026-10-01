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

variable "public_subnet_ids" {
  description = "Public subnet IDs (from the networking module) for the ALB itself."
  type        = list(string)
}

variable "security_group_id" {
  description = "ALB security group ID (from the security-groups module)."
  type        = string
}

variable "certificate_arn" {
  description = "Validated ACM certificate ARN (from the acm module). Leave empty to run HTTP-only (no HTTPS listener) — only acceptable for environments with no public domain yet; see README."
  type        = string
  default     = ""
}

variable "enable_deletion_protection" {
  description = "Whether to enable ALB deletion protection. Should be true for production."
  type        = bool
  default     = false
}

variable "idle_timeout_seconds" {
  type    = number
  default = 60
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
