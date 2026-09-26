# dns

Creates (or references) the Route 53 public hosted zone for a PesaGuard
domain. Intentionally minimal in this phase: **only the zone**, no records.

## Why no records yet

Records like `api.pesaguard.victorkipruto.com` need something real to
point at (an ALB DNS name, an ACM validation CNAME). Neither exists until
Phase 4 (ACM) and Phase 7 (load balancer) are implemented. Creating
placeholder A records pointing nowhere would be exactly the kind of fake
infrastructure this repository's implementation rules prohibit — so
`records.tf` is added to this module in Phase 7, not now.

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
