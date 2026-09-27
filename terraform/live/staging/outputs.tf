output "vpc_id" {
  value = module.networking.vpc_id
}

output "public_subnet_ids" {
  value = module.networking.public_subnet_ids
}

output "app_subnet_ids" {
  value = module.networking.app_subnet_ids
}

output "data_subnet_ids" {
  value = module.networking.data_subnet_ids
}

output "alb_security_group_id" {
  value = module.security_groups.alb_security_group_id
}

output "app_security_group_id" {
  value = module.security_groups.app_security_group_id
}

output "postgres_security_group_id" {
  value = module.security_groups.postgres_security_group_id
}

output "redis_security_group_id" {
  value = module.security_groups.redis_security_group_id
}

output "kafka_security_group_id" {
  value = module.security_groups.kafka_security_group_id
}

output "monitoring_security_group_id" {
  value = module.security_groups.monitoring_security_group_id
}

output "secrets_kms_key_arn" {
  value = module.kms.secrets_key_arn
}

output "logs_kms_key_arn" {
  value = module.kms.logs_key_arn
}

output "backups_kms_key_arn" {
  value = module.kms.backups_key_arn
}

output "database_kms_key_arn" {
  value = module.kms.database_key_arn
}

output "secret_arns" {
  value = module.secrets.secret_arns
}

output "terraform_ci_role_arn" {
  value = module.iam.terraform_ci_role_arn
}

output "app_service_instance_profile_name" {
  value = module.iam.app_service_instance_profile_name
}

output "monitoring_instance_profile_name" {
  value = module.iam.monitoring_instance_profile_name
}

output "rds_endpoint" {
  value = module.rds.endpoint
}

output "rds_master_user_secret_arn" {
  value = module.rds.master_user_secret_arn
}

output "redis_primary_endpoint" {
  value = module.redis.primary_endpoint_address
}

output "redis_auth_token_secret_arn" {
  value = module.redis.auth_token_secret_arn
}

output "object_storage_bucket_names" {
  value = module.object_storage.bucket_names
}
