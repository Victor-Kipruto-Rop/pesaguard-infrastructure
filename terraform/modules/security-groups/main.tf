# Load balancer -----------------------------------------------------------

resource "aws_security_group" "alb" {
  name        = "${local.name_prefix}-alb"
  description = "ALB: public HTTPS/HTTP ingress, egress restricted to the VPC."
  vpc_id      = var.vpc_id

  ingress {
    description = "HTTPS from allowed public CIDRs"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = var.public_ingress_cidrs
  }

  ingress {
    description = "HTTP from allowed public CIDRs (redirected to HTTPS at the listener)"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = var.public_ingress_cidrs
  }

  egress {
    description = "To application tier within the VPC only"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = [var.vpc_cidr_block]
  }

  tags = merge(local.common_tags, {
    Name    = "${local.name_prefix}-alb-sg"
    Service = "load-balancer"
  })
}

# Application tier (FastAPI, Java services, workers) -----------------------

resource "aws_security_group" "app" {
  name        = "${local.name_prefix}-app"
  description = "Application tier: ingress from ALB and from itself, egress open (NAT-routed) for external APIs and data tier."
  vpc_id      = var.vpc_id

  ingress {
    description     = "From ALB"
    from_port       = var.app_port
    to_port         = var.app_port
    protocol        = "tcp"
    security_groups = [aws_security_group.alb.id]
  }

  ingress {
    description = "Service-to-service within the app tier"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    self        = true
  }

  egress {
    description = "All outbound (NAT-routed internet + data tier + AWS APIs)"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(local.common_tags, {
    Name    = "${local.name_prefix}-app-sg"
    Service = "application"
  })
}

# PostgreSQL (RDS) ----------------------------------------------------------

resource "aws_security_group" "postgres" {
  name        = "${local.name_prefix}-postgres"
  description = "PostgreSQL: ingress from the app tier only, no internet route."
  vpc_id      = var.vpc_id

  ingress {
    description     = "PostgreSQL from app tier"
    from_port       = var.postgres_port
    to_port         = var.postgres_port
    protocol        = "tcp"
    security_groups = [aws_security_group.app.id]
  }

  egress {
    description = "Restricted to VPC (no internet egress needed for RDS)"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = [var.vpc_cidr_block]
  }

  tags = merge(local.common_tags, {
    Name    = "${local.name_prefix}-postgres-sg"
    Service = "postgresql"
  })
}

# Redis ----------------------------------------------------------------

resource "aws_security_group" "redis" {
  name        = "${local.name_prefix}-redis"
  description = "Redis: ingress from the app tier only, no internet route."
  vpc_id      = var.vpc_id

  ingress {
    description     = "Redis from app tier"
    from_port       = var.redis_port
    to_port         = var.redis_port
    protocol        = "tcp"
    security_groups = [aws_security_group.app.id]
  }

  egress {
    description = "Restricted to VPC"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = [var.vpc_cidr_block]
  }

  tags = merge(local.common_tags, {
    Name    = "${local.name_prefix}-redis-sg"
    Service = "redis"
  })
}

# Kafka / Redpanda + Schema Registry ----------------------------------------

resource "aws_security_group" "kafka" {
  name        = "${local.name_prefix}-kafka"
  description = "Kafka/Redpanda brokers + Schema Registry: ingress from app tier and broker-to-broker, no internet route."
  vpc_id      = var.vpc_id

  dynamic "ingress" {
    for_each = var.kafka_ports
    content {
      description     = "Kafka broker port ${ingress.value} from app tier"
      from_port       = ingress.value
      to_port         = ingress.value
      protocol        = "tcp"
      security_groups = [aws_security_group.app.id]
    }
  }

  ingress {
    description = "Broker-to-broker replication"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    self        = true
  }

  ingress {
    description     = "Schema Registry from app tier"
    from_port       = var.schema_registry_port
    to_port         = var.schema_registry_port
    protocol        = "tcp"
    security_groups = [aws_security_group.app.id]
  }

  egress {
    description = "Restricted to VPC"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = [var.vpc_cidr_block]
  }

  tags = merge(local.common_tags, {
    Name    = "${local.name_prefix}-kafka-sg"
    Service = "messaging"
  })
}

# Monitoring / observability -------------------------------------------

resource "aws_security_group" "monitoring" {
  name        = "${local.name_prefix}-monitoring"
  description = "Prometheus/Grafana/Alertmanager: reachable only from within the VPC; egress open for external alert notifications."
  vpc_id      = var.vpc_id

  dynamic "ingress" {
    for_each = var.monitoring_ports
    content {
      description = "Monitoring port ${ingress.value} from within the VPC"
      from_port   = ingress.value
      to_port     = ingress.value
      protocol    = "tcp"
      cidr_blocks = [var.vpc_cidr_block]
    }
  }

  egress {
    description = "All outbound (needed for alert notification integrations, e.g. email/Slack/PagerDuty)"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(local.common_tags, {
    Name    = "${local.name_prefix}-monitoring-sg"
    Service = "observability"
  })
}
