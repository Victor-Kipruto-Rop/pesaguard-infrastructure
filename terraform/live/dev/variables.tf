variable "project" {
  description = "Project name."
  type        = string
  default     = "PesaGuard"
}

variable "environment" {
  description = "Environment name (must be 'development' for this root config)."
  type        = string
  default     = "development"
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
  description = "Domain name for this environment's DNS zone, if any."
  type        = string
  default     = ""
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
  description = "Git refs allowed to assume the CI/CD role via OIDC for this environment."
  type        = list(string)
  default     = ["ref:refs/heads/main", "ref:refs/heads/develop"]
}

variable "secret_names" {
  description = "Secret container names to create for this environment (see modules/secrets)."
  type        = list(string)
  default     = ["database/credentials", "redis/auth-token", "kafka/credentials"]
}
