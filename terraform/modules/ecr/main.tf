resource "aws_ecr_repository" "this" {
  for_each = toset(var.repository_names)

  name                 = "${lower(var.project)}/${var.environment}/${each.value}"
  image_tag_mutability = "IMMUTABLE" # no floating tags like :latest in this registry

  image_scanning_configuration {
    scan_on_push = true
  }

  tags = merge(local.common_tags, { Name = each.value, Service = each.value })
}

resource "aws_ecr_lifecycle_policy" "this" {
  for_each   = aws_ecr_repository.this
  repository = each.value.name

  policy = jsonencode({
    rules = [
      {
        rulePriority = 1
        description  = "Expire untagged images after ${var.untagged_image_expiry_days} days"
        selection = {
          tagStatus   = "untagged"
          countType   = "sinceImagePushed"
          countUnit   = "days"
          countNumber = var.untagged_image_expiry_days
        }
        action = { type = "expire" }
      },
      {
        rulePriority = 2
        description  = "Keep only the most recent ${var.tagged_image_keep_count} tagged images"
        selection = {
          tagStatus     = "tagged"
          tagPrefixList = ["v", "sha-", "release-"]
          countType     = "imageCountMoreThan"
          countNumber   = var.tagged_image_keep_count
        }
        action = { type = "expire" }
      },
    ]
  })
}
