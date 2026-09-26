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
