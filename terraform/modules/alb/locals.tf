locals {
  name_prefix  = "${var.project}-${var.environment}"
  enable_https = var.certificate_arn != ""

  common_tags = merge(
    {
      Project            = var.project
      Environment        = var.environment
      ManagedBy          = "Terraform"
      Owner              = "PesaGuard"
      Component          = "load-balancer"
      CostCenter         = var.cost_center
      DataClassification = "internal"
    },
    var.additional_tags
  )

  no_service_message = jsonencode({
    error   = "no_application_deployed"
    message = "Infrastructure is up, but no application service has been deployed to this listener yet."
  })
}
