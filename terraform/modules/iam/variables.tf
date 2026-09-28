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

variable "region" {
  description = "AWS region."
  type        = string
  default     = "us-east-1"
}

# --- GitHub OIDC (CI/CD, no long-lived AWS access keys) ---------------

variable "create_oidc_provider" {
  description = "Whether to create the GitHub Actions OIDC identity provider. This is an account-wide resource — only one environment (typically production, or a dedicated shared/management account) should create it. Others pass its ARN via existing_oidc_provider_arn."
  type        = bool
  default     = false
}

variable "existing_oidc_provider_arn" {
  description = "ARN of an existing GitHub OIDC provider, used when create_oidc_provider is false."
  type        = string
  default     = ""
}

variable "github_org" {
  description = "GitHub organization or user that owns the infrastructure repo, e.g. Victor-Kipruto-Rop."
  type        = string
}

variable "github_repo" {
  description = "GitHub repository name, e.g. pesaguard-infrastructure."
  type        = string
  default     = "pesaguard-infrastructure"
}

variable "allowed_github_refs" {
  description = "Git refs allowed to assume the CI/CD role via OIDC, e.g. [\"ref:refs/heads/main\"]. Restrict production's role to protected branches only."
  type        = list(string)
  default     = ["ref:refs/heads/main"]
}

# --- Key ARNs from the kms module, for scoping IAM policies -----------

variable "secrets_kms_key_arn" {
  description = "ARN of the Secrets Manager KMS key (from the kms module)."
  type        = string
}

variable "logs_kms_key_arn" {
  description = "ARN of the CloudWatch Logs KMS key (from the kms module)."
  type        = string
}

variable "backups_kms_key_arn" {
  description = "ARN of the backups KMS key (from the kms module)."
  type        = string
}

variable "database_kms_key_arn" {
  description = "ARN of the database KMS key (from the kms module)."
  type        = string
}

# --- Terraform state resources, for scoping the CI/CD role -------------

variable "state_bucket_arn" {
  description = "ARN of this environment's Terraform state S3 bucket (from terraform/bootstrap)."
  type        = string
}

variable "lock_table_arn" {
  description = "ARN of this environment's Terraform lock DynamoDB table (from terraform/bootstrap)."
  type        = string
}

# --- Resources not yet created (later phases) -------------------------
# Left as empty-list defaults so this module works before those resources
# exist; policies fall back to a same-account, tag-scoped wildcard with a
# comment, never a cross-account "*".

variable "app_s3_bucket_arns" {
  description = "S3 bucket ARNs the application-tier role may read/write (populated once those buckets exist)."
  type        = list(string)
  default     = []
}

variable "backup_s3_bucket_arns" {
  description = "S3 bucket ARNs the backup-operator role may write to (populated once those buckets exist)."
  type        = list(string)
  default     = []
}

variable "secret_arns" {
  description = "Secrets Manager secret ARNs the application-tier role may read (populated by the secrets module)."
  type        = list(string)
  default     = []
}

variable "enable_msk_access" {
  description = "Whether to grant the app_service role MSK data-plane access. A plain bool (not derived from msk_cluster_arn) because the ARN is unknown at plan time on first apply and cannot gate a for_each."
  type        = bool
  default     = false
}

variable "msk_cluster_arn" {
  description = "MSK cluster ARN. Required when enable_msk_access is true."
  type        = string
  default     = ""
}

variable "enable_glue_registry_access" {
  description = "Whether to grant the app_service role Glue Schema Registry access. A plain bool for the same plan-time reason as enable_msk_access."
  type        = bool
  default     = false
}

variable "glue_registry_arn" {
  description = "Glue Schema Registry ARN. Required when enable_glue_registry_access is true."
  type        = string
  default     = ""
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
