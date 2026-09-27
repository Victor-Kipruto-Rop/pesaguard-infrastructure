resource "random_password" "auth_token" {
  length = 32
  # ElastiCache auth tokens must be printable ASCII, 16-128 chars,
  # excluding '@', '"', and '/'.
  override_special = "!#$%^&*()-_=+[]{}<>:?"
}

resource "aws_secretsmanager_secret" "redis_auth" {
  name        = "${var.project}/${var.environment}/redis/auth-token"
  description = "Redis AUTH token for ${var.project} ${var.environment}, generated and owned by Terraform (terraform/modules/redis)."
  kms_key_id  = var.secrets_kms_key_arn

  tags = local.common_tags
}

resource "aws_secretsmanager_secret_version" "redis_auth" {
  secret_id     = aws_secretsmanager_secret.redis_auth.id
  secret_string = jsonencode({ auth_token = random_password.auth_token.result })
}

resource "aws_elasticache_subnet_group" "this" {
  name       = "${local.name_prefix}-redis"
  subnet_ids = var.subnet_ids

  tags = local.common_tags
}

resource "aws_elasticache_replication_group" "this" {
  replication_group_id = "${local.name_prefix}-redis"
  description           = "${var.project} ${var.environment} Redis"

  engine         = "redis"
  engine_version = var.engine_version
  node_type      = var.node_type

  num_cache_clusters         = var.num_cache_clusters
  automatic_failover_enabled = var.automatic_failover_enabled

  subnet_group_name = aws_elasticache_subnet_group.this.name
  security_group_ids = [var.security_group_id]

  at_rest_encryption_enabled = true
  transit_encryption_enabled = true
  auth_token                 = random_password.auth_token.result

  snapshot_retention_limit = var.snapshot_retention_limit
  snapshot_window          = var.snapshot_window
  maintenance_window       = var.maintenance_window

  apply_immediately = var.apply_immediately

  tags = merge(local.common_tags, { Name = "${local.name_prefix}-redis" })

  lifecycle {
    precondition {
      condition     = !var.automatic_failover_enabled || var.num_cache_clusters >= 2
      error_message = "automatic_failover_enabled requires num_cache_clusters >= 2."
    }
    ignore_changes = [auth_token] # rotate via a separate, deliberate apply, not incidental diffs
  }
}
