terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  # Intentionally local state — see README.md in this directory for why.
}

provider "aws" {
  region = var.region

  default_tags {
    tags = local.common_tags
  }
}
