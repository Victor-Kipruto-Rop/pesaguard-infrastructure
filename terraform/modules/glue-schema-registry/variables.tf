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
  description = "VPC ID (for the optional interface VPC endpoint's security group)."
  type        = string
}

variable "vpc_cidr_block" {
  description = "VPC CIDR block, for the endpoint security group's egress rule."
  type        = string
}

variable "subnet_ids" {
  description = "Subnets to place the Glue interface VPC endpoint's ENIs in (typically the app-tier subnets, since application services are the consumers)."
  type        = list(string)
}

variable "app_security_group_id" {
  description = "The app tier's security group ID, allowed to reach the endpoint on 443."
  type        = string
}

variable "create_vpc_endpoint" {
  description = "Whether to create a private interface VPC endpoint for Glue, so app-tier calls to the Schema Registry API don't route through NAT. Costs an hourly fee per AZ; disable for a low-traffic dev environment if desired."
  type        = bool
  default     = true
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
