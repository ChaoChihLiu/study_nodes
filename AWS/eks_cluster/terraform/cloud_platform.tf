provider "aws" {
    profile = var.profile
    region  = var.region
}

data "aws_caller_identity" "current" {}