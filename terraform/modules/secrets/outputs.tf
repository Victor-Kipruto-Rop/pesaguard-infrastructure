output "secret_arns" {
  description = "Map of secret_name => ARN, for wiring into iam module policies (var.secret_arns)."
  value       = { for name, s in aws_secretsmanager_secret.this : name => s.arn }
}

output "secret_names_full" {
  description = "Map of secret_name => full Secrets Manager name (<project>/<environment>/<name>)."
  value       = { for name, s in aws_secretsmanager_secret.this : name => s.name }
}
