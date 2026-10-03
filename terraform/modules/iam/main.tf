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
    actions   = ["logs:CreateLogGroup", "logs:DeleteLogGroup", "logs:DescribeLogGroups", "logs:PutRetentionPolicy", "logs:TagResource", "logs:ListTagsForResource", "logs:AssociateKmsKey", "logs:DisassociateKmsKey"]
    resources = ["arn:aws:logs:${var.region}:${data.aws_caller_identity.current.account_id}:log-group:/pesaguard/${var.environment}/*"]
  }

  # --- Phase 5/6 services ------------------------------------------------
  # Scoped by this project+environment name prefix wherever the service
  # supports resource-level permissions. NOTE: RDS/ElastiCache lowercase
  # resource names, S3 bucket names are lowercased by the object-storage
  # module, MSK/Glue preserve case — hence the two prefixes below.
  # This policy has not been exercised by a real CI apply; expect to add a
  # missing action or two on first run (AccessDenied in the plan/apply log
  # names it) — extend here deliberately rather than widening to service:*.

  statement {
    sid    = "ObjectStorageBuckets"
    effect = "Allow"
    actions = [
      "s3:CreateBucket", "s3:DeleteBucket", "s3:ListBucket",
      "s3:GetBucket*", "s3:PutBucket*", "s3:DeleteBucketPolicy",
      "s3:GetLifecycleConfiguration", "s3:PutLifecycleConfiguration",
      "s3:GetEncryptionConfiguration", "s3:PutEncryptionConfiguration",
    ]
    resources = ["arn:aws:s3:::${lower(var.project)}-${var.environment}-*"]
  }

  statement {
    sid       = "RdsManagement"
    effect    = "Allow"
    actions   = ["rds:*"]
    resources = ["arn:aws:rds:${var.region}:${data.aws_caller_identity.current.account_id}:*:${lower(var.project)}-${var.environment}-*"]
  }

  statement {
    sid       = "ElastiCacheManagement"
    effect    = "Allow"
    actions   = ["elasticache:*"]
    resources = ["arn:aws:elasticache:${var.region}:${data.aws_caller_identity.current.account_id}:*:${lower(var.project)}-${var.environment}-*"]
  }

  statement {
    sid       = "MskManagementScoped"
    effect    = "Allow"
    actions   = ["kafka:*"]
    resources = [
      "arn:aws:kafka:${var.region}:${data.aws_caller_identity.current.account_id}:cluster/${var.project}-${var.environment}-msk/*",
      "arn:aws:kafka:${var.region}:${data.aws_caller_identity.current.account_id}:configuration/${var.project}-${var.environment}-msk-config/*",
    ]
  }

  statement {
    sid    = "GlueSchemaRegistryManagement"
    effect = "Allow"
    actions = [
      "glue:CreateRegistry", "glue:DeleteRegistry", "glue:GetRegistry",
      "glue:UpdateRegistry", "glue:TagResource", "glue:UntagResource", "glue:GetTags",
    ]
    resources = ["arn:aws:glue:${var.region}:${data.aws_caller_identity.current.account_id}:registry/${var.project}-${var.environment}-schemas"]
  }

  # Actions that do not support resource-level scoping (list/describe/create-
  # before-an-ARN-exists). Read-only except the two Create* calls.
  statement {
    sid    = "DataServicesUnscopedActions"
    effect = "Allow"
    actions = [
      "rds:Describe*", "rds:ListTagsForResource",
      "elasticache:Describe*", "elasticache:ListTagsForResource",
      "kafka:CreateCluster", "kafka:CreateConfiguration",
      "kafka:Describe*", "kafka:List*", "kafka:GetBootstrapBrokers",
      "glue:ListRegistries",
    ]
    resources = ["*"]
  }

  statement {
    sid    = "NetworkInterfacesForManagedServices"
    effect = "Allow"
    actions = [
      "ec2:CreateNetworkInterface", "ec2:DeleteNetworkInterface",
      "ec2:ModifyNetworkInterfaceAttribute", "ec2:ModifyVpcEndpoint",
    ]
    resources = ["*"]
  }

  # Encrypted RDS/ElastiCache/MSK/S3/Secrets create KMS grants on the CMK
  # using the caller's permissions. Limited to this environment's keys via
  # their aliases (alias/<Project>-<env>-*).
  statement {
    sid    = "KmsUseForEncryptedResources"
    effect = "Allow"
    actions = [
      "kms:CreateGrant", "kms:GenerateDataKey*", "kms:Decrypt",
      "kms:Encrypt", "kms:ReEncrypt*", "kms:DescribeKey",
    ]
    resources = ["*"]
    condition {
      test     = "ForAnyValue:StringLike"
      variable = "kms:ResourceAliases"
      values   = ["alias/${var.project}-${var.environment}-*"]
    }
  }

  # First use of RDS/ElastiCache/MSK in an account creates a service-linked
  # role; only those three services, only the aws-service-role path.
  statement {
    sid       = "ServiceLinkedRoles"
    effect    = "Allow"
    actions   = ["iam:CreateServiceLinkedRole"]
    resources = ["arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/aws-service-role/*"]
    condition {
      test     = "StringEquals"
      variable = "iam:AWSServiceName"
      values   = ["rds.amazonaws.com", "elasticache.amazonaws.com", "kafka.amazonaws.com"]
    }
  }
}

resource "aws_iam_role_policy" "terraform_ci" {
  name   = "${local.name_prefix}-terraform-ci-policy"
  role   = aws_iam_role.terraform_ci.id
  policy = data.aws_iam_policy_document.terraform_ci.json
}

# Second inline policy for Phases 7-8, kept separate from the Phases-1-6
# policy above rather than grown indefinitely -- each AWS inline role
# policy has a 10,240-character hard limit, and this repo would rather
# split early and predictably than hit that limit mid-phase. Extend THIS
# document for compute/edge/observability-adjacent services; start a
# third if this one approaches the limit too.
data "aws_iam_policy_document" "terraform_ci_phase_7_8" {
  # --- Phase 7: compute & edge --------------------------------------------

  statement {
    sid       = "EcsManagementScoped"
    effect    = "Allow"
    actions   = ["ecs:*"]
    resources = [
      "arn:aws:ecs:${var.region}:${data.aws_caller_identity.current.account_id}:cluster/${var.project}-${var.environment}-*",
      "arn:aws:ecs:${var.region}:${data.aws_caller_identity.current.account_id}:service/${var.project}-${var.environment}-*/*",
      "arn:aws:ecs:${var.region}:${data.aws_caller_identity.current.account_id}:task-definition/${var.project}-${var.environment}-*:*",
    ]
  }

  statement {
    sid       = "EcrManagementScoped"
    effect    = "Allow"
    actions   = ["ecr:*"]
    resources = ["arn:aws:ecr:${var.region}:${data.aws_caller_identity.current.account_id}:repository/${lower(var.project)}/${var.environment}/*"]
  }

  statement {
    sid       = "WafManagementScoped"
    effect    = "Allow"
    actions   = ["wafv2:*"]
    resources = ["arn:aws:wafv2:${var.region}:${data.aws_caller_identity.current.account_id}:regional/webacl/${var.project}-${var.environment}-waf/*"]
  }

  # ELB (ALB), ACM, and the create/list-only edges of ECS/ECR/WAF/AMP/
  # Grafana/autoscaling do not support resource-level scoping for the
  # actions CI needs at first-apply time (the resource doesn't exist yet,
  # or AWS simply doesn't define a resource-level policy for that action).
  # This is the same documented, deliberate trade-off as
  # DataServicesUnscopedActions above -- not a default-to-permissive habit.
  statement {
    sid    = "EdgeAndComputeUnscopedActions"
    effect = "Allow"
    actions = [
      "elasticloadbalancing:*",
      "acm:*",
      "ecr:CreateRepository", "ecr:GetAuthorizationToken",
      "ecs:CreateCluster", "ecs:RegisterTaskDefinition", "ecs:Describe*", "ecs:List*",
      "wafv2:CreateWebACL", "wafv2:CheckCapacity", "wafv2:ListWebACLs",
      "application-autoscaling:*",
    ]
    resources = ["*"]
  }

  # --- Phase 8: observability ----------------------------------------------

  statement {
    sid       = "SnsAlertsManagementScoped"
    effect    = "Allow"
    actions   = ["sns:*"]
    resources = ["arn:aws:sns:${var.region}:${data.aws_caller_identity.current.account_id}:${var.project}-${var.environment}-alerts-*"]
  }

  statement {
    sid       = "CloudWatchAlarmsManagementScoped"
    effect    = "Allow"
    actions   = ["cloudwatch:PutMetricAlarm", "cloudwatch:DeleteAlarms", "cloudwatch:TagResource"]
    resources = ["arn:aws:cloudwatch:${var.region}:${data.aws_caller_identity.current.account_id}:alarm:${var.project}-${var.environment}-*"]
  }

  statement {
    sid     = "CloudWatchAlarmsReadActions"
    effect  = "Allow"
    actions = ["cloudwatch:Describe*", "cloudwatch:List*", "cloudwatch:GetMetricData"]
    resources = ["*"]
  }

  # AMP (aps) and Grafana workspaces are not named with this project's
  # prefix in their ARNs (ID-based, assigned by AWS at creation) and have
  # too few distinct actions per workspace to justify a tag-based
  # condition here -- same "create-time ARN doesn't exist yet" reasoning
  # as ACM above.
  statement {
    sid       = "AmpAndGrafanaManagement"
    effect    = "Allow"
    actions   = ["aps:*", "grafana:*"]
    resources = ["*"]
  }
}

resource "aws_iam_role_policy" "terraform_ci_phase_7_8" {
  name   = "${local.name_prefix}-terraform-ci-policy-phase-7-8"
  role   = aws_iam_role.terraform_ci.id
  policy = data.aws_iam_policy_document.terraform_ci_phase_7_8.json
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

  # MSK data-plane access (IAM auth). Deliberately excludes
  # kafka-cluster:CreateTopic / DeleteTopic / AlterTopic: topic lifecycle is
  # an operator action (scripts/messaging/apply-topics.sh), not something a
  # runtime service — or an attacker who compromises one — should be able
  # to do to financial event streams.
  dynamic "statement" {
    for_each = var.enable_msk_access ? [1] : []
    content {
      sid       = "MskConnect"
      effect    = "Allow"
      actions   = ["kafka-cluster:Connect", "kafka-cluster:DescribeCluster"]
      resources = [var.msk_cluster_arn]
    }
  }

  dynamic "statement" {
    for_each = var.enable_msk_access ? [1] : []
    content {
      sid       = "MskTopicDataAccess"
      effect    = "Allow"
      actions   = ["kafka-cluster:DescribeTopic", "kafka-cluster:ReadData", "kafka-cluster:WriteData"]
      resources = ["${local.msk_topic_arn_prefix}/*"]
    }
  }

  dynamic "statement" {
    for_each = var.enable_msk_access ? [1] : []
    content {
      sid       = "MskConsumerGroups"
      effect    = "Allow"
      actions   = ["kafka-cluster:AlterGroup", "kafka-cluster:DescribeGroup"]
      resources = ["${local.msk_group_arn_prefix}/*"]
    }
  }

  # AMP remote-write + X-Ray trace export, for a future OTel/ADOT sidecar.
  # X-Ray's write actions (PutTraceSegments/PutTelemetryRecords) do not
  # support resource-level scoping -- AWS-documented limitation, not a
  # choice made here to be permissive.
  dynamic "statement" {
    for_each = var.enable_observability_access ? [1] : []
    content {
      sid       = "AmpRemoteWrite"
      effect    = "Allow"
      actions   = ["aps:RemoteWrite"]
      resources = [var.amp_workspace_arn]
    }
  }

  dynamic "statement" {
    for_each = var.enable_observability_access ? [1] : []
    content {
      sid       = "XRayWrite"
      effect    = "Allow"
      actions   = ["xray:PutTraceSegments", "xray:PutTelemetryRecords", "xray:GetSamplingRules", "xray:GetSamplingTargets"]
      resources = ["*"]
    }
  }

  # Glue Schema Registry, scoped to this environment's registry and the
  # schemas within it — not glue:* (Glue also covers ETL jobs/crawlers).
  dynamic "statement" {
    for_each = var.enable_glue_registry_access ? [1] : []
    content {
      sid = "GlueSchemaRegistry"
      effect = "Allow"
      actions = [
        "glue:GetRegistry",
        "glue:ListSchemas",
        "glue:ListSchemaVersions",
        "glue:GetSchema",
        "glue:GetSchemaVersion",
        "glue:GetSchemaByDefinition",
        "glue:QuerySchemaVersionMetadata",
        "glue:CreateSchema",
        "glue:RegisterSchemaVersion",
      ]
      resources = [var.glue_registry_arn, "${local.glue_schema_arn_prefix}/*"]
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
