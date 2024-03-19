/*
*   Create an ACM cert for use with ALB.
*/
locals {
  base-name = "${var.app-shorthand-name}.${var.region}"
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

  source              = "../terraform-main/aws/modules/pca"
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

  source      = "../terraform-main/aws/modules/acm"
  domain-name = "${local.base-name}.client"
  pca-arn     = module.pca.certificate_authority_arn
}
module "s3" {
  region             = var.region
  account-id         = var.account-id
  app-shorthand-name = var.app-shorthand-name
  app-name           = var.app-name
  terraform-role     = var.terraform-role
  tags               = var.tags
  base-name          = local.base-name
  partition          = var.partition

  bucket-name = "${local.base-name}.s3.acm"
  versioning  = false
  source      = "../terraform-main/aws/modules/s3"
}
resource "aws_s3_object" "trust" {
  bucket  = module.s3.outputs.name
  key     = "${module.pca.common_name}.pem"
  content = "${module.pca.certificate}\n\n${module.pca.certificate_chain}"
}

data "aws_subnets" "private" {
  filter {
    name   = "vpc-id"
    values = [var.vpc-id]
  }
  filter {
    name   = "tag:Name"
    values = ["*private*"]
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

  name        = replace(local.base-name, ".", "_")
  file-path   = "./handler.py"
  handler     = "handler.handler"
  runtime     = "python3.11"
  vpc-id      = var.vpc-id
  subnet-ids  = data.aws_subnets.private.ids
  layer_arns  = []
  environment = {}
  source      = "../terraform-main/aws/modules/lambda"
}

resource "aws_lambda_permission" "main" {
  statement_id  = "AllowExecutionFromALB"
  action        = "lambda:InvokeFunction"
  function_name = module.lambda.lambda_name
  principal     = "elasticloadbalancing.amazonaws.com"
  source_arn    = aws_lb_target_group.main.arn
}

resource "aws_lb_target_group" "main" {
  name        = "lambda-https-mtls"
  protocol    = "HTTPS"
  target_type = "lambda"
}

resource "aws_lb_target_group_attachment" "main" {
  target_group_arn = aws_lb_target_group.main.arn
  target_id        = module.lambda.lambda_arn
}

resource "aws_lb" "main" {
  name               = replace(local.base-name, ".", "-")
  internal           = true
  load_balancer_type = "application"
  subnets            = data.aws_subnets.private.ids

  enable_deletion_protection = false
}

resource "aws_lb_trust_store" "main" {
  name = replace(local.base-name, ".", "-")

  ca_certificates_bundle_s3_bucket = module.s3.outputs.name
  ca_certificates_bundle_s3_key    = aws_s3_object.trust.key

}

resource "aws_lb_listener" "main" {
  load_balancer_arn = aws_lb.main.arn
  port              = "443"
  protocol          = "HTTPS"
  certificate_arn   = module.acm.arn
  mutual_authentication {
    mode            = "verify"
    trust_store_arn = aws_lb_trust_store.main.arn
  }

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.main.arn
  }
}
