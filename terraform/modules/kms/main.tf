# Secrets Manager key -------------------------------------------------

resource "aws_kms_key" "secrets" {
  description             = "${local.name_prefix} — Secrets Manager encryption"
  deletion_window_in_days = var.key_deletion_window_days
  enable_key_rotation     = var.enable_key_rotation

  policy = jsonencode({
    Version   = "2012-10-17"
    Statement = concat([local.root_admin_statement], local.key_admin_statement)
  })

  tags = merge(local.common_tags, { Name = "${local.name_prefix}-secrets", Service = "secrets-manager" })
}

resource "aws_kms_alias" "secrets" {
  name          = "alias/${local.name_prefix}-secrets"
  target_key_id = aws_kms_key.secrets.key_id
}

# CloudWatch Logs key ----------------------------------------------------
# CloudWatch Logs requires an explicit service-principal grant in the key
# policy (IAM permissions on the log-writing role alone are not enough).

resource "aws_kms_key" "logs" {
  description             = "${local.name_prefix} — CloudWatch Logs encryption"
  deletion_window_in_days = var.key_deletion_window_days
  enable_key_rotation     = var.enable_key_rotation

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = concat([local.root_admin_statement], local.key_admin_statement, [{
      Sid    = "AllowCloudWatchLogs"
      Effect = "Allow"
      Principal = {
        Service = "logs.${data.aws_region.current.name}.amazonaws.com"
      }
      Action = [
        "kms:Encrypt*", "kms:Decrypt*", "kms:ReEncrypt*",
        "kms:GenerateDataKey*", "kms:Describe*",
      ]
      Resource = "*"
      Condition = {
        ArnLike = {
          "kms:EncryptionContext:aws:logs:arn" = "arn:aws:logs:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:log-group:/pesaguard/${var.environment}/*"
        }
      }
    }])
  })

  tags = merge(local.common_tags, { Name = "${local.name_prefix}-logs", Service = "cloudwatch-logs" })
}

resource "aws_kms_alias" "logs" {
  name          = "alias/${local.name_prefix}-logs"
  target_key_id = aws_kms_key.logs.key_id
}

# Backups key (S3 backup buckets, RDS/DB snapshots) -----------------------

resource "aws_kms_key" "backups" {
  description             = "${local.name_prefix} — backups (S3, RDS/DB snapshots) encryption"
  deletion_window_in_days = var.key_deletion_window_days
  enable_key_rotation     = var.enable_key_rotation

  policy = jsonencode({
    Version   = "2012-10-17"
    Statement = concat([local.root_admin_statement], local.key_admin_statement)
  })

  tags = merge(local.common_tags, { Name = "${local.name_prefix}-backups", Service = "backup" })
}

resource "aws_kms_alias" "backups" {
  name          = "alias/${local.name_prefix}-backups"
  target_key_id = aws_kms_key.backups.key_id
}

# Database key (RDS/Redis storage encryption) ------------------------------

resource "aws_kms_key" "database" {
  description             = "${local.name_prefix} — database (RDS, Redis) storage encryption"
  deletion_window_in_days = var.key_deletion_window_days
  enable_key_rotation     = var.enable_key_rotation

  policy = jsonencode({
    Version   = "2012-10-17"
    Statement = concat([local.root_admin_statement], local.key_admin_statement)
  })

  tags = merge(local.common_tags, { Name = "${local.name_prefix}-database", Service = "database" })
}

resource "aws_kms_alias" "database" {
  name          = "alias/${local.name_prefix}-database"
  target_key_id = aws_kms_key.database.key_id
}
