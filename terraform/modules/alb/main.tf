resource "aws_lb" "this" {
  name               = "${local.name_prefix}-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [var.security_group_id]
  subnets            = var.public_subnet_ids

  idle_timeout               = var.idle_timeout_seconds
  enable_deletion_protection = var.enable_deletion_protection
  drop_invalid_header_fields = true

  # Access logging deferred: writing it correctly means adding an
  # ALB-log-delivery bucket policy statement to a bucket already managed
  # (and policy-owned) by terraform/modules/object-storage, and this repo
  # avoids two modules both declaring aws_s3_bucket_policy for the same
  # bucket. Revisit alongside Phase 8/9 observability work.

  tags = merge(local.common_tags, { Name = "${local.name_prefix}-alb" })
}

# HTTP listener: redirects to HTTPS when a certificate is configured,
# otherwise serves a fixed placeholder response directly (HTTP-only —
# see README for when this applies).
resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.this.arn
  port              = 80
  protocol          = "HTTP"

  dynamic "default_action" {
    for_each = local.enable_https ? [1] : []
    content {
      type = "redirect"
      redirect {
        port        = "443"
        protocol    = "HTTPS"
        status_code = "HTTP_301"
      }
    }
  }

  dynamic "default_action" {
    for_each = local.enable_https ? [] : [1]
    content {
      type = "fixed-response"
      fixed_response {
        content_type = "application/json"
        message_body = local.no_service_message
        status_code  = "503"
      }
    }
  }

  tags = local.common_tags
}

resource "aws_lb_listener" "https" {
  count = local.enable_https ? 1 : 0

  load_balancer_arn = aws_lb.this.arn
  port              = 443
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-TLS13-1-2-2021-06"
  certificate_arn   = var.certificate_arn

  default_action {
    type = "fixed-response"
    fixed_response {
      content_type = "application/json"
      message_body = local.no_service_message
      status_code  = "503"
    }
  }

  tags = local.common_tags
}
