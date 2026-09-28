resource "aws_glue_registry" "this" {
  registry_name = "${local.name_prefix}-schemas"
  description   = "${var.project} ${var.environment} event schema registry (Avro/JSON/Protobuf). Schemas are registered by application repositories, not defined here."

  tags = local.common_tags
}

# Private connectivity so app-tier calls to the Glue API don't route
# through NAT. Optional: Glue is also reachable over the public AWS API
# endpoint via NAT if this is disabled (e.g. to save cost in dev).

resource "aws_security_group" "endpoint" {
  count       = var.create_vpc_endpoint ? 1 : 0
  name        = "${local.name_prefix}-glue-endpoint"
  description = "Allows the app tier to reach the Glue Schema Registry interface VPC endpoint on 443."
  vpc_id      = var.vpc_id

  ingress {
    description     = "HTTPS from app tier"
    from_port       = 443
    to_port         = 443
    protocol        = "tcp"
    security_groups = [var.app_security_group_id]
  }

  egress {
    description = "Restricted to VPC"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = [var.vpc_cidr_block]
  }

  tags = merge(local.common_tags, { Name = "${local.name_prefix}-glue-endpoint-sg" })
}

resource "aws_vpc_endpoint" "glue" {
  count               = var.create_vpc_endpoint ? 1 : 0
  vpc_id              = var.vpc_id
  service_name        = "com.amazonaws.${data.aws_region.current.name}.glue"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = var.subnet_ids
  security_group_ids  = [aws_security_group.endpoint[0].id]
  private_dns_enabled = true

  tags = merge(local.common_tags, { Name = "${local.name_prefix}-glue-endpoint" })
}
