/*
*   Create a spoke VPC with only private subnets, that uses the hub VPC as a transit center.
*/
locals {
  base-name = "${var.app-shorthand-name}.${var.region}"
}

data "aws_ec2_transit_gateway" "tgw" {
  filter {
    name   = "transit-gateway-id"
    values = [var.root-transit-gateway-id]
  }
}

module "account" {
  region             = var.region
  account-id         = var.root-account-id
  app-shorthand-name = var.app-shorthand-name
  app-name           = var.app-name
  // Use organization root to provision child
  terraform-role = var.terraform-role
  tags           = var.tags
  // Don't use region in account base name, since account can span regions
  base-name = var.app-shorthand-name

  account-name  = "${var.app-shorthand-name}.account"
  account-owner = var.owner-email
  source        = "../../terraform-main/aws/modules/organization-child"
}

locals {
  child-account-id     = module.account.outputs.account-id
  child-terraform-role = module.account.outputs.terraform-role-arn
}

provider "aws" {
  region = var.region
  assume_role { role_arn = local.child-terraform-role }
  default_tags { tags = var.tags }
  alias = "spoke"
}

module "vpc" {
  providers          = { aws = aws.spoke }
  region             = var.region
  account-id         = local.child-account-id
  app-shorthand-name = var.app-shorthand-name
  app-name           = var.app-name
  terraform-role     = local.child-terraform-role
  tags               = var.tags
  base-name          = local.base-name

  public-subnets  = var.public-subnets
  private-subnets = var.private-subnets
  cidr-block      = var.cidr-block
  source          = "../../terraform-main/aws/modules/vpc"
}

module "transit-gateway-attachment" {
  providers          = { aws = aws.spoke, aws.root = aws }
  region             = var.region
  account-id         = local.child-account-id
  app-shorthand-name = var.app-shorthand-name
  app-name           = var.app-name
  terraform-role     = local.child-terraform-role
  tags               = var.tags
  base-name          = local.base-name

  transit-gateway-id = data.aws_ec2_transit_gateway.tgw.id
  root-account-id    = var.root-account-id
  root-region        = var.root-region
  vpc-id             = module.vpc.outputs.vpc-id
  subnet-ids         = [for o in values(module.vpc.outputs.private-subnet-ids) : o]
  cidr-block         = var.cidr-block
  source             = "../../terraform-main/aws/modules/transit-gateway-attachment"
}

module "s3-infra" {
  providers          = { aws = aws.spoke }
  region             = var.region
  account-id         = local.child-account-id
  app-shorthand-name = var.app-shorthand-name
  app-name           = var.app-name
  terraform-role     = local.child-terraform-role
  tags               = var.tags
  base-name          = local.base-name

  bucket-name = "${local.base-name}.s3.infra"
  versioning  = false
  source      = "../../terraform-main/aws/modules/s3"
}

module "s3-data" {
  providers          = { aws = aws.spoke }
  region             = var.region
  account-id         = local.child-account-id
  app-shorthand-name = var.app-shorthand-name
  app-name           = var.app-name
  terraform-role     = local.child-terraform-role
  tags               = var.tags
  base-name          = local.base-name

  bucket-name = "${local.base-name}.s3.analytics"
  versioning  = false
  source      = "../../terraform-main/aws/modules/s3"
}

module "s3-logs" {
  providers          = { aws = aws.spoke }
  region             = var.region
  account-id         = local.child-account-id
  app-shorthand-name = var.app-shorthand-name
  app-name           = var.app-name
  terraform-role     = local.child-terraform-role
  tags               = var.tags
  base-name          = local.base-name

  bucket-name     = "${local.base-name}.s3.logs"
  versioning      = false
  expiration-days = 7
  source          = "../../terraform-main/aws/modules/s3"
}
