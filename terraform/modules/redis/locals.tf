locals {
  name_prefix = "${var.project}-${var.environment}"

  common_tags = merge(
    {
      Project            = var.project
      Environment        = var.environment
      ManagedBy          = "Terraform"
      Owner              = "PesaGuard"
      Component          = "cache"
      Service            = "redis"
      CostCenter         = var.cost_center
      DataClassification = "confidential"
    },
    var.additional_tags
  )
}
