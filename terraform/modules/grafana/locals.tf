locals {
  name_prefix = "${var.project}-${var.environment}"

  common_tags = merge(
    {
      Project            = var.project
      Environment        = var.environment
      ManagedBy          = "Terraform"
      Owner              = "PesaGuard"
      Component          = "observability"
      Service            = "grafana"
      CostCenter         = var.cost_center
      DataClassification = "internal"
    },
    var.additional_tags
  )
}
