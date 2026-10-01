# Public hosted zone ------------------------------------------------------
# Only the zone itself was created in Phase 3. Phase 7 adds real ALB alias
# records below, now that an ALB actually exists to point at.

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

locals {
  # The zone this module is responsible for, whether it created that zone
  # or was told to reuse an existing one.
  zone_id = var.create_zone ? aws_route53_zone.this[0].zone_id : var.existing_zone_id
}

# ALB alias records --------------------------------------------------------
# One per name in alb_record_names; "" means the apex (domain_name itself).
# ALIAS (not CNAME) so the apex can be included and so Route 53 resolves
# it without an extra lookup, at no additional query cost.

resource "aws_route53_record" "alb_alias" {
  for_each = var.create_alb_records ? toset(var.alb_record_names) : []

  zone_id = local.zone_id
  name    = each.value == "" ? var.domain_name : "${each.value}.${var.domain_name}"
  type    = "A"

  alias {
    name                   = var.alb_dns_name
    zone_id                = var.alb_zone_id
    evaluate_target_health = true
  }
}

