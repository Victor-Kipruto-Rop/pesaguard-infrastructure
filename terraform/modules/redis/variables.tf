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
  description = "Data-tier subnet IDs (from the networking module)."
  type        = list(string)
}

variable "security_group_id" {
  description = "Security group ID for Redis (from the security-groups module)."
  type        = string
}

variable "secrets_kms_key_arn" {
  description = "KMS key ARN used to encrypt the generated auth-token secret (the secrets key from the kms module)."
  type        = string
}

variable "node_type" {
  description = "ElastiCache node type."
  type        = string
  default     = "cache.t4g.micro"
}

variable "engine_version" {
  description = "Redis engine version."
  type        = string
  default     = "7.1"
}

variable "num_cache_clusters" {
  description = "Number of nodes in the replication group. 1 = single node (no failover, dev only), 2+ = primary + replica(s) with automatic failover eligible."
  type        = number
  default     = 1
}

variable "automatic_failover_enabled" {
  description = "Whether to enable automatic failover. Requires num_cache_clusters >= 2. Should be true for production."
  type        = bool
  default     = false
}

variable "snapshot_retention_limit" {
  description = "Days to retain automatic snapshots. 0 disables snapshots (not recommended outside development)."
  type        = number
  default     = 1
}

variable "snapshot_window" {
  description = "Preferred daily snapshot window (UTC), e.g. 03:00-04:00."
  type        = string
  default     = "03:00-04:00"
}

variable "maintenance_window" {
  description = "Preferred weekly maintenance window (UTC), e.g. mon:04:30-mon:05:30."
  type        = string
  default     = "mon:04:30-mon:05:30"
}

variable "apply_immediately" {
  description = "Whether changes apply immediately instead of during the next maintenance window."
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
