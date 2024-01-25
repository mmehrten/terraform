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

  vpc-id          = var.vpc-id
  domain-name     = replace("${local.base-name}.${var.cluster-id}", ".", "-")
  master-password = var.opensearch-master-password
  source          = "../terraform-main/aws/modules/opensearch"
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

  name = "cloudwatch-firehose-processor-${var.cluster-id}"
  policy = jsonencode(
    {
      "Version" : "2012-10-17",
      "Statement" : [
        {
          "Effect" : "Allow",
          "Action" : "kinesis-firehose:*",
          "Resource" : "*"
        },
        {
          "Effect" : "Allow",
          "Action" : "kinesis:*",
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

  name = "opensearch-configurer-${var.cluster-id}"
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

# module "os-write-lambda" {
#   region             = var.region
#   account-id         = var.account-id
#   app-shorthand-name = var.app-shorthand-name
#   app-name           = var.app-name
#   terraform-role     = var.terraform-role
#   tags               = var.tags
#   base-name          = local.base-name
#   partition          = var.partition

#   name = "opensearch-writer-${var.cluster-id}"
#   policy = jsonencode(
#     {
#       "Version" : "2012-10-17",
#       "Statement" : [
#         {
#           "Effect" : "Allow",
#           "Action" : "es:*",
#           "Resource" : "${module.opensearch.arn}"
#         }
#       ]
#   })
#   file-path  = "./writer.py"
#   handler    = "writer.handler"
#   runtime    = "python3.9"
#   vpc-id     = var.vpc-id
#   subnet-ids = data.aws_subnets.main.ids
#   layer_arns = [
#     "arn:aws-us-gov:lambda:us-gov-west-1:053633994311:layer:opensearch-py:3"
#   ]
#   environment = {
#     OPENSEARCH_ENDPOINT = module.opensearch.endpoint
#   }
#   source  = "../terraform-main/aws/modules/lambda"
#   timeout = 300
# }

# resource "aws_cloudwatch_event_rule" "main" {
#   name                = "opensearch-writer"
#   schedule_expression = "rate(1 minute)"
# }

# resource "aws_cloudwatch_event_target" "main" {
#   rule      = aws_cloudwatch_event_rule.main.name
#   target_id = aws_cloudwatch_event_rule.main.name
#   arn       = module.os-write-lambda.lambda_arn
# }

# resource "aws_lambda_permission" "main" {
#   statement_id  = "AllowExecutionFromEventBridge"
#   action        = "lambda:InvokeFunction"
#   function_name = module.os-write-lambda.lambda_arn
#   principal     = "events.amazonaws.com"
#   source_arn    = aws_cloudwatch_event_rule.main.arn
# }


module "s3-data" {
  region             = var.region
  account-id         = var.account-id
  app-shorthand-name = var.app-shorthand-name
  app-name           = var.app-name
  terraform-role     = var.terraform-role
  tags               = var.tags
  base-name          = local.base-name
  partition          = var.partition

  bucket-name = "${local.base-name}.s3.opensearch.snapshot"
  versioning  = false
  source      = "../terraform-main/aws/modules/s3"
}

resource "aws_iam_role_policy" "main" {
  name = "${var.app-shorthand-name}.iam.policy.opensearch.snapshot"
  role = aws_iam_role.main.id
  policy = jsonencode(
    {
      "Version" : "2012-10-17",
      "Statement" : [
        {
          "Action" : [
            "s3:ListBucket"
          ],
          "Effect" : "Allow",
          "Resource" : [
            module.s3-data.outputs.arn
          ]
        },
        {
          "Action" : [
            "s3:GetObject",
            "s3:PutObject",
            "s3:DeleteObject"
          ],
          "Effect" : "Allow",
          "Resource" : [
            "${module.s3-data.outputs.arn}/*"
          ]
        },
        {
          "Action" : [
            "kms:GenerateDataKey",
            "kms:Encrypt",
            "kms:Decrypt",
          ],
          "Effect" : "Allow",
          "Resource" : [
            module.s3-data.outputs.kms-arn
          ]
        }

      ]
  })
}

resource "aws_iam_role" "main" {
  name                = "${var.app-shorthand-name}.iam.role.opensearch.snapshot"
  managed_policy_arns = []
  assume_role_policy = jsonencode(
    {
      "Version" : "2012-10-17",
      "Statement" : [
        {
          "Action" : "sts:AssumeRole",
          "Principal" : { "Service" : "es.amazonaws.com" },
          "Effect" : "Allow",
          "Condition" : {
            "StringEquals" : {
              "aws:SourceAccount" : "${var.account-id}"
            },
            "ArnLike" : {
              "aws:SourceArn" : module.opensearch.arn
            }
          }
        }
      ]
    }
  )
}

resource "aws_iam_role_policy" "admin-snap" {
  name = "${var.app-shorthand-name}.iam.policy.opensearch.admin-snap"
  role = module.os-configure-lambda.iam_role_id
  policy = jsonencode(
    {
      "Version" : "2012-10-17",
      "Statement" : [
        {
          "Effect" : "Allow",
          "Action" : "iam:PassRole",
          "Resource" : aws_iam_role.main.arn
        },
        {
          "Effect" : "Allow",
          "Action" : "es:ESHttpPut",
          "Resource" : module.opensearch.arn
        }
      ]
    }
  )
}

