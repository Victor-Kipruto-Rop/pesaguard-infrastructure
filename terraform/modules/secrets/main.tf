# Creates one Secrets Manager secret container per entry in var.secret_names.
# Terraform manages the container (name, KMS key, tags, recovery window)
# but NOT the value: a random placeholder is written once so the secret
# isn't left in an unusable empty state, then `ignore_changes` tells
# Terraform to never touch the value again. The real value is set
# out-of-band (AWS console, CLI, or a rotation Lambda added in Phase 10)
# by someone with access to actual credentials — it is never generated
# from or committed to this repository.

resource "aws_secretsmanager_secret" "this" {
  for_each = toset(var.secret_names)

  name                    = "${var.project}/${var.environment}/${each.value}"
  description             = "Managed by Terraform (container only — value set out-of-band). See terraform/modules/secrets/README.md."
  kms_key_id              = var.kms_key_arn
  recovery_window_in_days = var.recovery_window_days

  tags = merge(
    {
      Project            = var.project
      Environment        = var.environment
      ManagedBy          = "Terraform"
      Owner              = "PesaGuard"
      Component          = "secrets"
      CostCenter         = var.cost_center
      DataClassification = "confidential"
    },
    var.additional_tags
  )
}

resource "random_password" "placeholder" {
  for_each = toset(var.secret_names)

  length  = 32
  special = true
}

resource "aws_secretsmanager_secret_version" "placeholder" {
  for_each = toset(var.secret_names)

  secret_id     = aws_secretsmanager_secret.this[each.value].id
  secret_string = jsonencode({ status = "PLACEHOLDER_NOT_A_REAL_SECRET", value = random_password.placeholder[each.value].result })

  lifecycle {
    ignore_changes = [secret_string]
  }
}
