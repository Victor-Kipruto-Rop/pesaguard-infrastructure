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

variable "create" {
  description = "Whether to create the Amazon Managed Grafana workspace. Default false: it requires IAM Identity Center (AWS SSO) already enabled for the account, which Terraform cannot safely bootstrap. Set true only after confirming that prerequisite — see README.md."
  type        = bool
  default     = false
}

variable "amp_workspace_arn" {
  description = "AMP workspace ARN to grant this Grafana workspace read access to (the amp module's workspace_arn output). Required when create is true."
  type        = string
  default     = ""
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
