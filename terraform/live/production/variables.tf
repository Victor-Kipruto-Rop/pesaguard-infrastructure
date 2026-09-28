variable "project" {
  description = "Project name."
  type        = string
  default     = "PesaGuard"
}

variable "environment" {
  description = "Environment name (must be 'production' for this root config)."
  type        = string
  default     = "production"
}

variable "region" {
  description = "AWS region."
  type        = string
  default     = "us-east-1"
}

variable "vpc_cidr" {
  description = "VPC CIDR block (/16)."
  type        = string
}

variable "availability_zones" {
  description = "Availability zones to spread subnets across."
  type        = list(string)
}

variable "domain_name" {
  description = "Domain name for the production DNS zone."
  type        = string
}

variable "create_dns_zone" {
  description = "Whether production owns and creates the apex Route 53 zone."
  type        = bool
  default     = true
}

variable "github_org" {
  description = "GitHub organization/user owning the infrastructure repo."
  type        = string
  default     = "Victor-Kipruto-Rop"
}

variable "github_repo" {
  description = "GitHub repository name."
  type        = string
  default     = "pesaguard-infrastructure"
}

variable "allowed_github_refs" {
  description = "Git refs allowed to assume production's CI/CD role via OIDC. Kept to protected branches only."
  type        = list(string)
  default     = ["ref:refs/heads/main"]
}

variable "secret_names" {
  description = "Secret container names to create for this environment (see modules/secrets)."
  type        = list(string)
  default     = ["database/credentials", "redis/auth-token", "kafka/credentials"]
}

variable "rds_instance_class" {
  type    = string
  default = "db.r6g.large"
}

variable "rds_multi_az" {
  type    = bool
  default = true
}

variable "rds_deletion_protection" {
  type    = bool
  default = true
}

variable "rds_skip_final_snapshot" {
  type    = bool
  default = false
}

variable "rds_backup_retention_period" {
  type    = number
  default = 30
}

variable "redis_node_type" {
  type    = string
  default = "cache.r6g.large"
}

variable "redis_num_cache_clusters" {
  type    = number
  default = 2
}

variable "redis_automatic_failover_enabled" {
  type    = bool
  default = true
}

variable "msk_broker_instance_type" {
  type    = string
  default = "kafka.m5.large"
}

variable "msk_number_of_broker_nodes" {
  description = "Must be a multiple of the number of AZs/subnets."
  type        = number
  default     = 3
}

variable "msk_broker_ebs_volume_size" {
  type    = number
  default = 500
}
