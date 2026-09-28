output "cluster_arn" {
  value = aws_msk_cluster.this.arn
}

output "cluster_name" {
  value = aws_msk_cluster.this.cluster_name
}

output "bootstrap_brokers_sasl_iam" {
  description = "IAM-auth bootstrap broker string (port 9098) — the only broker endpoint this cluster exposes."
  value       = aws_msk_cluster.this.bootstrap_brokers_sasl_iam
}

output "broker_log_group_name" {
  value = aws_cloudwatch_log_group.broker_logs.name
}

output "configuration_arn" {
  value = aws_msk_configuration.this.arn
}
