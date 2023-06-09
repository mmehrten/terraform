/*
* Create a basic Lambda function and IAM role.
*/

resource "aws_iam_role_policy" "main" {
  name   = "${var.app-shorthand-name}.iam.role.lambda.${var.name}"
  role   = aws_iam_role.main.id
  policy = var.policy
}

resource "aws_iam_role_policy" "ec2" {
  name   = "${var.app-shorthand-name}.iam.role.lambda.${var.name}.ec2"
  role   = aws_iam_role.main.id
  policy = jsonencode(
{
 "Version": "2012-10-17",
 "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "ec2:DescribeNetworkInterfaces",
        "ec2:CreateNetworkInterface",
        "ec2:DeleteNetworkInterface",
        "ec2:DescribeInstances",
        "ec2:AttachNetworkInterface"
      ],
      "Resource": "*"
    },
            {
            "Effect": "Allow",
            "Action": [
                "logs:CreateLogGroup",
                "logs:CreateLogStream",
                "logs:PutLogEvents",
                "cloudwatch:*"
            ],
            "Resource": "*"
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
     "Principal": {
       "Service": "lambda.amazonaws.com",
     },
     "Effect": "Allow",
     "Sid": ""
   }
 ]
}
EOF
}

data "archive_file" "main" {
  type        = "zip"
  source_file = var.file-path
  output_path = "lambda.zip"
}

resource "aws_lambda_function" "main" {
  filename         = "lambda.zip"
  function_name    = var.name
  role             = aws_iam_role.main.arn
  handler          = var.handler
  source_code_hash = data.archive_file.main.output_base64sha256
  runtime          = var.runtime
  environment {
    variables = var.environment
  }
  vpc_config {
    subnet_ids         = var.subnet-ids
    security_group_ids = var.security-group-ids
  }
}

output "lambda_arn" {
  value = aws_lambda_function.main.arn
}
output "iam_arn" {
  value = aws_iam_role.main.arn
}

