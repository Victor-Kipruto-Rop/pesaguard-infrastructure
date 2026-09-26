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
