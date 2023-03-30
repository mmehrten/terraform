/*
*   Create hub VPC with VPC endpoints and an internet gateway, to be used as a transit hub for other VPCs.
*/
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "= 4.6.0"
    }
  }
}

locals {
  base-name  = "${var.app-shorthand-name}.${var.region}"
}

module "terraform" {
  region             = var.region
  partition          = var.partition
  account-id         = var.account-id
  app-shorthand-name = var.app-shorthand-name
  app-name           = var.app-name
  terraform-role     = var.terraform-role
  tags               = var.tags
  base-name          = local.base-name

  runner-role-arns = ["arn:${var.partition}:iam::${var.account-id}:role/Admin"]
  source           = "../../modules/terraform-infra"
}
