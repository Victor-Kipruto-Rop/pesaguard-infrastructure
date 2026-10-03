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

  enable_observability_access = true
  amp_workspace_arn           = module.amp.workspace_arn
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

module "ecr" {
  source = "../../modules/ecr"

  project     = var.project
  environment = var.environment
}

module "acm" {
  source = "../../modules/acm"

  project     = var.project
  environment = var.environment
  domain_name = var.domain_name
  subject_alternative_names = [
    "api.${var.domain_name}",
    "app.${var.domain_name}",
  ]
  zone_id = module.dns.zone_id
}

module "alb" {
  source = "../../modules/alb"

  project             = var.project
  environment         = var.environment
  vpc_id              = module.networking.vpc_id
  public_subnet_ids   = module.networking.public_subnet_ids
  security_group_id   = module.security_groups.alb_security_group_id
  certificate_arn     = module.acm.certificate_arn

  enable_deletion_protection = true
}

module "waf" {
  source = "../../modules/waf"

  project          = var.project
  environment      = var.environment
  alb_arn          = module.alb.alb_arn
  logs_kms_key_arn = module.kms.logs_key_arn
}

# Second instance of the dns module: writes ALB alias records into the
# zone the first instance (module.dns) created. Split out to avoid a
# dependency cycle (dns -> alb -> acm -> dns) that would result from a
# single module handling both the zone and its ALB-dependent records.
module "dns_records" {
  source = "../../modules/dns"

  project           = var.project
  environment       = var.environment
  create_zone       = false
  existing_zone_id  = module.dns.zone_id
  domain_name       = var.domain_name

  create_alb_records = true
  alb_dns_name       = module.alb.alb_dns_name
  alb_zone_id        = module.alb.alb_zone_id
  alb_record_names   = ["", "api", "app"]
}

module "ecs" {
  source = "../../modules/ecs"

  project                = var.project
  environment            = var.environment
  vpc_id                 = module.networking.vpc_id
  app_subnet_ids         = module.networking.app_subnet_ids
  app_security_group_id  = module.security_groups.app_security_group_id
  listener_arn           = module.alb.primary_listener_arn
  task_role_arn          = module.iam.app_service_role_arn
  secrets_kms_key_arn    = module.kms.secrets_key_arn
  logs_kms_key_arn       = module.kms.logs_key_arn

  # services intentionally left at its default ({}) — see
  # terraform/modules/ecs/README.md for why.
}

module "sns_alerts" {
  source = "../../modules/sns-alerts"

  project     = var.project
  environment = var.environment
  kms_key_arn = module.kms.secrets_key_arn
}

module "amp" {
  source = "../../modules/amp"

  project            = var.project
  environment        = var.environment
  logs_kms_key_arn   = module.kms.logs_key_arn
  security_topic_arn = module.sns_alerts.topic_arns["security"]
  sns_region         = var.region
}

module "cloudwatch_alarms" {
  source = "../../modules/cloudwatch-alarms"

  project     = var.project
  environment = var.environment

  database_topic_arn       = module.sns_alerts.topic_arns["database"]
  messaging_topic_arn      = module.sns_alerts.topic_arns["messaging"]
  infrastructure_topic_arn = module.sns_alerts.topic_arns["infrastructure"]
  security_topic_arn       = module.sns_alerts.topic_arns["security"]

  rds_instance_id         = module.rds.db_instance_id
  redis_cache_cluster_ids = module.redis.member_cluster_ids
  msk_cluster_name        = module.msk.cluster_name
  alb_arn_suffix          = module.alb.alb_arn_suffix
  waf_web_acl_name        = "${var.project}-${var.environment}-waf"
}

module "grafana" {
  source = "../../modules/grafana"

  project     = var.project
  environment = var.environment
  # create left at its default (false) -- requires IAM Identity Center
  # pre-enabled; see terraform/modules/grafana/README.md.
  amp_workspace_arn = module.amp.workspace_arn
}
