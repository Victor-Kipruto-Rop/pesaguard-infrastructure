output "secrets_key_id" {
  value = aws_kms_key.secrets.key_id
}

output "secrets_key_arn" {
  value = aws_kms_key.secrets.arn
}

output "logs_key_id" {
  value = aws_kms_key.logs.key_id
}

output "logs_key_arn" {
  value = aws_kms_key.logs.arn
}

output "backups_key_id" {
  value = aws_kms_key.backups.key_id
}

output "backups_key_arn" {
  value = aws_kms_key.backups.arn
}

output "database_key_id" {
  value = aws_kms_key.database.key_id
}

output "database_key_arn" {
  value = aws_kms_key.database.arn
}

output "messaging_key_id" {
  value = aws_kms_key.messaging.key_id
}

output "messaging_key_arn" {
  value = aws_kms_key.messaging.arn
}
