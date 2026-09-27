# One bucket per entry in var.buckets, each with the same security
# baseline: versioning, SSE-KMS, public access fully blocked, TLS-only
# bucket policy, and lifecycle expiration of old versions.

resource "aws_s3_bucket" "this" {
  for_each = local.buckets_by_name

  bucket = lower("${var.project}-${var.environment}-${each.value.name}-${data.aws_caller_identity.current.account_id}")

  tags = merge(local.common_tags, {
    Name    = "${var.project}-${var.environment}-${each.value.name}"
    Purpose = each.value.name
  })
}

resource "aws_s3_bucket_versioning" "this" {
  for_each = local.buckets_by_name
  bucket   = aws_s3_bucket.this[each.key].id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "this" {
  for_each = local.buckets_by_name
  bucket   = aws_s3_bucket.this[each.key].id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm     = "aws:kms"
      kms_master_key_id = var.kms_key_arn
    }
    bucket_key_enabled = true
  }
}

resource "aws_s3_bucket_public_access_block" "this" {
  for_each = local.buckets_by_name
  bucket   = aws_s3_bucket.this[each.key].id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_lifecycle_configuration" "this" {
  for_each = local.buckets_by_name
  bucket   = aws_s3_bucket.this[each.key].id

  rule {
    id     = "expire-noncurrent-versions"
    status = "Enabled"

    noncurrent_version_expiration {
      noncurrent_days = each.value.noncurrent_version_expiration_days
    }
  }
}

resource "aws_s3_bucket_policy" "deny_insecure_transport" {
  for_each = local.buckets_by_name
  bucket   = aws_s3_bucket.this[each.key].id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Sid       = "DenyInsecureTransport"
      Effect    = "Deny"
      Principal = "*"
      Action    = "s3:*"
      Resource = [
        aws_s3_bucket.this[each.key].arn,
        "${aws_s3_bucket.this[each.key].arn}/*",
      ]
      Condition = {
        Bool = {
          "aws:SecureTransport" = "false"
        }
      }
    }]
  })
}
