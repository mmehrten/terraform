/*
*   Create hub VPC with VPC endpoints and an internet gateway, to be used as a transit hub for other VPCs.
*/
locals {
  base-name = "${var.app-shorthand-name}.${var.region}"
}



module "s3-web" {
  region             = var.region
  account-id         = var.account-id
  app-shorthand-name = var.app-shorthand-name
  app-name           = var.app-name
  terraform-role     = var.terraform-role
  tags               = var.tags
  base-name          = local.base-name
  partition          = var.partition

  bucket-name = "${local.base-name}.s3.web"
  versioning  = false
  source      = "../../../terraform-main/aws/modules/s3"
}

module "cognito" {
  region             = var.region
  account-id         = var.account-id
  app-shorthand-name = var.app-shorthand-name
  app-name           = var.app-name
  terraform-role     = var.terraform-role
  tags               = var.tags
  base-name          = local.base-name
  partition          = var.partition

  source = "../../../terraform-main/aws/modules/cognito"
}

module "ddb" {
  region             = var.region
  account-id         = var.account-id
  app-shorthand-name = var.app-shorthand-name
  app-name           = var.app-name
  terraform-role     = var.terraform-role
  tags               = var.tags
  base-name          = local.base-name
  partition          = var.partition

  table-name   = "Rides"
  billing-mode = "PAY_PER_REQUEST"
  hash-key     = "RideId"
  hash-type    = "S"
  source       = "../../../terraform-main/aws/modules/dynamodb"
}

data "aws_subnet_ids" "main" {
  vpc_id = var.vpc-id

  filter {
    name   = "tag:Name"
    values = ["*private*"]
  }
}

resource "aws_security_group" "main" {
  name        = "${var.base-name}.sg.lambda"
  description = "Security group for Lambda functions."
  vpc_id      = var.vpc-id

  # ingress {
  #   description      = "Allow no inbound connections"
  #   from_port        = 0
  #   to_port          = 0
  #   protocol         = "tcp"
  #   cidr_blocks      = []
  #   ipv6_cidr_blocks = []
  # }

  egress {
    description      = "Allow all outbound connections"
    from_port        = 0
    to_port          = 65535
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = []
  }

  tags = {
    Name = "${var.base-name}.sg.lambda"
  }
}

module "lambda" {
  region             = var.region
  account-id         = var.account-id
  app-shorthand-name = var.app-shorthand-name
  app-name           = var.app-name
  terraform-role     = var.terraform-role
  tags               = var.tags
  base-name          = local.base-name
  partition          = var.partition

  subnet-ids         = data.aws_subnet_ids.main.ids
  security-group-ids = [aws_security_group.main.id]
  name               = "serverless-demo"
  file-path          = "../../src/main.js"
  handler            = "main.handler"
  runtime            = "nodejs16.x"
  policy             = <<EOF
{
   "Version": "2012-10-17",
   "Statement": [
        {
            "Effect": "Allow",
            "Action": "dynamodb:PutItem",
            "Resource": "${module.ddb.arn}"
        }
   ]
}
EOF
  source             = "../../../terraform-main/aws/modules/lambda"
}



