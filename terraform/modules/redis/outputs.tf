output "primary_endpoint_address" {
  value = aws_elasticache_replication_group.this.primary_endpoint_address
}

output "reader_endpoint_address" {
  description = "Reader endpoint (only meaningful when num_cache_clusters >= 2)."
  value       = try(aws_elasticache_replication_group.this.reader_endpoint_address, null)
}

output "port" {
  value = aws_elasticache_replication_group.this.port
}

output "member_cluster_ids" {
  description = "Individual cache cluster (node) IDs in this replication group, e.g. [\"pesaguard-production-redis-001\", \"...-002\"]. ElastiCache CloudWatch metrics are published per node, not per replication group, so alarms need these."
  value       = aws_elasticache_replication_group.this.member_clusters
}

output "auth_token_secret_arn" {
  description = "Secrets Manager ARN holding the Redis AUTH token. Grant read access to the app_service IAM role; never read the token any other way."
  value       = aws_secretsmanager_secret.redis_auth.arn
}
