/*
*   Create a spoke VPC with only private subnets, that uses the hub VPC as a transit center.
*/
locals {
  base-name = "${var.app-shorthand-name}.${var.region}"
}

data "aws_ec2_transit_gateway" "tgw" {
  filter {
    name   = "state"
    values = ["available"]
  }
}


# TODO: manage both child govcloud and commercial accounts
module "account" {
  # Only create an account if we're configured to
  count = var.create-account == true ? 1 : 0

  region             = var.region
  account-id         = var.root-account-id
  app-shorthand-name = var.app-shorthand-name
  app-name           = var.app-name
  partition          = var.partition
  // Use organization root to provision child
  terraform-role = var.terraform-role
  tags           = var.tags
  // Don't use region in account base name, since account can span regions
  base-name = var.app-shorthand-name

  account-name  = "${var.app-shorthand-name}.account"
  account-owner = var.owner-email
  source        = "../../modules/organization-child"
}

provider "aws" {
  region = var.region
  assume_role {
    role_arn = var.create-account == true ? "arn:${var.partition}:iam::${local.child-account-id}:role/OrganizationAccountAccessRole" : "arn:${var.partition}:iam::${local.child-account-id}:role/Admin"
  }
  default_tags { tags = var.tags }
  alias = "spoke"
}

locals {
  child-account-id = var.create-account == true ? module.account[0].outputs.account-id : var.child-account-id
}

module "child-terraform-role" {
  count              = var.create-account == true ? 1 : 0
  providers          = { aws = aws.spoke, aws.root = aws }
  region             = var.region
  account-id         = local.child-account-id
  app-shorthand-name = var.app-shorthand-name
  app-name           = var.app-name
  # Use the child account admin role to provision the Terraform role
  terraform-role = "arn:aws:iam::${local.child-account-id}:role/OrganizationAccountAccessRole"
  tags           = var.tags
  base-name      = local.base-name
  partition      = var.partition

  # Allow the root account Terraform role to assume the child account Terraform role
  runner-role-arns = [
    var.terraform-role,
    "arn:${var.partition}:iam::${var.root-account-id}:role/Admin",
    "arn:${var.partition}:iam::${var.root-account-id}:role/Terraform",
  ]
  source = "../../modules/terraform-role"
}

locals {
  child-terraform-role = var.create-account == true ? module.child-terraform-role[0].outputs.arn : var.terraform-role
}

module "vpc" {
  providers          = { aws = aws.spoke, aws.root = aws }
  region             = var.region
  account-id         = local.child-account-id
  app-shorthand-name = var.app-shorthand-name
  app-name           = var.app-name
  terraform-role     = local.child-terraform-role
  tags               = var.tags
  base-name          = local.base-name
  partition          = var.partition

  public-subnets  = var.public-subnets
  private-subnets = var.private-subnets
  cidr-block      = var.cidr-block
  source          = "../../modules/vpc"
}

module "transit-gateway-attachment" {
  count              = var.enable-transitgateway == true ? 1 : 0
  depends_on         = [module.vpc]
  providers          = { aws = aws.spoke, aws.root = aws }
  region             = var.region
  account-id         = local.child-account-id
  app-shorthand-name = var.app-shorthand-name
  app-name           = var.app-name
  terraform-role     = local.child-terraform-role
  tags               = var.tags
  base-name          = local.base-name
  partition          = var.partition

  transit-gateway-id = data.aws_ec2_transit_gateway.tgw.id
  root-account-id    = var.root-account-id
  root-region        = var.root-region
  vpc-id             = module.vpc.outputs.vpc-id
  subnet-ids         = [for o in values(module.vpc.outputs.private-subnet-ids) : o]
  cidr-block         = var.cidr-block
  source             = "../../modules/transit-gateway-attachment"
}

module "redshift" {
  providers          = { aws = aws.spoke, aws.root = aws }
  region             = var.region
  account-id         = local.child-account-id
  app-shorthand-name = var.app-shorthand-name
  app-name           = var.app-name
  terraform-role     = local.child-terraform-role
  tags               = var.tags
  base-name          = local.base-name
  partition          = var.partition

  vpc-id          = module.vpc.outputs.vpc-id
  database-name   = "dev"
  master-password = var.redshift-master-password
  source          = "../../modules/redshift"
}

module "s3-data" {
  providers          = { aws = aws.spoke, aws.root = aws }
  region             = var.region
  account-id         = local.child-account-id
  app-shorthand-name = var.app-shorthand-name
  app-name           = var.app-name
  terraform-role     = local.child-terraform-role
  tags               = var.tags
  base-name          = local.base-name
  partition          = var.partition

  bucket-name = "${local.base-name}.s3.analytics"
  versioning  = false
  source      = "../../modules/s3"
}
