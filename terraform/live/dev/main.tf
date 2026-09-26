module "networking" {
  source = "../../modules/networking"

  project             = var.project
  environment         = var.environment
  vpc_cidr            = var.vpc_cidr
  availability_zones  = var.availability_zones
  single_nat_gateway  = true # cheaper for dev; production uses one per AZ
}

module "security_groups" {
  source = "../../modules/security-groups"

  project        = var.project
  environment    = var.environment
  vpc_id         = module.networking.vpc_id
  vpc_cidr_block = module.networking.vpc_cidr_block
}

# DNS: development does not own the apex zone — it reuses production's
# zone (once Phase 7 creates it) for a dev.pesaguard.* subdomain, or is
# left unset until then.
