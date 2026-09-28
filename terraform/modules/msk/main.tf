resource "aws_cloudwatch_log_group" "broker_logs" {
  name              = "/pesaguard/${var.environment}/msk-broker-logs"
  retention_in_days = var.log_retention_days
  kms_key_id        = var.logs_kms_key_arn

  tags = local.common_tags
}

resource "aws_msk_configuration" "this" {
  name           = "${local.name_prefix}-msk-config"
  kafka_versions = [var.kafka_version]

  server_properties = <<-PROPERTIES
    auto.create.topics.enable=false
    default.replication.factor=${min(var.number_of_broker_nodes, 3)}
    min.insync.replicas=${var.number_of_broker_nodes >= 3 ? 2 : 1}
    num.partitions=6
    log.retention.hours=168
    unclean.leader.election.enable=false
  PROPERTIES
}

resource "aws_msk_cluster" "this" {
  cluster_name           = "${local.name_prefix}-msk"
  kafka_version          = var.kafka_version
  number_of_broker_nodes = var.number_of_broker_nodes

  broker_node_group_info {
    instance_type   = var.broker_instance_type
    client_subnets  = var.subnet_ids
    security_groups = [var.security_group_id]

    storage_info {
      ebs_storage_info {
        volume_size = var.broker_ebs_volume_size
      }
    }
  }

  configuration_info {
    arn      = aws_msk_configuration.this.arn
    revision = aws_msk_configuration.this.latest_revision
  }

  encryption_info {
    encryption_at_rest_kms_key_arn = var.kms_key_arn

    encryption_in_transit {
      client_broker = "TLS"
      in_cluster    = true
    }
  }

  # IAM authentication only — no plaintext, no separately-managed
  # SASL/SCRAM credentials. App-tier access is granted via the iam
  # module's app_service role (kafka-cluster:* actions scoped to this
  # cluster's ARN), consistent with this repo's OIDC/least-privilege
  # approach elsewhere.
  client_authentication {
    sasl {
      iam = true
    }
  }

  enhanced_monitoring = var.enhanced_monitoring

  logging_info {
    broker_logs {
      cloudwatch_logs {
        enabled   = true
        log_group = aws_cloudwatch_log_group.broker_logs.name
      }
    }
  }

  tags = merge(local.common_tags, { Name = "${local.name_prefix}-msk" })
}
