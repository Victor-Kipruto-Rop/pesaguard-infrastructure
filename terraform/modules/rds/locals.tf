locals {
  name_prefix = "${var.project}-${var.environment}"

  common_tags = merge(
    {
      Project            = var.project
      Environment        = var.environment
      ManagedBy          = "Terraform"
      Owner              = "PesaGuard"
      Component          = "database"
      Service            = "postgresql"
      CostCenter         = var.cost_center
      DataClassification = "confidential"
    },
    var.additional_tags
  )
}
