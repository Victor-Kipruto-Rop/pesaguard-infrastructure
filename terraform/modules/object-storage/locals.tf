locals {
  buckets_by_name = { for b in var.buckets : b.name => b }

  common_tags = merge(
    {
      Project            = var.project
      Environment        = var.environment
      ManagedBy          = "Terraform"
      Owner              = "PesaGuard"
      Component          = "object-storage"
      CostCenter         = var.cost_center
      DataClassification = "internal"
    },
    var.additional_tags
  )
}
