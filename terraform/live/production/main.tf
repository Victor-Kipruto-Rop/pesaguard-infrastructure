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

  secret_arns = values(module.secrets.secret_arns)
}
