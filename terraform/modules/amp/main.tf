resource "aws_cloudwatch_log_group" "amp" {
  name              = "/pesaguard/${var.environment}/amp"
  retention_in_days = var.log_retention_days
  kms_key_id        = var.logs_kms_key_arn

  tags = local.common_tags
}

resource "aws_prometheus_workspace" "this" {
  alias = "${local.name_prefix}-amp"

  logging_configuration {
    log_group_arn = "${aws_cloudwatch_log_group.amp.arn}:*"
  }

  tags = merge(local.common_tags, { Name = "${local.name_prefix}-amp" })
}

# Starter rule group — a template, not a finished alerting suite. "up"
# requires something to be remote_write-ing Prometheus metrics into this
# workspace at all (e.g. an ADOT sidecar on a real ECS service), which
# does not exist yet — see README.md. Replace/extend once real services
# and their metric names exist.
resource "aws_prometheus_rule_group_namespace" "starter" {
  name         = "${local.name_prefix}-starter-rules"
  workspace_id = aws_prometheus_workspace.this.id

  data = <<-YAML
    groups:
      - name: starter
        rules:
          - alert: TargetDown
            expr: up == 0
            for: 5m
            labels:
              severity: critical
            annotations:
              summary: "A scrape target has been down for 5 minutes"
  YAML
}

resource "aws_prometheus_alert_manager_definition" "this" {
  workspace_id = aws_prometheus_workspace.this.id

  definition = <<-YAML
    route:
      receiver: sns-default
      group_by: ["alertname"]
      group_wait: 30s
      group_interval: 5m
      repeat_interval: 4h
    receivers:
      - name: sns-default
        sns_configs:
          - topic_arn: ${var.security_topic_arn}
            sigv4:
              region: ${var.sns_region}
  YAML
}
