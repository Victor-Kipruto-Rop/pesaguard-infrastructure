data "aws_iam_policy_document" "assume" {
  count = var.create ? 1 : 0

  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["grafana.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "this" {
  count              = var.create ? 1 : 0
  name               = "${local.name_prefix}-grafana"
  assume_role_policy = data.aws_iam_policy_document.assume[0].json
  tags               = local.common_tags
}

data "aws_iam_policy_document" "data_sources" {
  count = var.create ? 1 : 0

  statement {
    sid    = "AmpReadAccess"
    effect = "Allow"
    actions = [
      "aps:QueryMetrics", "aps:GetSeries", "aps:GetLabels", "aps:GetMetricMetadata",
      "aps:DescribeWorkspace", "aps:ListWorkspaces",
    ]
    resources = [var.amp_workspace_arn]
  }

  statement {
    sid    = "CloudWatchReadAccess"
    effect = "Allow"
    actions = [
      "cloudwatch:DescribeAlarmsForMetric", "cloudwatch:DescribeAlarmHistory",
      "cloudwatch:DescribeAlarms", "cloudwatch:ListMetrics", "cloudwatch:GetMetricData",
      "cloudwatch:GetInsightRuleReport", "logs:DescribeLogGroups", "logs:GetLogGroupFields",
      "logs:StartQuery", "logs:StopQuery", "logs:GetQueryResults", "logs:GetLogEvents",
      "ec2:DescribeTags", "ec2:DescribeInstances", "ec2:DescribeRegions",
      "tag:GetResources",
    ]
    resources = ["*"]
  }
}

resource "aws_iam_role_policy" "data_sources" {
  count  = var.create ? 1 : 0
  name   = "${local.name_prefix}-grafana-datasources"
  role   = aws_iam_role.this[0].id
  policy = data.aws_iam_policy_document.data_sources[0].json
}

resource "aws_grafana_workspace" "this" {
  count = var.create ? 1 : 0

  name                     = "${local.name_prefix}-grafana"
  account_access_type      = "CURRENT_ACCOUNT"
  authentication_providers = ["AWS_SSO"]
  permission_type          = "SERVICE_MANAGED"
  role_arn                 = aws_iam_role.this[0].arn
  data_sources             = ["PROMETHEUS", "CLOUDWATCH"]

  tags = merge(local.common_tags, { Name = "${local.name_prefix}-grafana" })
}
