/*
*   Create hub VPC with VPC endpoints and an internet gateway, to be used as a transit hub for other VPCs.
*/
locals {
  base-name = "${var.app-shorthand-name}.${var.region}"
  subnets = {
    "10.0.2.4": {
        "endpoint_ip": "10.0.2.4", 
        "az": "us-gov-west-1a",
        "subnet_id": "subnet-0838c0a690833fd5d"
      },
    "10.0.3.222": {
        "endpoint_ip": "10.0.3.222", 
        "az": "us-gov-west-1b",
        "subnet_id": "subnet-00b3db3f74902bc0a"
      },
    "10.0.5.220": {
        "endpoint_ip": "10.0.5.220", 
        "az": "us-gov-west-1c",
        "subnet_id": "subnet-093de3674c6f2c16e"
      },
  }
}

module "health-check-lambda" {
  for_each = local.subnets
  region             = var.region
  account-id         = var.account-id
  app-shorthand-name = var.app-shorthand-name
  app-name           = var.app-name
  terraform-role     = var.terraform-role
  tags               = var.tags
  base-name          = local.base-name
  partition = var.partition

  policy = jsonencode(
    {
      "Version": "2012-10-17",
      "Statement": [
          {
              "Effect": "Allow",
              "Action": "lambda:InvokeFunction",
              "Resource": "arn:${var.partition}:lambda:${var.region}:${var.account-id}:function:s3-hc-${each.value.az}"
          },
          {
              "Effect": "Allow",
              "Action": "s3:ListAllMyBuckets",
              "Resource": "*"
          }

      ]
  })
  name = "s3-hc-${each.value.az}"
  file-path = "./s3_health_check.py"
  handler = "s3_health_check.lambda_handler"
  runtime = "python3.9"
  environment = {"ENDPOINT_IP": each.value.endpoint_ip, "REGION": var.region}
  subnet-ids = [each.value.subnet_id]
  security-group-ids = ["sg-0801857305a6d44cb"]
  source          = "../terraform-main/aws/modules/lambda"
}

resource "aws_cloudwatch_event_rule" "every5minutes" {
  for_each = local.subnets
  name = "s3-health-check-${each.value.az}"
  schedule_expression = "rate(5 minutes)"
}

resource "aws_cloudwatch_event_target" "lambda" {
  for_each = local.subnets
  rule      = aws_cloudwatch_event_rule.every5minutes[each.key].name
  target_id = aws_cloudwatch_event_rule.every5minutes[each.key].name
  arn       = module.health-check-lambda[each.key].lambda_arn
}

resource "aws_lambda_permission" "allow_eventbridge" {
  for_each = local.subnets
  statement_id  = "AllowExecutionFromEventBridge"
  action        = "lambda:InvokeFunction"
  function_name = module.health-check-lambda[each.key].lambda_arn
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.every5minutes[each.key].arn
}

resource "aws_cloudwatch_metric_alarm" "health-checks" {
  for_each = local.subnets
  alarm_name                = "s3-health-check-${each.value.az}"
  comparison_operator       = "GreaterThanOrEqualToThreshold"
  evaluation_periods        = 2
  datapoints_to_alarm = 2
  metric_name               = "Errors"
  namespace                 = "AWS/Lambda"
  period                    = 900
  statistic                 = "Maximum"
  threshold                 = 1
  alarm_description         = "Errors in health check lambda"
  insufficient_data_actions = []
  dimensions = {
    FunctionName = "s3-hc-${each.value.az}"
  }
  treat_missing_data ="breaching"
}

module "vpc-endpoints" {
  region             = var.region
  account-id         = var.account-id
  app-shorthand-name = var.app-shorthand-name
  app-name           = var.app-name
  terraform-role     = var.terraform-role
  tags               = var.tags
  base-name          = local.base-name
  partition = var.partition

  endpoints = {"s3": null}
  vpc-id          = var.vpc-id
  subnet-ids      = var.subnet-ids
  route-table-ids = var.route-table-ids
  create-route53-zones = true
  create-org-zone = false
  source          = "../terraform-main/aws/modules/vpc-endpoints"
}
