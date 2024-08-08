/*
*   Create an MSK cluster and an NLB with a custom domain name (e.g. for a migration scenario).
*/
locals {
  base-name = "${var.app-shorthand-name}.${var.region}"
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
  subject-alternative-names = [
    "b-1.${local.base-name}.client",
    "b-2.${local.base-name}.client",
    "b-3.${local.base-name}.client"
  ]
}

resource "aws_security_group" "nlb" {
  name        = "${local.base-name}.sg.nlb"
  description = "Security group for NLB in front of MSK cluster."
  vpc_id      = var.vpc-id

  ingress {
    from_port        = 9000
    to_port          = 9003
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
    description = "Allow NLB ingress on custom SASL/SCRAM ports"
  }
  tags = {
    Name = "${local.base-name}.sg.nlb"
  }
}
resource "aws_security_group_rule" "nlb-egress" {
  security_group_id = aws_security_group.nlb.id
  type = "egress"
  from_port        = 9096
  to_port          = 9096
  protocol         = "-1"
  source_security_group_id = aws_security_group.msk.id
  description = "Allow NLB health checks to MSK on SASL/SCRAM ports"
}

resource "aws_security_group" "msk" {
  name        = "${local.base-name}.sg.msk"
  description = "Security group for MSK cluster."
  vpc_id      = var.vpc-id

  ingress {
    from_port        = 9000
    to_port          = 9099
    protocol         = "tcp"
    security_groups = [aws_security_group.nlb.id]
    description = "Allow NLB ingress on custom SASL/SCRAM ports"
  }

  tags = {
    Name = "${local.base-name}.sg.msk"
  }
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

  vpc-id               = var.vpc-id
  source               = "../terraform-main/aws/modules/msk"
  tls-certificate-arns = [module.pca.certificate_authority_arn]
  enable-vpc-connectivity = false
  security-group-ids = [aws_security_group.msk.id]
  # kafka-version = "3.8.0"
}

## Create SASL/SCRAM user in the cluster
resource "aws_kms_key" "main" {
  description             = "${local.base-name} MSK SecretsManager key."
  deletion_window_in_days = 7
  enable_key_rotation     = "true"
  tags = {
    "Name" = "${local.base-name}.kms.AmazonMSK"
  }
}
resource "aws_kms_alias" "alias" {
  name          = replace("alias/${local.base-name}.kms.AmazonMSK_Secret", ".", "_")
  target_key_id = aws_kms_key.main.key_id
}
resource "aws_secretsmanager_secret" "main" {
  name       = "AmazonMSK_Secret"
  kms_key_id = aws_kms_key.main.id
}
resource "aws_secretsmanager_secret_version" "main" {
  secret_id     = aws_secretsmanager_secret.main.id
  secret_string = jsonencode({ "username" : var.scram-username, "password" : var.scram-password })
}
resource "aws_msk_scram_secret_association" "main" {
  cluster_arn     = module.msk.cluster_arn
  secret_arn_list = [aws_secretsmanager_secret.main.arn]
  depends_on      = [aws_secretsmanager_secret_version.main]
}

## Create NLB with custom domain name for MSK
# NOTE: Must create MSK cluster before commenting out NLB due to Terraform for_each logic :( 
# Moving these definitions to two separate steps would fix

# resource "aws_lb" "all" {
#   name               = replace("${local.base-name}", ".", "-")
#   internal           = true
#   load_balancer_type = "network"
#   subnets            = data.aws_subnets.private.ids

#   enable_deletion_protection       = false
#   security_groups                  = [aws_security_group.nlb.id]
#   enable_cross_zone_load_balancing = true
# }
# resource "aws_lb_target_group" "all" {
#   name        = "msk-all"
#   port        = "9096"
#   protocol    = "TLS"
#   target_type = "ip"
#   vpc_id      = var.vpc-id
# }
# resource "aws_lb_target_group_attachment" "all" {
#   for_each         = { for o in module.msk.broker_nodes : o.broker_id => o }
#   target_group_arn = aws_lb_target_group.all.arn
#   target_id        = each.value.client_vpc_ip_address
#   port             = "9096"
# }
# resource "aws_lb_target_group" "brokers" {
#   for_each    = { for o in module.msk.broker_nodes : o.broker_id => o }
#   name        = "msk-b-${each.key}"
#   port        = "9096"
#   protocol    = "TLS"
#   target_type = "ip"
#   vpc_id      = var.vpc-id
# }
# resource "aws_lb_target_group_attachment" "brokers" {
#   for_each         = { for o in module.msk.broker_nodes : o.broker_id => o }
#   target_group_arn = aws_lb_target_group.brokers[each.key].arn
#   target_id        = each.value.client_vpc_ip_address
#   port             = "9096"
# }
# resource "aws_lb_listener" "all" {
#   load_balancer_arn = aws_lb.all.arn
#   port              = "9000"
#   protocol          = "TLS"
#   certificate_arn   = module.acm.arn

#   default_action {
#     type             = "forward"
#     target_group_arn = aws_lb_target_group.all.arn
#   }
# }
# resource "aws_lb_listener" "brokers" {
#   for_each          = { for o in module.msk.broker_nodes : o.broker_id => o }
#   load_balancer_arn = aws_lb.all.arn
#   port              = string(9000 + each.key)
#   protocol          = "TLS"
#   certificate_arn   = module.acm.arn

#   default_action {
#     type             = "forward"
#     target_group_arn = aws_lb_target_group.brokers[each.key].arn
#   }
# }
# resource "aws_route53_zone" "main" {
#   name = join(".", slice(split(".", module.acm.domain_name), 1, length(split(".", module.acm.domain_name))))
#   vpc {
#     vpc_id = var.vpc-id
#   }
# }
# resource "aws_route53_record" "all" {
#   zone_id = aws_route53_zone.main.zone_id
#   name    = module.acm.domain_name
#   type    = "CNAME"
#   ttl     = 300
#   records = [aws_lb.all.dns_name]
# }
# resource "aws_route53_record" "brokers" {
#   for_each = { for o in module.msk.broker_nodes : o.broker_id => o }
#   zone_id  = aws_route53_zone.main.zone_id
#   name     = "b-${each.key}.${module.acm.domain_name}"
#   type     = "CNAME"
#   ttl      = 300
#   records  = [aws_lb.all.dns_name]
# }