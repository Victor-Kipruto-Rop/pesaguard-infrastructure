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

variable "domain_name" {
  description = "Primary domain name for the certificate, e.g. pesaguard.victorkipruto.com."
  type        = string
}

variable "subject_alternative_names" {
  description = "Additional names the certificate should cover, e.g. [\"api.pesaguard.victorkipruto.com\", \"app.pesaguard.victorkipruto.com\"]."
  type        = list(string)
  default     = []
}

variable "zone_id" {
  description = "Route 53 zone ID to create DNS validation records in (from the dns module)."
  type        = string
}

variable "cost_center" {
  description = "Cost center tag."
  type        = string
  default     = "platform-engineering"
}

variable "additional_tags" {
  description = "Additional tags merged onto the certificate."
  type        = map(string)
  default     = {}
}
