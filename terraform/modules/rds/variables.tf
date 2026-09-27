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

variable "subnet_ids" {
  description = "Data-tier subnet IDs (from the networking module) to place the DB subnet group in."
  type        = list(string)
}

variable "security_group_id" {
  description = "Security group ID for PostgreSQL (from the security-groups module)."
  type        = string
}

variable "storage_kms_key_arn" {
  description = "KMS key ARN for storage encryption (the database key from the kms module)."
  type        = string
}

variable "secrets_kms_key_arn" {
  description = "KMS key ARN used to encrypt the RDS-managed master password secret (the secrets key from the kms module)."
  type        = string
}

variable "engine_version" {
  description = "PostgreSQL major/minor version."
  type        = string
  default     = "16.4"
}

variable "instance_class" {
  description = "RDS instance class. Size per environment via tfvars — small for dev, larger for production."
  type        = string
  default     = "db.t4g.micro"
}

variable "allocated_storage" {
  description = "Initial allocated storage in GiB."
  type        = number
  default     = 20
}

variable "max_allocated_storage" {
  description = "Upper bound for RDS storage autoscaling, in GiB."
  type        = number
  default     = 100
}

variable "multi_az" {
  description = "Whether to deploy a Multi-AZ standby. Should be true for production."
  type        = bool
  default     = false
}

variable "master_username" {
  description = "Master username. The password is never set here — RDS manages it natively in Secrets Manager (manage_master_user_password)."
  type        = string
  default     = "pesaguard_admin"
}

variable "database_name" {
  description = "Name of the default database created with the instance."
  type        = string
  default     = "pesaguard"
}

variable "backup_retention_period" {
  description = "Automated backup retention in days (also the practical bound on point-in-time recovery). Production should use a longer window than dev/staging."
  type        = number
  default     = 7
}

variable "backup_window" {
  description = "Preferred daily backup window (UTC), e.g. 03:00-04:00."
  type        = string
  default     = "03:00-04:00"
}

variable "maintenance_window" {
  description = "Preferred weekly maintenance window (UTC), e.g. mon:04:00-mon:05:00."
  type        = string
  default     = "mon:04:00-mon:05:00"
}

variable "deletion_protection" {
  description = "Whether to enable RDS deletion protection. Should be true for production."
  type        = bool
  default     = false
}

variable "skip_final_snapshot" {
  description = "Whether to skip the final snapshot on destroy. Must be false for production."
  type        = bool
  default     = true
}

variable "performance_insights_retention_days" {
  description = "Performance Insights retention in days (7 = free tier)."
  type        = number
  default     = 7
}

variable "apply_immediately" {
  description = "Whether parameter/instance changes apply immediately instead of during the next maintenance window. Keep false for production to avoid unexpected mid-day changes."
  type        = bool
  default     = false
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
