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

variable "repository_names" {
  description = "Names of ECR repositories to create, one per deployable image. Kept separate from application repos' own build config — this only reserves the registry location and its lifecycle/scan policy."
  type        = list(string)
  default     = ["fastapi-service", "java-service", "worker"]
}

variable "untagged_image_expiry_days" {
  description = "Days after which an untagged image is expired."
  type        = number
  default     = 14
}

variable "tagged_image_keep_count" {
  description = "Number of most-recent tagged images to keep per repository; older ones are expired."
  type        = number
  default     = 20
}

variable "cost_center" {
  description = "Cost center tag."
  type        = string
  default     = "platform-engineering"
}

variable "additional_tags" {
  description = "Additional tags merged onto every repository."
  type        = map(string)
  default     = {}
}
