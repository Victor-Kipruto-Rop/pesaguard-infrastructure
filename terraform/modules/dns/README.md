# dns

Creates (or references) the Route 53 public hosted zone for a PesaGuard
domain. Intentionally minimal in this phase: **only the zone**, no records.

## ALB records (Phase 7)

`create_alb_records = true` plus `alb_dns_name` / `alb_zone_id` (from
`terraform/modules/alb/`) creates an ALIAS record per name in
`alb_record_names` (e.g. `["api", "app"]`; `""` for the apex). ACM
certificate *validation* records are handled separately, by
`terraform/modules/acm/` writing directly into this module's zone via its
own `zone_id` input — not by this module.

## One zone or one per environment?

Typically only **one** environment (usually production) should own the
apex zone (`pesaguard.victorkipruto.com`) and create it
(`create_zone = true`); other environments either:

- reuse that zone with `create_zone = false` and
  `existing_zone_id = <production's zone id>`, adding environment-specific
  subdomains (`dev.pesaguard.victorkipruto.com`) as records within it
  (Phase 7), or
- own their own delegated subdomain zone, created the same way.

This repository does not prescribe which; document the choice made for
this project in `../../../ARCHITECTURE.md` once Phase 7 records land.

## After creating the zone

If `create_zone = true`, delegate the domain at your registrar to the
`name_servers` output — otherwise the zone exists in Route 53 but nothing
on the internet will resolve to it.

## Inputs / outputs

See `variables.tf` / `outputs.tf`.

## Example

```hcl
module "dns" {
  source = "../../modules/dns"

  project     = "PesaGuard"
  environment = "production"
  create_zone = true
  domain_name = "pesaguard.victorkipruto.com"
}
```
