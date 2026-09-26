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
