variable "project" {
  description = "Project name, used in resource naming and tags."
  type        = string
  default     = "PesaGuard"
}

variable "environment" {
  description = "Environment this backend serves: development, staging, or production."
  type        = string

  validation {
    condition     = contains(["development", "staging", "production"], var.environment)
    error_message = "environment must be one of: development, staging, production."
  }
}

variable "region" {
  description = "AWS region for the state bucket and lock table."
  type        = string
  default     = "us-east-1"
}

variable "state_bucket_name" {
  description = "Override for the state bucket name. Defaults to a derived, globally-unique name."
  type        = string
  default     = ""
}

variable "lock_table_name" {
  description = "Override for the DynamoDB lock table name. Defaults to a derived name."
  type        = string
  default     = ""
}

variable "cost_center" {
  description = "Cost center tag applied to backend resources."
  type        = string
  default     = "platform-engineering"
}

variable "additional_tags" {
  description = "Additional tags to merge onto every resource in this module."
  type        = map(string)
  default     = {}
}
