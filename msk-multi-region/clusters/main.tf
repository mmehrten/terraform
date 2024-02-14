/*
*   Create an MSK cluster with Redshift cluster, and streaming ingestion with Avro and Glue Schema Registry using a NAT gateway or a Lambda function.
*/
locals {
  base-name = "${var.app-shorthand-name}.${var.region}"
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

module "vpc-endpoints" {
  region             = var.region
  account-id         = var.account-id
  app-shorthand-name = var.app-shorthand-name
  app-name           = var.app-name
  terraform-role     = var.terraform-role
  tags               = var.tags
  base-name          = local.base-name
  partition          = var.partition

  vpc-id               = module.vpc.outputs.vpc-id
  subnet-ids           = module.vpc.outputs.private-subnet-ids
  route-table-ids      = [module.vpc.outputs.public-route-table-id, module.vpc.outputs.private-route-table-id]
  source               = "../../terraform-main/aws/modules/vpc-endpoints"
  create-route53-zones = false
  create-org-zone      = false
  endpoints = {
    "redshift-data" = null,
    "glue"          = null,
    "sts"           = null,
    "lambda"        = null,
  }
}

module "pca" {
  region             = var.region
  account-id         = var.account-id
  app-shorthand-name = var.app-shorthand-name
  app-name           = var.app-name
  terraform-role     = var.terraform-role
  tags               = var.tags
  base-name          = local.base-name
  partition          = var.partition

  source              = "../../terraform-main/aws/modules/pca"
  subject-common-name = local.base-name
}

module "acm" {
  region             = var.region
  account-id         = var.account-id
  app-shorthand-name = var.app-shorthand-name
  app-name           = var.app-name
  terraform-role     = var.terraform-role
  tags               = var.tags
  base-name          = local.base-name
  partition          = var.partition

  source      = "../../terraform-main/aws/modules/acm"
  domain-name = "${local.base-name}.client"
  pca-arn     = module.pca.certificate_authority_arn
}

module "msk" {
  region             = var.region
  account-id         = var.account-id
  app-shorthand-name = var.app-shorthand-name
  app-name           = var.app-name
  terraform-role     = var.terraform-role
  tags               = var.tags
  base-name          = local.base-name
  partition          = var.partition

  vpc-id               = module.vpc.outputs.vpc-id
  source               = "../../terraform-main/aws/modules/msk"
  tls-certificate-arns = [module.pca.certificate_authority_arn]
}

module "kafka-publisher-lambda" {
  region             = var.region
  account-id         = var.account-id
  app-shorthand-name = var.app-shorthand-name
  app-name           = var.app-name
  terraform-role     = var.terraform-role
  tags               = var.tags
  base-name          = local.base-name
  partition          = var.partition

  name = "msk-publisher-${var.region}"
  policy = jsonencode(
    {
      "Version" : "2012-10-17",
      "Statement" : [
        {
          "Effect" : "Allow",
          "Action" : "glue:*",
          "Resource" : "*"
          }, {
          "Effect" : "Allow",
          "Action" : "acm:ExportCertificate",
          "Resource" : "*"
          }, {
          "Effect" : "Allow",
          "Action" : "kafka-cluster:*",
          "Resource" : "*"
        }
      ]
  })
  file-path  = "./kafka_publisher/"
  handler    = "handler.handler"
  runtime    = "python3.9"
  vpc-id     = module.vpc.outputs.vpc-id
  subnet-ids = values(module.vpc.outputs.private-subnet-ids)
  layer_arns = [
    "arn:${var.partition}:lambda:${var.region}:${var.account-id}:layer:avro:1",
    "arn:${var.partition}:lambda:${var.region}:${var.account-id}:layer:kafka-python:1",
    "arn:${var.partition}:lambda:${var.region}:${var.account-id}:layer:aws-msk-iam-sasl-signer-python:1",
    "arn:${var.partition}:lambda:${var.region}:${var.account-id}:layer:aws-lambda-powertools:5"
  ]
  environment = {
    AWS_ACM_CERT_PASS = var.private-cert-passphrase,
  }
  source = "../../terraform-main/aws/modules/lambda"
}

# data "aws_subnet" "selected" {
#   for_each   = { for o in module.msk.broker_nodes : o.broker_id => o }
#   id         = each.value.client_subnet
# }
# output "broker_nodes" {
#   value = [
#     for o in module.msk.broker_nodes : {
#       "ip" : o.client_vpc_ip_address,
#       "id" : o.broker_id,
#       "availability_zone" : data.aws_subnet.selected[o.broker_id].availability_zone
#     }
#   ]
# }
# output "broker_zone" {
#   value = join(".", slice(split(".", split(":", module.msk.bootstrap_brokers_sasl_iam)[0]), 1, 8))
# }
# output "vpc_id" {
#   value = module.vpc.outputs.vpc-id
# }
