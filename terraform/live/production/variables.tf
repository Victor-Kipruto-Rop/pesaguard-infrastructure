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
