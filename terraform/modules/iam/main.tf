# GitHub OIDC provider ----------------------------------------------------
# Account-wide resource. Only create where var.create_oidc_provider = true
# (see variable description). Eliminates the need for long-lived AWS
# access keys in GitHub Actions.

resource "aws_iam_openid_connect_provider" "github" {
  count = var.create_oidc_provider ? 1 : 0

  url             = "https://token.actions.githubusercontent.com"
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = [data.tls_certificate.github[0].certificates[0].sha1_fingerprint]

  tags = merge(local.common_tags, { Name = "github-actions-oidc" })
}

# CI/CD role (Terraform plan/apply from GitHub Actions) --------------------

data "aws_iam_policy_document" "terraform_ci_trust" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRoleWithWebIdentity"]

    principals {
      type        = "Federated"
      identifiers = [local.oidc_provider_arn]
    }

    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:aud"
      values   = ["sts.amazonaws.com"]
    }

    condition {
      test     = "StringLike"
      variable = "token.actions.githubusercontent.com:sub"
      values   = [for ref in var.allowed_github_refs : "repo:${var.github_org}/${var.github_repo}:${ref}"]
    }
  }
}

resource "aws_iam_role" "terraform_ci" {
  name                 = "${local.name_prefix}-terraform-ci"
  assume_role_policy   = data.aws_iam_policy_document.terraform_ci_trust.json
  max_session_duration = 3600

  tags = merge(local.common_tags, { Name = "${local.name_prefix}-terraform-ci", Service = "ci-cd" })
}

# Scoped to what this repository's modules actually manage so far
# (Phases 1-4). Expand as later phases add RDS/ElastiCache/ECS/etc.
data "aws_iam_policy_document" "terraform_ci" {
  statement {
    sid    = "TerraformStateAccess"
    effect = "Allow"
    actions = [
      "s3:GetObject", "s3:PutObject", "s3:DeleteObject", "s3:ListBucket",
    ]
    resources = [var.state_bucket_arn, "${var.state_bucket_arn}/*"]
  }

  statement {
    sid       = "TerraformStateLock"
    effect    = "Allow"
    actions   = ["dynamodb:GetItem", "dynamodb:PutItem", "dynamodb:DeleteItem"]
    resources = [var.lock_table_arn]
  }

  statement {
    sid    = "NetworkingManagement"
    effect = "Allow"
    actions = [
      "ec2:Describe*",
      "ec2:CreateVpc", "ec2:DeleteVpc", "ec2:ModifyVpcAttribute",
      "ec2:CreateSubnet", "ec2:DeleteSubnet", "ec2:ModifySubnetAttribute",
      "ec2:CreateInternetGateway", "ec2:DeleteInternetGateway",
      "ec2:AttachInternetGateway", "ec2:DetachInternetGateway",
      "ec2:CreateNatGateway", "ec2:DeleteNatGateway",
      "ec2:AllocateAddress", "ec2:ReleaseAddress", "ec2:AssociateAddress",
      "ec2:CreateRouteTable", "ec2:DeleteRouteTable", "ec2:CreateRoute",
      "ec2:DeleteRoute", "ec2:AssociateRouteTable", "ec2:DisassociateRouteTable",
      "ec2:CreateSecurityGroup", "ec2:DeleteSecurityGroup",
      "ec2:AuthorizeSecurityGroupIngress", "ec2:AuthorizeSecurityGroupEgress",
      "ec2:RevokeSecurityGroupIngress", "ec2:RevokeSecurityGroupEgress",
      "ec2:CreateVpcEndpoint", "ec2:DeleteVpcEndpoints",
      "ec2:CreateFlowLogs", "ec2:DeleteFlowLogs",
      "ec2:CreateTags", "ec2:DeleteTags",
    ]
    resources = ["*"] # EC2 networking APIs do not support resource-level ARN scoping for most of these actions
  }

  statement {
    sid       = "Route53Management"
    effect    = "Allow"
    actions   = ["route53:*"]
    resources = ["*"] # Route 53 zones are global; scope narrowed once the zone ID is known outside this bootstrap-level policy
  }

  statement {
    sid    = "KmsManagement"
    effect = "Allow"
    actions = [
      "kms:CreateKey", "kms:CreateAlias", "kms:DeleteAlias", "kms:DescribeKey",
      "kms:PutKeyPolicy", "kms:GetKeyPolicy", "kms:EnableKeyRotation",
      "kms:GetKeyRotationStatus", "kms:ListAliases", "kms:ListResourceTags",
      "kms:TagResource", "kms:ScheduleKeyDeletion", "kms:CancelKeyDeletion",
    ]
    resources = ["*"]
  }

  statement {
    sid    = "IamManagement"
    effect = "Allow"
    actions = [
      "iam:GetRole", "iam:CreateRole", "iam:DeleteRole", "iam:UpdateRole",
      "iam:TagRole", "iam:UntagRole", "iam:PutRolePolicy", "iam:GetRolePolicy",
      "iam:DeleteRolePolicy", "iam:AttachRolePolicy", "iam:DetachRolePolicy",
      "iam:ListRolePolicies", "iam:ListAttachedRolePolicies",
      "iam:CreateInstanceProfile", "iam:DeleteInstanceProfile",
      "iam:AddRoleToInstanceProfile", "iam:RemoveRoleFromInstanceProfile",
      "iam:GetInstanceProfile", "iam:GetOpenIDConnectProvider",
      "iam:CreateOpenIDConnectProvider", "iam:DeleteOpenIDConnectProvider",
      "iam:PassRole",
    ]
    resources = [
      "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/${var.project}-*",
      "arn:aws:iam::${data.aws_caller_identity.current.account_id}:instance-profile/${var.project}-*",
      "arn:aws:iam::${data.aws_caller_identity.current.account_id}:oidc-provider/token.actions.githubusercontent.com",
    ]
  }

  statement {
    sid       = "SecretsManagerManagement"
    effect    = "Allow"
    actions   = ["secretsmanager:CreateSecret", "secretsmanager:DeleteSecret", "secretsmanager:DescribeSecret", "secretsmanager:TagResource", "secretsmanager:PutSecretValue", "secretsmanager:GetSecretValue"]
    resources = ["arn:aws:secretsmanager:${var.region}:${data.aws_caller_identity.current.account_id}:secret:${var.project}/${var.environment}/*"]
  }

  statement {
    sid       = "CloudWatchLogsManagement"
    effect    = "Allow"
    actions   = ["logs:CreateLogGroup", "logs:DeleteLogGroup", "logs:DescribeLogGroups", "logs:PutRetentionPolicy", "logs:TagResource", "logs:ListTagsForResource"]
    resources = ["arn:aws:logs:${var.region}:${data.aws_caller_identity.current.account_id}:log-group:/pesaguard/${var.environment}/*"]
  }
}

resource "aws_iam_role_policy" "terraform_ci" {
  name   = "${local.name_prefix}-terraform-ci-policy"
  role   = aws_iam_role.terraform_ci.id
  policy = data.aws_iam_policy_document.terraform_ci.json
}

# Application-tier role (FastAPI / Java services / workers) ----------------
# Assumable by either ECS tasks or EC2 instances, so this role works
# whichever compute strategy Phase 7 chooses.

data "aws_iam_policy_document" "app_service_trust" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["ecs-tasks.amazonaws.com", "ec2.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "app_service" {
  name               = "${local.name_prefix}-app-service"
  assume_role_policy = data.aws_iam_policy_document.app_service_trust.json

  tags = merge(local.common_tags, { Name = "${local.name_prefix}-app-service", Service = "application" })
}

resource "aws_iam_instance_profile" "app_service" {
  name = "${local.name_prefix}-app-service"
  role = aws_iam_role.app_service.name
}

# SSM Session Manager instead of SSH for administrative access.
resource "aws_iam_role_policy_attachment" "app_service_ssm" {
  role       = aws_iam_role.app_service.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

data "aws_iam_policy_document" "app_service" {
  statement {
    sid       = "DecryptSecrets"
    effect    = "Allow"
    actions   = ["kms:Decrypt", "kms:DescribeKey"]
    resources = [var.secrets_kms_key_arn]
  }

  statement {
    sid       = "ReadSecrets"
    effect    = "Allow"
    actions   = ["secretsmanager:GetSecretValue", "secretsmanager:DescribeSecret"]
    resources = length(local.secret_resources) > 0 ? local.secret_resources : ["arn:aws:secretsmanager:${var.region}:${data.aws_caller_identity.current.account_id}:secret:${var.project}/${var.environment}/*"]
  }

  statement {
    sid       = "WriteLogs"
    effect    = "Allow"
    actions   = ["logs:CreateLogStream", "logs:PutLogEvents", "logs:DescribeLogStreams"]
    resources = ["arn:aws:logs:${var.region}:${data.aws_caller_identity.current.account_id}:log-group:/pesaguard/${var.environment}/*"]
  }

  statement {
    sid       = "EncryptLogs"
    effect    = "Allow"
    actions   = ["kms:GenerateDataKey", "kms:Decrypt"]
    resources = [var.logs_kms_key_arn]
  }

  statement {
    sid       = "PublishMetrics"
    effect    = "Allow"
    actions   = ["cloudwatch:PutMetricData"]
    resources = ["*"] # CloudWatch PutMetricData does not support resource-level scoping
    condition {
      test     = "StringEquals"
      variable = "cloudwatch:namespace"
      values   = ["PesaGuard/${var.environment}"]
    }
  }

  dynamic "statement" {
    for_each = length(local.app_s3_resources) > 0 ? [1] : []
    content {
      sid       = "AppObjectStorage"
      effect    = "Allow"
      actions   = ["s3:GetObject", "s3:PutObject", "s3:ListBucket"]
      resources = local.app_s3_resources
    }
  }
}

resource "aws_iam_role_policy" "app_service" {
  name   = "${local.name_prefix}-app-service-policy"
  role   = aws_iam_role.app_service.id
  policy = data.aws_iam_policy_document.app_service.json
}

# Monitoring role (Prometheus / Grafana / Alertmanager) ---------------------

data "aws_iam_policy_document" "monitoring_trust" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["ecs-tasks.amazonaws.com", "ec2.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "monitoring" {
  name               = "${local.name_prefix}-monitoring"
  assume_role_policy = data.aws_iam_policy_document.monitoring_trust.json

  tags = merge(local.common_tags, { Name = "${local.name_prefix}-monitoring", Service = "observability" })
}

resource "aws_iam_instance_profile" "monitoring" {
  name = "${local.name_prefix}-monitoring"
  role = aws_iam_role.monitoring.name
}

resource "aws_iam_role_policy_attachment" "monitoring_ssm" {
  role       = aws_iam_role.monitoring.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

data "aws_iam_policy_document" "monitoring" {
  statement {
    sid    = "ServiceDiscovery"
    effect = "Allow"
    actions = [
      "ec2:DescribeInstances", "ec2:DescribeTags",
      "cloudwatch:GetMetricData", "cloudwatch:ListMetrics", "cloudwatch:DescribeAlarms",
    ]
    resources = ["*"] # read-only describe/list actions; these do not support resource-level scoping
  }

  statement {
    sid       = "ReadLogsForCorrelation"
    effect    = "Allow"
    actions   = ["logs:GetLogEvents", "logs:DescribeLogStreams", "logs:FilterLogEvents"]
    resources = ["arn:aws:logs:${var.region}:${data.aws_caller_identity.current.account_id}:log-group:/pesaguard/${var.environment}/*"]
  }

  statement {
    sid       = "DecryptLogs"
    effect    = "Allow"
    actions   = ["kms:Decrypt", "kms:DescribeKey"]
    resources = [var.logs_kms_key_arn]
  }
}

resource "aws_iam_role_policy" "monitoring" {
  name   = "${local.name_prefix}-monitoring-policy"
  role   = aws_iam_role.monitoring.id
  policy = data.aws_iam_policy_document.monitoring.json
}

# Backup operator role (AWS Backup / scheduled snapshot automation) --------

data "aws_iam_policy_document" "backup_operator_trust" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["backup.amazonaws.com", "events.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "backup_operator" {
  name               = "${local.name_prefix}-backup-operator"
  assume_role_policy = data.aws_iam_policy_document.backup_operator_trust.json

  tags = merge(local.common_tags, { Name = "${local.name_prefix}-backup-operator", Service = "backup" })
}

data "aws_iam_policy_document" "backup_operator" {
  statement {
    sid    = "DatabaseSnapshots"
    effect = "Allow"
    actions = [
      "rds:CreateDBSnapshot", "rds:DescribeDBSnapshots", "rds:CopyDBSnapshot",
      "rds:DeleteDBSnapshot", "rds:ListTagsForResource", "rds:AddTagsToResource",
    ]
    resources = ["*"] # scoped further once specific RDS instance ARNs exist (Phase 5)
  }

  statement {
    sid       = "EncryptBackups"
    effect    = "Allow"
    actions   = ["kms:GenerateDataKey", "kms:Decrypt", "kms:DescribeKey"]
    resources = [var.backups_kms_key_arn, var.database_kms_key_arn]
  }

  dynamic "statement" {
    for_each = length(local.backup_s3_resources) > 0 ? [1] : []
    content {
      sid       = "BackupObjectStorage"
      effect    = "Allow"
      actions   = ["s3:PutObject", "s3:GetObject", "s3:ListBucket"]
      resources = local.backup_s3_resources
    }
  }
}

resource "aws_iam_role_policy" "backup_operator" {
  name   = "${local.name_prefix}-backup-operator-policy"
  role   = aws_iam_role.backup_operator.id
  policy = data.aws_iam_policy_document.backup_operator.json
}
