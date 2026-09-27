locals {
  name_prefix = "${var.project}-${var.environment}"

  common_tags = merge(
    {
      Project            = var.project
      Environment        = var.environment
      ManagedBy          = "Terraform"
      Owner              = "PesaGuard"
      Component          = "kms"
      CostCenter         = var.cost_center
      DataClassification = "internal"
    },
    var.additional_tags
  )

  # "Enable IAM User Permissions": delegates all authorization to IAM
  # policies attached to roles/users in this account, so the iam module
  # can grant specific roles kms:Decrypt/GenerateDataKey on specific key
  # ARNs without this module needing to know about those roles.
  root_admin_statement = {
    Sid    = "EnableIAMUserPermissions"
    Effect = "Allow"
    Principal = {
      AWS = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
    }
    Action   = "kms:*"
    Resource = "*"
  }

  key_admin_statement = length(var.additional_key_admin_arns) > 0 ? [{
    Sid    = "AllowKeyAdmins"
    Effect = "Allow"
    Principal = {
      AWS = var.additional_key_admin_arns
    }
    Action = [
      "kms:Create*", "kms:Describe*", "kms:Enable*", "kms:List*",
      "kms:Put*", "kms:Update*", "kms:Revoke*", "kms:Disable*",
      "kms:Get*", "kms:Delete*", "kms:TagResource", "kms:UntagResource",
      "kms:ScheduleKeyDeletion", "kms:CancelKeyDeletion",
    ]
    Resource = "*"
  }] : []
}
