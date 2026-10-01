locals {
  name_prefix = "${var.project}-${var.environment}"

  common_tags = merge(
    {
      Project            = var.project
      Environment        = var.environment
      ManagedBy          = "Terraform"
      Owner              = "PesaGuard"
      Component          = "compute"
      CostCenter         = var.cost_center
      DataClassification = "internal"
    },
    var.additional_tags
  )

  # Every secret ARN referenced by any service, deduplicated, for the
  # execution role's secretsmanager:GetSecretValue policy. A secret value
  # can carry a "::jsonkey::version" suffix in the map value (ECS supports
  # pulling one JSON key); strip that before using it as an IAM resource.
  all_secret_arns = distinct([
    for arn in flatten([for s in var.services : values(s.secrets)]) :
    split("::", arn)[0]
  ])
}
