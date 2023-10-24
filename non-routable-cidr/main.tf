/*
*   Create a non-routable CIDR in a VPC.
*/
locals {
  base-name = "${var.app-shorthand-name}.${var.region}"
}

module "cidr" {
  region             = var.region
  account-id         = var.account-id
  app-shorthand-name = var.app-shorthand-name
  app-name           = var.app-name
  terraform-role     = var.terraform-role
  tags               = var.tags
  base-name          = local.base-name
  partition          = var.partition

  subnets    = var.subnets
  cidr-block = var.cidr-block
  vpc-id     = var.vpc-id
  source     = "../terraform-main/aws/modules/non-routable-cidr"
}

