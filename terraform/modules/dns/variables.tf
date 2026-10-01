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

variable "create_alb_records" {
  description = "Whether to create ALIAS records pointing at an ALB. Requires alb_dns_name and alb_zone_id (from the alb module)."
  type        = bool
  default     = false
}

variable "alb_dns_name" {
  description = "ALB DNS name (the alb module's alb_dns_name output). Required when create_alb_records is true."
  type        = string
  default     = ""
}

variable "alb_zone_id" {
  description = "The ALB's own hosted zone ID (the alb module's alb_zone_id output, NOT this module's Route 53 zone). Required when create_alb_records is true."
  type        = string
  default     = ""
}

variable "alb_record_names" {
  description = "Subdomain names to point at the ALB, e.g. [\"api\", \"app\"]. An empty string creates an apex (domain_name itself) alias."
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
