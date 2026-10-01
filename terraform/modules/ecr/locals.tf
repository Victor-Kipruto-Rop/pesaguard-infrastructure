locals {
  common_tags = merge(
    {
      Project            = var.project
      Environment        = var.environment
      ManagedBy          = "Terraform"
      Owner              = "PesaGuard"
      Component          = "container-registry"
      CostCenter         = var.cost_center
      DataClassification = "internal"
    },
    var.additional_tags
  )
}
