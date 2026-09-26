variable "project" {
  description = "Project name, used in tags."
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

variable "create_zone" {
  description = "Whether to create a Route 53 public hosted zone. Set false to reuse an existing zone (pass its ID via existing_zone_id) — useful so only one environment (typically production) owns the apex zone."
  type        = bool
  default     = false
}

variable "domain_name" {
  description = "Domain name for the zone, e.g. pesaguard.victorkipruto.com."
  type        = string
}

variable "existing_zone_id" {
  description = "Route 53 zone ID to use when create_zone is false."
  type        = string
  default     = ""
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
