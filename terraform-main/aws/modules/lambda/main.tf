/*
* Create a basic Lambda function and IAM role.
*/

resource "aws_iam_role_policy" "main" {
  name   = "${var.app-shorthand-name}.iam.role.lambda.${var.name}"
  role   = aws_iam_role.main.id
  policy = var.policy
}

resource "aws_iam_role_policy" "ec2" {
  name = "${var.app-shorthand-name}.iam.role.lambda.${var.name}.ec2"
  role = aws_iam_role.main.id
  policy = jsonencode(
    {
      "Version" : "2012-10-17",
      "Statement" : [
        {
          "Effect" : "Allow",
          "Action" : [
            "ec2:DescribeNetworkInterfaces",
            "ec2:CreateNetworkInterface",
            "ec2:DeleteNetworkInterface",
            "ec2:DescribeInstances",
            "ec2:AttachNetworkInterface",
            "ec2:DescribeSecurityGroups",
            "ec2:DescribeSubnets",
            "ec2:DescribeVpcs"
          ],
          "Resource" : "*"
        },
        {
          "Effect" : "Allow",
          "Action" : [
            "logs:CreateLogGroup",
            "logs:CreateLogStream",
            "logs:PutLogEvents",
            "cloudwatch:*"
          ],
          "Resource" : "*"
        }

      ]
  })
}



resource "aws_iam_role" "main" {
  name                = "${var.app-shorthand-name}.iam.role.lambda.${var.name}"
  managed_policy_arns = []
  assume_role_policy  = <<EOF
{
 "Version": "2012-10-17",
 "Statement": [
   {
     "Action": "sts:AssumeRole",
     "Principal": {"Service": "lambda.amazonaws.com"},
     "Effect": "Allow"
   }
 ]
}
EOF
}

data "archive_file" "main" {
  type        = "zip"
  source_file = endswith(var.file-path, "/") ? null : var.file-path
  source_dir  = endswith(var.file-path, "/") ? var.file-path : null
  output_path = "${var.name}.zip"
}

resource "aws_security_group" "main" {
  count       = var.subnet-ids != null ? 1 : 0
  name        = "${var.base-name}.sg.lambda.${var.name}"
  description = "Security group for Lambda."
  vpc_id      = var.vpc-id
  egress {
    description      = "Allow all outbound connections"
    from_port        = 0
    to_port          = 65535
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = []
  }
}

resource "aws_lambda_function" "main" {
  filename         = "${var.name}.zip"
  function_name    = var.name
  role             = aws_iam_role.main.arn
  handler          = var.handler
  source_code_hash = data.archive_file.main.output_base64sha256
  runtime          = var.runtime
  timeout          = var.timeout
  environment {
    variables = var.environment
  }
  vpc_config {
    subnet_ids         = var.subnet-ids
    security_group_ids = concat(var.security-group-ids, [for o in aws_security_group.main : o.id])
  }
  layers = var.layer_arns

}

output "lambda_name" {
  value = aws_lambda_function.main.function_name
}
output "lambda_arn" {
  value = aws_lambda_function.main.arn
}
output "iam_arn" {
  value = aws_iam_role.main.arn
}

output "iam_role_id" {
  value = aws_iam_role.main.id
}

