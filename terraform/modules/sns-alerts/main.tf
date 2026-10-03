# One SNS topic per alert category. No subscriptions are created here —
# see README.md for why.

resource "aws_sns_topic" "this" {
  for_each = toset(var.topics)

  name              = "${var.project}-${var.environment}-alerts-${each.value}"
  kms_master_key_id = var.kms_key_arn

  tags = merge(
    {
      Project            = var.project
      Environment        = var.environment
      ManagedBy          = "Terraform"
      Owner              = "PesaGuard"
      Component          = "alerting"
      Category           = each.value
      CostCenter         = var.cost_center
      DataClassification = "internal"
    },
    var.additional_tags
  )
}

# Allow the services that actually publish alarms (CloudWatch Alarms, AMP
# Alertmanager) to do so. Both are same-account AWS services publishing
# to a specific topic ARN — scoped accordingly, not a wildcard principal.

data "aws_iam_policy_document" "topic_policy" {
  for_each = aws_sns_topic.this

  statement {
    sid     = "AllowCloudWatchAlarms"
    effect  = "Allow"
    actions = ["sns:Publish"]
    principals {
      type        = "Service"
      identifiers = ["cloudwatch.amazonaws.com"]
    }
    resources = [each.value.arn]
  }

  statement {
    sid     = "AllowAmpAlertManager"
    effect  = "Allow"
    actions = ["sns:Publish"]
    principals {
      type        = "Service"
      identifiers = ["aps.amazonaws.com"]
    }
    resources = [each.value.arn]
  }
}

resource "aws_sns_topic_policy" "this" {
  for_each = aws_sns_topic.this
  arn      = each.value.arn
  policy   = data.aws_iam_policy_document.topic_policy[each.key].json
}
