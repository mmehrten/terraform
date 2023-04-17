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

module "account" {
  # Only create an account if we're configured to
  count = var.create-account == true ? 1 : 0

  region             = var.region
  account-id         = var.root-account-id
  app-shorthand-name = var.app-shorthand-name
  app-name           = var.app-name
  // Use organization root to provision child
  terraform-role = local.terraform-role
  tags           = local.tags
  // Don't use region in account base name, since account can span regions
  base-name = var.app-shorthand-name

  account-name  = "${var.app-shorthand-name}.account"
  account-owner = var.owner-email
  source        = "../../modules/organization-child"
}

locals {
  child-account-id     = var.create-account == true ? module.account[0].outputs.account-id : var.root-account-id
  child-terraform-role = var.create-account == true ? module.account[0].outputs.terraform-role-arn : local.terraform-role
}

module "vpc" {
  region             = var.region
  account-id         = local.child-account-id
  app-shorthand-name = var.app-shorthand-name
  app-name           = var.app-name
  terraform-role     = local.child-terraform-role
  tags               = local.tags
  base-name          = local.base-name

  public-subnets  = local.public-subnets
  private-subnets = local.private-subnets
  cidr-block      = local.cidr-block
  source          = "../../modules/vpc"
}

# TODO: Use peering attachments
module "transit-gateway-attachment" {
  region             = var.region
  account-id         = local.child-account-id
  app-shorthand-name = var.app-shorthand-name
  app-name           = var.app-name
  terraform-role     = local.child-terraform-role
  tags               = local.tags
  base-name          = local.base-name

  transit-gateway-id = data.aws_ec2_transit_gateway.tgw.id
  vpc-id             = module.vpc.outputs.vpc-id
  route-table-id     = module.vpc.outputs.private-route-table-id
  subnet-ids         = [for o in values(module.vpc.outputs.private-subnet-ids) : o]
  source             = "../../modules/transit-gateway-attachment"
}

module "console-user" {
  region             = var.region
  account-id         = local.child-account-id
  app-shorthand-name = var.app-shorthand-name
  app-name           = var.app-name
  terraform-role     = local.child-terraform-role
  tags               = local.tags
  base-name          = local.base-name

  pgp-key = var.pgp-key
  source  = "../../modules/console-user"
}

output "spoke-account-id" {
  value = module.account.outputs.account-id
}
output "password" {
  value = module.console-user.outputs.console
}
output "access-key-id" {
  value = module.console-user.outputs.access_key_id
}
output "secret-access-key" {
  value = module.console-user.outputs.secret_access_key
}
