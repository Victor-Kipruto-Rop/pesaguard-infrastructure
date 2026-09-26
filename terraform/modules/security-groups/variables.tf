variable "project" {
  description = "Project name, used in resource naming and tags."
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
  description = "VPC ID these security groups belong to."
  type        = string
}

variable "vpc_cidr_block" {
  description = "CIDR block of the VPC, used for VPC-internal-only rules (e.g. monitoring scrape targets)."
  type        = string
}

variable "public_ingress_cidrs" {
  description = "CIDR blocks allowed to reach the ALB on 80/443. Defaults to the public internet; narrow this for internal-only environments."
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "app_port" {
  description = "Port the ALB forwards to on application-tier instances/containers."
  type        = number
  default     = 8000
}

variable "postgres_port" {
  description = "PostgreSQL port."
  type        = number
  default     = 5432
}

variable "redis_port" {
  description = "Redis port."
  type        = number
  default     = 6379
}

variable "kafka_ports" {
  description = "Kafka/Redpanda broker ports (plaintext and TLS listeners)."
  type        = list(number)
  default     = [9092, 9093]
}

variable "schema_registry_port" {
  description = "Schema Registry port."
  type        = number
  default     = 8081
}

variable "monitoring_ports" {
  description = "Ports used by the observability stack (Prometheus, Grafana, Alertmanager), reachable only from within the VPC."
  type        = list(number)
  default     = [9090, 3000, 9093]
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
