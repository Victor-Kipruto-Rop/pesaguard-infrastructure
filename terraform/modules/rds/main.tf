resource "aws_db_subnet_group" "this" {
  name       = "${local.name_prefix}-postgres"
  subnet_ids = var.subnet_ids

  tags = merge(local.common_tags, { Name = "${local.name_prefix}-postgres-subnet-group" })
}

resource "aws_db_parameter_group" "this" {
  name   = "${local.name_prefix}-postgres"
  family = "postgres${split(".", var.engine_version)[0]}"

  parameter {
    name  = "rds.force_ssl"
    value = "1"
  }

  parameter {
    name         = "log_min_duration_statement"
    value        = "1000" # log queries slower than 1s
    apply_method = "pending-reboot"
  }

  tags = local.common_tags
}

resource "aws_db_instance" "this" {
  identifier = "${local.name_prefix}-postgres"

  engine         = "postgres"
  engine_version = var.engine_version
  instance_class = var.instance_class

  allocated_storage     = var.allocated_storage
  max_allocated_storage = var.max_allocated_storage
  storage_type          = "gp3"
  storage_encrypted     = true
  kms_key_id            = var.storage_kms_key_arn

  db_name  = var.database_name
  username = var.master_username
  # No master_password set: RDS creates and manages this credential
  # natively in Secrets Manager (rotatable without a Terraform apply).
  manage_master_user_password = true
  master_user_secret_kms_key_id = var.secrets_kms_key_arn

  db_subnet_group_name   = aws_db_subnet_group.this.name
  vpc_security_group_ids = [var.security_group_id]
  parameter_group_name   = aws_db_parameter_group.this.name
  publicly_accessible    = false

  multi_az = var.multi_az

  backup_retention_period = var.backup_retention_period
  backup_window           = var.backup_window
  maintenance_window      = var.maintenance_window
  copy_tags_to_snapshot   = true

  deletion_protection       = var.deletion_protection
  skip_final_snapshot       = var.skip_final_snapshot
  final_snapshot_identifier = var.skip_final_snapshot ? null : "${local.name_prefix}-postgres-final"

  enabled_cloudwatch_logs_exports = ["postgresql", "upgrade"]

  performance_insights_enabled         = true
  performance_insights_kms_key_id      = var.storage_kms_key_arn
  performance_insights_retention_period = var.performance_insights_retention_days

  apply_immediately = var.apply_immediately

  tags = merge(local.common_tags, { Name = "${local.name_prefix}-postgres" })

  lifecycle {
    # The password is managed by RDS/Secrets Manager, not Terraform; never
    # let a stray master_password diff attempt to overwrite it.
    ignore_changes = [master_password]
  }
}
