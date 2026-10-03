output "alarm_names" {
  value = concat(
    [
      aws_cloudwatch_metric_alarm.rds_cpu.alarm_name,
      aws_cloudwatch_metric_alarm.rds_free_storage.alarm_name,
      aws_cloudwatch_metric_alarm.rds_connections.alarm_name,
      aws_cloudwatch_metric_alarm.msk_active_controller.alarm_name,
      aws_cloudwatch_metric_alarm.msk_offline_partitions.alarm_name,
      aws_cloudwatch_metric_alarm.alb_5xx.alarm_name,
      aws_cloudwatch_metric_alarm.alb_target_response_time.alarm_name,
      aws_cloudwatch_metric_alarm.waf_blocked_requests.alarm_name,
    ],
    [for a in aws_cloudwatch_metric_alarm.redis_cpu : a.alarm_name],
    [for a in aws_cloudwatch_metric_alarm.redis_memory : a.alarm_name],
  )
}
