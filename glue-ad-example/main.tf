/*
*   Create an OpenSearch cluster and assocaited infrastructure.
*/
locals {
  base-name = "${var.app-shorthand-name}.${var.region}"
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

module "s3-data" {
  region             = var.region
  account-id         = var.account-id
  app-shorthand-name = var.app-shorthand-name
  app-name           = var.app-name
  terraform-role     = var.terraform-role
  tags               = var.tags
  base-name          = local.base-name
  partition          = var.partition

  bucket-name = "${local.base-name}.s3.analytics"
  versioning  = false
  source      = "../terraform-main/aws/modules/s3"
}

module "writer-lambda" {
  region             = var.region
  account-id         = var.account-id
  app-shorthand-name = var.app-shorthand-name
  app-name           = var.app-name
  terraform-role     = var.terraform-role
  tags               = var.tags
  base-name          = local.base-name
  partition          = var.partition

  name = replace("${local.base-name}.s3-writer", ".", "-")
  policy = jsonencode(
    {
      "Version" : "2012-10-17",
      "Statement" : [
        {
          "Effect" : "Allow",
          "Action" : "s3:*",
          "Resource" : [
            "${module.s3-data.outputs.arn}",
            "${module.s3-data.outputs.arn}/*"
          ]
        },
        {
          "Effect" : "Allow",
          "Action" : "kms:*",
          "Resource" : "${module.s3-data.outputs.kms-arn}"
        }
      ]
  })
  file-path  = "./writer.py"
  handler    = "writer.handler"
  runtime    = "python3.9"
  vpc-id     = var.vpc-id
  subnet-ids = data.aws_subnets.main.ids
  environment = {
    "BUCKET_NAME" : module.s3-data.outputs.name
  }
  layer_arns = [
    "arn:aws:lambda:us-east-1:017000801446:layer:AWSLambdaPowertoolsPythonV2:58"
  ]
  source  = "../terraform-main/aws/modules/lambda"
  timeout = 300
}

resource "aws_cloudwatch_event_rule" "main" {
  name                = "opensearch-writer"
  schedule_expression = "rate(5 minutes)"
}

resource "aws_cloudwatch_event_target" "main" {
  rule      = aws_cloudwatch_event_rule.main.name
  target_id = aws_cloudwatch_event_rule.main.name
  arn       = module.writer-lambda.lambda_arn
}

resource "aws_lambda_permission" "main" {
  statement_id  = "AllowExecutionFromEventBridge"
  action        = "lambda:InvokeFunction"
  function_name = module.writer-lambda.lambda_arn
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.main.arn
}
