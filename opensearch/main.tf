/*
*   Create an OpenSearch cluster and assocaited infrastructure.
*/
locals {
  base-name = "${var.app-shorthand-name}.${var.region}"
}


module "opensearch" {
  region             = var.region
  account-id         = var.account-id
  app-shorthand-name = var.app-shorthand-name
  app-name           = var.app-name
  terraform-role     = var.terraform-role
  tags               = var.tags
  base-name          = local.base-name
  partition          = var.partition

  vpc-id      = var.vpc-id
  domain-name = replace("${local.base-name}.demo", ".", "-")
  source      = "../terraform-main/aws/modules/opensearch"
}

data "aws_subnets" "main" {
  filter {
    name   = "vpc-id"
    values = [var.vpc-id]
  }
  filter {
    name   = "map-public-ip-on-launch"
    values = [false]
  }
}

module "cloudwatch-parse-lambda" {
  region             = var.region
  account-id         = var.account-id
  app-shorthand-name = var.app-shorthand-name
  app-name           = var.app-name
  terraform-role     = var.terraform-role
  tags               = var.tags
  base-name          = local.base-name
  partition          = var.partition

  name = "cloudwatch-firehose-processor"
  policy = jsonencode(
    {
      "Version" : "2012-10-17",
      "Statement" : [
        {
          "Effect" : "Allow",
          "Action" : "kinesis-firehose:*",
          "Resource" : "*"
        }
      ]
  })
  file-path  = "./cloudwatch_kinesis_firehose.py"
  handler    = "cloudwatch_kinesis_firehose.lambda_handler"
  runtime    = "python3.9"
  vpc-id     = var.vpc-id
  subnet-ids = data.aws_subnets.main.ids
  source     = "../terraform-main/aws/modules/lambda"
  timeout    = 300
}


module "os-configure-lambda" {
  region             = var.region
  account-id         = var.account-id
  app-shorthand-name = var.app-shorthand-name
  app-name           = var.app-name
  terraform-role     = var.terraform-role
  tags               = var.tags
  base-name          = local.base-name
  partition          = var.partition

  name = "opensearch-configurer"
  policy = jsonencode(
    {
      "Version" : "2012-10-17",
      "Statement" : [
        {
          "Effect" : "Allow",
          "Action" : "es:*",
          "Resource" : "${module.opensearch.arn}"
        }
      ]
  })
  file-path  = "./opensearch.py"
  handler    = "opensearch.handler"
  runtime    = "python3.9"
  vpc-id     = var.vpc-id
  subnet-ids = data.aws_subnets.main.ids
  layer_arns = [
    "arn:aws-us-gov:lambda:us-gov-west-1:053633994311:layer:opensearch-py:3"
  ]
  environment = {
    OPENSEARCH_ENDPOINT = module.opensearch.endpoint
  }
  source  = "../terraform-main/aws/modules/lambda"
  timeout = 300
}
