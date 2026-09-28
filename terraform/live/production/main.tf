module "networking" {
  source = "../../modules/networking"

  project             = var.project
  environment         = var.environment
  vpc_cidr            = var.vpc_cidr
  availability_zones  = var.availability_zones
  single_nat_gateway  = false # one NAT gateway per AZ for production HA
}

module "security_groups" {
  source = "../../modules/security-groups"

  project        = var.project
  environment    = var.environment
  vpc_id         = module.networking.vpc_id
  vpc_cidr_block = module.networking.vpc_cidr_block
}

module "dns" {
  source = "../../modules/dns"

  project     = var.project
  environment = var.environment
  create_zone = var.create_dns_zone
  domain_name = var.domain_name
}

module "kms" {
  source = "../../modules/kms"

  project     = var.project
  environment = var.environment
}

module "secrets" {
  source = "../../modules/secrets"

  project      = var.project
  environment  = var.environment
  kms_key_arn  = module.kms.secrets_key_arn
  secret_names = var.secret_names
}

module "iam" {
  source = "../../modules/iam"

  project     = var.project
  environment = var.environment
  region      = var.region

  # Production owns the account-wide GitHub OIDC provider. Other
  # environments reference its ARN via existing_oidc_provider_arn.
  create_oidc_provider = true
  github_org            = var.github_org
  github_repo           = var.github_repo
  allowed_github_refs   = var.allowed_github_refs

  secrets_kms_key_arn  = module.kms.secrets_key_arn
  logs_kms_key_arn     = module.kms.logs_key_arn
  backups_kms_key_arn  = module.kms.backups_key_arn
  database_kms_key_arn = module.kms.database_key_arn

  state_bucket_arn = local.state_bucket_arn
  lock_table_arn   = local.lock_table_arn

  secret_arns = concat(
    values(module.secrets.secret_arns),
    [module.rds.master_user_secret_arn, module.redis.auth_token_secret_arn],
  )
  app_s3_bucket_arns    = values(module.object_storage.bucket_arns)
  backup_s3_bucket_arns = [module.object_storage.bucket_arns["backups"]]

  # Booleans are literals (known at plan time); the ARNs are not.
  enable_msk_access           = true
  msk_cluster_arn             = module.msk.cluster_arn
  enable_glue_registry_access = true
  glue_registry_arn           = module.glue_schema_registry.registry_arn
}

module "msk" {
  source = "../../modules/msk"

  project           = var.project
  environment       = var.environment
  subnet_ids        = module.networking.data_subnet_ids
  security_group_id = module.security_groups.kafka_security_group_id
  kms_key_arn       = module.kms.messaging_key_arn
  logs_kms_key_arn  = module.kms.logs_key_arn

  broker_instance_type   = var.msk_broker_instance_type
  number_of_broker_nodes = var.msk_number_of_broker_nodes
  broker_ebs_volume_size = var.msk_broker_ebs_volume_size
}

module "glue_schema_registry" {
  source = "../../modules/glue-schema-registry"

  project               = var.project
  environment           = var.environment
  vpc_id                = module.networking.vpc_id
  vpc_cidr_block        = module.networking.vpc_cidr_block
  subnet_ids            = module.networking.app_subnet_ids
  app_security_group_id = module.security_groups.app_security_group_id
}

module "object_storage" {
  source = "../../modules/object-storage"

  project     = var.project
  environment = var.environment
  kms_key_arn = module.kms.backups_key_arn
}

module "rds" {
  source = "../../modules/rds"

  project             = var.project
  environment         = var.environment
  subnet_ids          = module.networking.data_subnet_ids
  security_group_id   = module.security_groups.postgres_security_group_id
  storage_kms_key_arn = module.kms.database_key_arn
  secrets_kms_key_arn = module.kms.secrets_key_arn

  instance_class          = var.rds_instance_class
  multi_az                = var.rds_multi_az
  deletion_protection     = var.rds_deletion_protection
  skip_final_snapshot     = var.rds_skip_final_snapshot
  backup_retention_period = var.rds_backup_retention_period
}

module "redis" {
  source = "../../modules/redis"

  project             = var.project
  environment         = var.environment
  subnet_ids          = module.networking.data_subnet_ids
  security_group_id   = module.security_groups.redis_security_group_id
  secrets_kms_key_arn = module.kms.secrets_key_arn

  node_type                  = var.redis_node_type
  num_cache_clusters         = var.redis_num_cache_clusters
  automatic_failover_enabled = var.redis_automatic_failover_enabled
}
