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
  description = "Data-tier subnet IDs (from the networking module). MSK places one broker per subnet per broker-per-AZ, so provide at least 2 (3 recommended for production)."
  type        = list(string)

  validation {
    condition     = length(var.subnet_ids) >= 2
    error_message = "At least 2 subnets (AZs) are required for MSK."
  }
}

variable "security_group_id" {
  description = "Security group ID for Kafka/MSK (from the security-groups module)."
  type        = string
}

variable "kms_key_arn" {
  description = "KMS key ARN for broker storage encryption (the messaging key from the kms module)."
  type        = string
}

variable "logs_kms_key_arn" {
  description = "KMS key ARN for the CloudWatch Logs group MSK broker logs are exported to (the logs key from the kms module)."
  type        = string
}

variable "kafka_version" {
  description = "MSK-supported Kafka version."
  type        = string
  default     = "3.7.x"
}

variable "broker_instance_type" {
  description = "MSK broker instance type."
  type        = string
  default     = "kafka.t3.small"
}

variable "number_of_broker_nodes" {
  description = "Total broker count. Must be a multiple of length(subnet_ids) (one broker per subnet per 'set')."
  type        = number
  default     = 2
}

variable "broker_ebs_volume_size" {
  description = "Per-broker EBS storage in GiB."
  type        = number
  default     = 100
}

variable "enhanced_monitoring" {
  description = "MSK enhanced monitoring level: DEFAULT, PER_BROKER, PER_TOPIC_PER_BROKER, or PER_TOPIC_PER_PARTITION."
  type        = string
  default     = "PER_BROKER"
}

variable "log_retention_days" {
  description = "CloudWatch Logs retention for broker logs."
  type        = number
  default     = 30
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
