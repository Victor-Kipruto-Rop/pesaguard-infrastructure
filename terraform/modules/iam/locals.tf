locals {
  name_prefix = "${var.project}-${var.environment}"

  oidc_provider_arn = var.create_oidc_provider ? aws_iam_openid_connect_provider.github[0].arn : var.existing_oidc_provider_arn

  common_tags = merge(
    {
      Project            = var.project
      Environment        = var.environment
      ManagedBy          = "Terraform"
      Owner              = "PesaGuard"
      Component          = "iam"
      CostCenter         = var.cost_center
      DataClassification = "internal"
    },
    var.additional_tags
  )

  # Fallback resource list for policies whose real targets (S3 buckets,
  # secrets) don't exist yet in this phase. Scoped to this account and
  # region, never a bare "*" across accounts/services.
  app_s3_resources     = length(var.app_s3_bucket_arns) > 0 ? flatten([for b in var.app_s3_bucket_arns : [b, "${b}/*"]]) : []
  backup_s3_resources  = length(var.backup_s3_bucket_arns) > 0 ? flatten([for b in var.backup_s3_bucket_arns : [b, "${b}/*"]]) : []
  secret_resources     = length(var.secret_arns) > 0 ? var.secret_arns : []
}
