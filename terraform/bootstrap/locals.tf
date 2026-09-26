locals {
  state_bucket_name = var.state_bucket_name != "" ? var.state_bucket_name : lower(
    "${var.project}-tfstate-${var.environment}-${data.aws_caller_identity.current.account_id}"
  )

  lock_table_name = var.lock_table_name != "" ? var.lock_table_name : "${lower(var.project)}-tflock-${var.environment}"

  common_tags = merge(
    {
      Project             = var.project
      Environment         = var.environment
      ManagedBy           = "Terraform"
      Owner               = "PesaGuard"
      Component           = "terraform-state-backend"
      Service             = "bootstrap"
      CostCenter          = var.cost_center
      DataClassification  = "internal"
    },
    var.additional_tags
  )
}
