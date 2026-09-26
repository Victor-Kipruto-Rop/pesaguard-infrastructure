# Public hosted zone ------------------------------------------------------
# Only the zone itself is created here. Records (A/ALIAS to the ALB, ACM
# validation records, etc.) are added in Phase 7 once compute and the load
# balancer exist — creating placeholder records with no real target would
# violate this repo's "no fake infrastructure" rule.

resource "aws_route53_zone" "this" {
  count   = var.create_zone ? 1 : 0
  name    = var.domain_name
  comment = "${var.project} ${var.environment} zone — managed by Terraform (terraform/modules/dns)"

  tags = merge(
    {
      Project            = var.project
      Environment        = var.environment
      ManagedBy          = "Terraform"
      Owner              = "PesaGuard"
      Component          = "dns"
      Service            = "route53"
      CostCenter         = var.cost_center
      DataClassification = "internal"
    },
    var.additional_tags
  )
}
