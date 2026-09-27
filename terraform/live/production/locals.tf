locals {
  # Must match terraform/bootstrap's naming convention exactly (that
  # module's locals.state_bucket_name / lock_table_name), since this root
  # config uses a separate (remote) state file from bootstrap's (local)
  # state and can't reference its outputs directly. If bootstrap was
  # applied with a state_bucket_name/lock_table_name override, update
  # these to match.
  state_bucket_name = lower("${var.project}-tfstate-${var.environment}-${data.aws_caller_identity.current.account_id}")
  lock_table_name   = "${lower(var.project)}-tflock-${var.environment}"

  state_bucket_arn = "arn:aws:s3:::${local.state_bucket_name}"
  lock_table_arn   = "arn:aws:dynamodb:${var.region}:${data.aws_caller_identity.current.account_id}:table/${local.lock_table_name}"
}
