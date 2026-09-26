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

variable "vpc_cidr" {
  description = "CIDR block for the VPC. Must be a /16 so the subnet math below has room."
  type        = string

  validation {
    condition     = can(cidrnetmask(var.vpc_cidr)) && split("/", var.vpc_cidr)[1] == "16"
    error_message = "vpc_cidr must be a valid /16 CIDR block, e.g. 10.10.0.0/16."
  }
}

variable "availability_zones" {
  description = "Availability zones to spread subnets across. At least 2 required for Multi-AZ resources."
  type        = list(string)

  validation {
    condition     = length(var.availability_zones) >= 2
    error_message = "At least 2 availability zones are required."
  }
}

variable "single_nat_gateway" {
  description = "If true, create one NAT gateway shared by all AZs (cheaper, single point of failure — suitable for dev/staging). If false, one NAT gateway per AZ (production)."
  type        = bool
  default     = true
}

variable "enable_flow_logs" {
  description = "Whether to enable VPC flow logs to CloudWatch Logs."
  type        = bool
  default     = true
}

variable "flow_log_retention_days" {
  description = "CloudWatch Logs retention for VPC flow logs."
  type        = number
  default     = 30
}

variable "enable_s3_endpoint" {
  description = "Whether to create an S3 gateway VPC endpoint (no NAT/data-transfer cost for S3 traffic)."
  type        = bool
  default     = true
}

variable "enable_dynamodb_endpoint" {
  description = "Whether to create a DynamoDB gateway VPC endpoint."
  type        = bool
  default     = true
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
