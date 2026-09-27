output "db_instance_id" {
  value = aws_db_instance.this.id
}

output "endpoint" {
  description = "Connection endpoint, host:port."
  value       = aws_db_instance.this.endpoint
}

output "address" {
  description = "Hostname only (no port)."
  value       = aws_db_instance.this.address
}

output "port" {
  value = aws_db_instance.this.port
}

output "database_name" {
  value = aws_db_instance.this.db_name
}

output "master_username" {
  value = aws_db_instance.this.username
}

output "master_user_secret_arn" {
  description = "ARN of the RDS-managed Secrets Manager secret holding the master password. Grant read access to this ARN, never extract/copy the password elsewhere."
  value       = aws_db_instance.this.master_user_secret[0].secret_arn
}
