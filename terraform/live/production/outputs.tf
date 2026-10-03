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

output "dns_zone_id" {
  value = module.dns.zone_id
}

output "dns_name_servers" {
  description = "Delegate the domain at your registrar to these name servers."
  value       = module.dns.name_servers
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

output "oidc_provider_arn" {
  description = "Pass this into dev/staging's existing_oidc_provider_arn variable."
  value       = module.iam.oidc_provider_arn
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

output "backup_operator_role_arn" {
  value = module.iam.backup_operator_role_arn
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

output "msk_cluster_arn" {
  value = module.msk.cluster_arn
}

output "msk_bootstrap_brokers_sasl_iam" {
  description = "Use as BOOTSTRAP_SERVERS for scripts/messaging/apply-topics.sh."
  value       = module.msk.bootstrap_brokers_sasl_iam
}

output "glue_schema_registry_name" {
  value = module.glue_schema_registry.registry_name
}

output "ecr_repository_urls" {
  value = module.ecr.repository_urls
}

output "alb_dns_name" {
  value = module.alb.alb_dns_name
}

output "acm_certificate_arn" {
  value = module.acm.certificate_arn
}

output "waf_web_acl_arn" {
  value = module.waf.web_acl_arn
}

output "ecs_cluster_name" {
  value = module.ecs.cluster_name
}

output "sns_alert_topic_arns" {
  value = module.sns_alerts.topic_arns
}

output "amp_workspace_id" {
  value = module.amp.workspace_id
}

output "amp_remote_write_endpoint" {
  value = module.amp.remote_write_endpoint
}

output "cloudwatch_alarm_names" {
  value = module.cloudwatch_alarms.alarm_names
}
