output "alb_security_group_id" {
  description = "Security group ID for the load balancer."
  value       = aws_security_group.alb.id
}

output "app_security_group_id" {
  description = "Security group ID for the application tier."
  value       = aws_security_group.app.id
}

output "postgres_security_group_id" {
  description = "Security group ID for PostgreSQL (RDS)."
  value       = aws_security_group.postgres.id
}

output "redis_security_group_id" {
  description = "Security group ID for Redis."
  value       = aws_security_group.redis.id
}

output "kafka_security_group_id" {
  description = "Security group ID for Kafka/Redpanda + Schema Registry."
  value       = aws_security_group.kafka.id
}

output "monitoring_security_group_id" {
  description = "Security group ID for the observability stack."
  value       = aws_security_group.monitoring.id
}
