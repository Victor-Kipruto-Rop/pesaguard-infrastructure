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

output "auth_token_secret_arn" {
  description = "Secrets Manager ARN holding the Redis AUTH token. Grant read access to the app_service IAM role; never read the token any other way."
  value       = aws_secretsmanager_secret.redis_auth.arn
}
