/*
*   Create AWS Glue resources.
*/
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "= 4.6.0"
    }
  }
  backend "s3" {
    bucket         = "govcore.us-gov-west-1.s3.terraform"
    key            = "govglue/state/prod.tfstate"
    region         = "us-gov-west-1"
    dynamodb_table = "govcore.us-gov-west-1.dynamodb.terraform"
  }
}

locals {
  terraform-role = "arn:aws-us-gov:iam::${var.account-id}:role/Terraform"
  tags = {
    "service"     = "GovCould AWS Glue Deployment"
    "environment" = "prod"
    "deployment"  = "terraform"
    "cicd"        = "None"
  }
  base-name = "${var.app-shorthand-name}.${var.region}"
}

module "s3-infra" {
  region             = var.region
  partition          = var.partition
  account-id         = var.account-id
  app-shorthand-name = var.app-shorthand-name
  app-name           = var.app-name
  terraform-role     = local.terraform-role
  tags               = local.tags
  base-name          = local.base-name

  bucket-name = "${local.base-name}.s3.glue-infra"
  versioning  = false
  source      = "../../modules/s3"
}

module "s3-data" {
  region             = var.region
  partition          = var.partition
  account-id         = var.account-id
  app-shorthand-name = var.app-shorthand-name
  app-name           = var.app-name
  terraform-role     = local.terraform-role
  tags               = local.tags
  base-name          = local.base-name

  bucket-name = "${local.base-name}.s3.analytics"
  versioning  = false
  source      = "../../modules/s3"
}

module "s3-logs" {
  region             = var.region
  partition          = var.partition
  account-id         = var.account-id
  app-shorthand-name = var.app-shorthand-name
  app-name           = var.app-name
  terraform-role     = local.terraform-role
  tags               = local.tags
  base-name          = local.base-name

  bucket-name     = "${local.base-name}.s3.glue-logs"
  versioning      = false
  expiration-days = 7
  source          = "../../modules/s3"
}

module "glue" {
  region             = var.region
  partition          = var.partition
  account-id         = var.account-id
  app-shorthand-name = var.app-shorthand-name
  app-name           = var.app-name
  terraform-role     = local.terraform-role
  tags               = local.tags
  base-name          = local.base-name

  read-bucket-arns    = [
    "${module.s3-data.outputs.arn}/*",
    "${module.s3-logs.outputs.arn}/*",
    "${module.s3-infra.outputs.arn}/*",
    module.s3-data.outputs.arn,
    module.s3-logs.outputs.arn,
    module.s3-infra.outputs.arn,
    module.s3-data.outputs.kms-arn,
    module.s3-logs.outputs.kms-arn,
    module.s3-infra.outputs.kms-arn
  ]
  write-bucket-arns    = [
    "${module.s3-data.outputs.arn}/*",
    "${module.s3-logs.outputs.arn}/*",
    module.s3-data.outputs.arn,
    module.s3-logs.outputs.arn,
    module.s3-data.outputs.kms-arn,
    module.s3-logs.outputs.kms-arn,
  ] 
  database-name  = "analytics"
  source                = "../../modules/glue"
}