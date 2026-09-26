locals {
  az_count = length(var.availability_zones)

  # /16 VPC carved into /20 subnets (newbits = 20 - 16 = 4 -> 16 possible
  # /20s, netnum 0-15). Supports up to 4 AZs across 3 tiers (12 of 16 used).
  public_subnet_cidrs = [
    for i in range(local.az_count) : cidrsubnet(var.vpc_cidr, 4, i)
  ]
  app_subnet_cidrs = [
    for i in range(local.az_count) : cidrsubnet(var.vpc_cidr, 4, 4 + i)
  ]
  data_subnet_cidrs = [
    for i in range(local.az_count) : cidrsubnet(var.vpc_cidr, 4, 8 + i)
  ]

  nat_gateway_count = var.single_nat_gateway ? 1 : local.az_count

  common_tags = merge(
    {
      Project            = var.project
      Environment        = var.environment
      ManagedBy          = "Terraform"
      Owner              = "PesaGuard"
      Component          = "networking"
      CostCenter         = var.cost_center
      DataClassification = "internal"
    },
    var.additional_tags
  )
}
