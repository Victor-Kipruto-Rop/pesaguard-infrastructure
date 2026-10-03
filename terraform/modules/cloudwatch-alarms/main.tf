# --- RDS (golden signals: saturation) --------------------------------------

resource "aws_cloudwatch_metric_alarm" "rds_cpu" {
  alarm_name          = "${local.name_prefix}-rds-cpu-high"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods   = 3
  metric_name         = "CPUUtilization"
  namespace           = "AWS/RDS"
  period              = 300
  statistic           = "Average"
  threshold           = var.rds_cpu_threshold_percent
  alarm_description   = "RDS ${var.rds_instance_id} CPU above ${var.rds_cpu_threshold_percent}% for 15 minutes."
  dimensions          = { DBInstanceIdentifier = var.rds_instance_id }
  alarm_actions       = [var.database_topic_arn]
  ok_actions          = [var.database_topic_arn]
  tags                = local.common_tags
}

resource "aws_cloudwatch_metric_alarm" "rds_free_storage" {
  alarm_name          = "${local.name_prefix}-rds-storage-low"
  comparison_operator = "LessThanThreshold"
  evaluation_periods   = 1
  metric_name         = "FreeStorageSpace"
  namespace           = "AWS/RDS"
  period              = 300
  statistic           = "Minimum"
  threshold           = var.rds_free_storage_threshold_bytes
  alarm_description   = "RDS ${var.rds_instance_id} free storage below ${var.rds_free_storage_threshold_bytes} bytes."
  dimensions          = { DBInstanceIdentifier = var.rds_instance_id }
  alarm_actions       = [var.database_topic_arn]
  ok_actions          = [var.database_topic_arn]
  tags                = local.common_tags
}

resource "aws_cloudwatch_metric_alarm" "rds_connections" {
  alarm_name          = "${local.name_prefix}-rds-connections-high"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods   = 3
  metric_name         = "DatabaseConnections"
  namespace           = "AWS/RDS"
  period              = 300
  statistic           = "Average"
  threshold           = var.rds_connection_threshold_count
  alarm_description   = "RDS ${var.rds_instance_id} connection count above ${var.rds_connection_threshold_count}."
  dimensions          = { DBInstanceIdentifier = var.rds_instance_id }
  alarm_actions       = [var.database_topic_arn]
  ok_actions          = [var.database_topic_arn]
  tags                = local.common_tags
}

# --- Redis (per-node; ElastiCache publishes metrics per cache cluster) -----

resource "aws_cloudwatch_metric_alarm" "redis_cpu" {
  for_each = toset(var.redis_cache_cluster_ids)

  alarm_name          = "${local.name_prefix}-redis-${each.value}-cpu-high"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods   = 3
  metric_name         = "EngineCPUUtilization"
  namespace           = "AWS/ElastiCache"
  period              = 300
  statistic           = "Average"
  threshold           = var.redis_cpu_threshold_percent
  alarm_description   = "Redis node ${each.value} CPU above ${var.redis_cpu_threshold_percent}% for 15 minutes."
  dimensions          = { CacheClusterId = each.value }
  alarm_actions       = [var.database_topic_arn]
  ok_actions          = [var.database_topic_arn]
  tags                = local.common_tags
}

resource "aws_cloudwatch_metric_alarm" "redis_memory" {
  for_each = toset(var.redis_cache_cluster_ids)

  alarm_name          = "${local.name_prefix}-redis-${each.value}-memory-high"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods   = 3
  metric_name         = "DatabaseMemoryUsagePercentage"
  namespace           = "AWS/ElastiCache"
  period              = 300
  statistic           = "Average"
  threshold           = var.redis_memory_threshold_percent
  alarm_description   = "Redis node ${each.value} memory usage above ${var.redis_memory_threshold_percent}% for 15 minutes."
  dimensions          = { CacheClusterId = each.value }
  alarm_actions       = [var.database_topic_arn]
  ok_actions          = [var.database_topic_arn]
  tags                = local.common_tags
}

# --- MSK (cluster-level metrics only — no per-broker complexity here) ------

resource "aws_cloudwatch_metric_alarm" "msk_active_controller" {
  alarm_name          = "${local.name_prefix}-msk-active-controller-count"
  comparison_operator = "LessThanThreshold"
  evaluation_periods   = 1
  metric_name         = "ActiveControllerCount"
  namespace           = "AWS/Kafka"
  period              = 300
  statistic           = "Sum"
  threshold           = 1
  alarm_description   = "MSK ${var.msk_cluster_name} has no active controller (expected exactly 1) — cluster may be unable to manage partition state."
  dimensions          = { "Cluster Name" = var.msk_cluster_name }
  alarm_actions       = [var.messaging_topic_arn]
  ok_actions          = [var.messaging_topic_arn]
  treat_missing_data  = "breaching"
  tags                = local.common_tags
}

resource "aws_cloudwatch_metric_alarm" "msk_offline_partitions" {
  alarm_name          = "${local.name_prefix}-msk-offline-partitions"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods   = 1
  metric_name         = "OfflinePartitionsCount"
  namespace           = "AWS/Kafka"
  period              = 300
  statistic           = "Sum"
  threshold           = 0
  alarm_description   = "MSK ${var.msk_cluster_name} has offline partitions — some topics may be unavailable."
  dimensions          = { "Cluster Name" = var.msk_cluster_name }
  alarm_actions       = [var.messaging_topic_arn]
  ok_actions          = [var.messaging_topic_arn]
  tags                = local.common_tags
}

# --- ALB (golden signals: errors, latency) ---------------------------------

resource "aws_cloudwatch_metric_alarm" "alb_5xx" {
  alarm_name          = "${local.name_prefix}-alb-5xx-high"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods   = 1
  metric_name         = "HTTPCode_Target_5XX_Count"
  namespace           = "AWS/ApplicationELB"
  period              = 300
  statistic           = "Sum"
  threshold           = var.alb_5xx_threshold_count
  alarm_description   = "ALB target 5xx responses above ${var.alb_5xx_threshold_count} in 5 minutes."
  dimensions          = { LoadBalancer = var.alb_arn_suffix }
  alarm_actions       = [var.infrastructure_topic_arn]
  ok_actions          = [var.infrastructure_topic_arn]
  treat_missing_data  = "notBreaching" # no traffic is not an error
  tags                = local.common_tags
}

resource "aws_cloudwatch_metric_alarm" "alb_target_response_time" {
  alarm_name          = "${local.name_prefix}-alb-latency-high"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods   = 3
  metric_name         = "TargetResponseTime"
  namespace           = "AWS/ApplicationELB"
  period              = 300
  statistic           = "Average"
  threshold           = var.alb_target_response_time_threshold_seconds
  alarm_description   = "ALB average target response time above ${var.alb_target_response_time_threshold_seconds}s for 15 minutes."
  dimensions          = { LoadBalancer = var.alb_arn_suffix }
  alarm_actions       = [var.infrastructure_topic_arn]
  ok_actions          = [var.infrastructure_topic_arn]
  treat_missing_data  = "notBreaching"
  tags                = local.common_tags
}

# --- WAF (security signal) -------------------------------------------------

resource "aws_cloudwatch_metric_alarm" "waf_blocked_requests" {
  alarm_name          = "${local.name_prefix}-waf-blocked-spike"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods   = 1
  metric_name         = "BlockedRequests"
  namespace           = "AWS/WAFV2"
  period              = 300
  statistic           = "Sum"
  threshold           = var.waf_blocked_requests_threshold_count
  alarm_description   = "WAF blocked more than ${var.waf_blocked_requests_threshold_count} requests in 5 minutes — possible attack or misconfigured client."
  dimensions = {
    WebACL = var.waf_web_acl_name
    Region = data.aws_region.current.name
    Rule   = "ALL"
  }
  alarm_actions      = [var.security_topic_arn]
  ok_actions         = [var.security_topic_arn]
  treat_missing_data = "notBreaching"
  tags               = local.common_tags
}
