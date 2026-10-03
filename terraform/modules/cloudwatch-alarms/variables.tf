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

variable "database_topic_arn" {
  type = string
}

variable "messaging_topic_arn" {
  type = string
}

variable "infrastructure_topic_arn" {
  type = string
}

variable "security_topic_arn" {
  type = string
}

# --- RDS ---

variable "rds_instance_id" {
  description = "RDS DBInstanceIdentifier (the rds module's db_instance_id output)."
  type        = string
}

variable "rds_cpu_threshold_percent" {
  type    = number
  default = 80
}

variable "rds_free_storage_threshold_bytes" {
  description = "Alarm when free storage drops below this many bytes. Default 2 GiB."
  type        = number
  default     = 2147483648
}

variable "rds_connection_threshold_count" {
  type    = number
  default = 150
}

# --- Redis ---

variable "redis_cache_cluster_ids" {
  description = "Individual cache cluster (node) IDs (the redis module's member_cluster_ids output). One CPU/memory alarm pair is created per node."
  type        = list(string)
}

variable "redis_cpu_threshold_percent" {
  type    = number
  default = 80
}

variable "redis_memory_threshold_percent" {
  type    = number
  default = 85
}

# --- MSK ---

variable "msk_cluster_name" {
  description = "MSK cluster name (the msk module's cluster_name output)."
  type        = string
}

# --- ALB ---

variable "alb_arn_suffix" {
  description = "ALB short ARN form used as a metric dimension (the alb module's alb_arn_suffix output)."
  type        = string
}

variable "alb_5xx_threshold_count" {
  description = "Alarm when 5xx responses from targets exceed this count in one evaluation period (5 min)."
  type        = number
  default     = 25
}

variable "alb_target_response_time_threshold_seconds" {
  type    = number
  default = 2
}

# --- WAF ---

variable "waf_web_acl_name" {
  description = "WAF Web ACL name (the waf module's... note: the waf module names it \"<project>-<env>-waf\" internally; pass that same name here)."
  type        = string
}

variable "waf_blocked_requests_threshold_count" {
  type    = number
  default = 1000
}

variable "cost_center" {
  description = "Cost center tag."
  type        = string
  default     = "platform-engineering"
}

variable "additional_tags" {
  description = "Additional tags merged onto every alarm."
  type        = map(string)
  default     = {}
}
