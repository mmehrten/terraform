/*
*   Create hub VPC with VPC endpoints and an internet gateway, to be used as a transit hub for other VPCs.
*/
locals {
  base-name = "${var.app-shorthand-name}.${var.region}"
}

module "terraform" {
  region             = var.region
  account-id         = var.account-id
  app-shorthand-name = var.app-shorthand-name
  app-name           = var.app-name
  terraform-role     = var.terraform-role
  tags               = var.tags
  base-name          = local.base-name
  partition          = var.partition

  runner-role-arns = ["arn:aws:iam::${var.account-id}:role/Admin"]
  source           = "../../terraform-main/aws/modules/terraform-infra"
}

module "vpc" {
  region             = var.region
  account-id         = var.account-id
  app-shorthand-name = var.app-shorthand-name
  app-name           = var.app-name
  terraform-role     = var.terraform-role
  tags               = var.tags
  base-name          = local.base-name
  partition          = var.partition

  public-subnets  = var.public-subnets
  private-subnets = var.private-subnets
  cidr-block      = var.cidr-block
  source          = "../../terraform-main/aws/modules/vpc"
}

module "s3-logs" {
  region             = var.region
  account-id         = var.account-id
  app-shorthand-name = var.app-shorthand-name
  app-name           = var.app-name
  terraform-role     = var.terraform-role
  tags               = var.tags
  base-name          = local.base-name
  partition          = var.partition

  bucket-name = "${local.base-name}.s3.logs"
  versioning  = false
  source      = "../../terraform-main/aws/modules/s3"
}

module "organization-root" {
  region             = var.region
  account-id         = var.account-id
  app-shorthand-name = var.app-shorthand-name
  app-name           = var.app-name
  terraform-role     = var.terraform-role
  tags               = var.tags
  base-name          = local.base-name
  partition          = var.partition

  source      = "../../terraform-main/aws/modules/organization-root"
  logs-bucket = module.s3-logs.outputs.name
}

module "internet-gateway" {
  region             = var.region
  account-id         = var.account-id
  app-shorthand-name = var.app-shorthand-name
  app-name           = var.app-name
  terraform-role     = var.terraform-role
  tags               = var.tags
  base-name          = local.base-name
  partition          = var.partition

  vpc-id         = module.vpc.outputs.vpc-id
  subnet-ids     = module.vpc.outputs.public-subnet-ids
  route-table-id = module.vpc.outputs.public-route-table-id
  source         = "../../terraform-main/aws/modules/internet-gateway"
}

module "vpc-endpoints" {
  region             = var.region
  account-id         = var.account-id
  app-shorthand-name = var.app-shorthand-name
  app-name           = var.app-name
  terraform-role     = var.terraform-role
  tags               = var.tags
  base-name          = local.base-name
  partition          = var.partition

  vpc-id          = module.vpc.outputs.vpc-id
  subnet-ids      = module.vpc.outputs.private-subnet-ids
  route-table-ids = [module.vpc.outputs.public-route-table-id, module.vpc.outputs.private-route-table-id]
  source          = "../../terraform-main/aws/modules/vpc-endpoints"
}

module "transit-gateway" {
  count              = var.enable-transitgateway ? 1 : 0
  region             = var.region
  account-id         = var.account-id
  app-shorthand-name = var.app-shorthand-name
  app-name           = var.app-name
  terraform-role     = var.terraform-role
  tags               = var.tags
  base-name          = local.base-name
  partition          = var.partition

  vpc-id     = module.vpc.outputs.vpc-id
  subnet-ids = [for o in values(module.vpc.outputs.private-subnet-ids) : o]
  source     = "../../terraform-main/aws/modules/transit-gateway"
}

output "results" {
  value = {
    "root-transit-gateway-id" : module.transit-gateway[0].id
  }
}
