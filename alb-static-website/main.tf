/*
*   Create an ALB that directs to an S3 bucket with an interface endpoint over HTTP.
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

data "aws_route_tables" "main" {
  filter {
    name   = "vpc-id"
    values = [var.vpc-id]
  }
  filter {
    name   = "tag:name"
    values = ["*private*"]
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

  bucket-name = "${local.base-name}.s3.static-web"
  versioning  = false
  use-cmk = false
  source      = "../terraform-main/aws/modules/s3"
}

module "intf" {
  region             = var.region
  account-id         = var.account-id
  app-shorthand-name = var.app-shorthand-name
  app-name           = var.app-name
  terraform-role     = var.terraform-role
  tags               = var.tags
  base-name          = local.base-name
  partition          = var.partition

  source               = "../terraform-main/aws/modules/vpc-endpoints"
  vpc-id               = var.vpc-id
  subnet-ids           = { for o in data.aws_subnets.main.ids : o => o }
  route-table-ids      = data.aws_route_tables.main.ids
  create-route53-zones = true
  create-org-zone = false
  endpoints            = { "s3" : null }
}

resource "aws_security_group" "main" {
  name        = "${local.base-name}.sg.alb"
  description = "Security group for ALB."
  vpc_id      = var.vpc-id

  ingress {
    description      = "Allow all inbound connections"
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = []
  }

  egress {
    description      = "Allow all outbound connections"
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = []
  }

  tags = {
    Name = "${local.base-name}.sg.alb"
  }
}

resource "aws_lb" "main" {
  name               = replace("${local.base-name}.alb.lb", ".", "-")
  load_balancer_type = "application"
  security_groups    = [aws_security_group.main.id]
  subnets            = data.aws_subnets.main.ids
  enable_deletion_protection = false
  internal = true
}

resource "aws_lb_target_group" "main" {
  name        = replace("${local.base-name}.alb.tg", ".", "-")
  port        = 80
  protocol    = "HTTP"
  target_type = "ip"
  vpc_id      = var.vpc-id
  health_check {
    protocol = "http"
    matcher= "307"
  }
}

resource "aws_lb_target_group_attachment" "main" {
  for_each = module.intf.endpoint_ips
  target_group_arn = aws_lb_target_group.main.arn
  target_id        = each.value.ip
  port             = 80
}

resource "aws_lb_listener" "main" {
  load_balancer_arn = aws_lb.main.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.main.arn
  }
}


resource "aws_lb_listener_rule" "static" {
  listener_arn = aws_lb_listener.main.arn
  priority     = 100

  action {
    type             = "redirect"
    redirect {
      path = "/#{path}index.html"
      port = "#{port}"
      status_code = "HTTP_301"
    }
  }

  condition {
    path_pattern {
      values = ["*/"]
    }
  }
}

resource "aws_route53_zone" "main" {
  name = "s3.static-web"
  vpc {
    vpc_id = var.vpc-id
  }
}

resource "aws_route53_record" "main" {
  zone_id = aws_route53_zone.main.zone_id
  name    = "*.s3.static-web"
  type     = "CNAME"
  set_identifier = "alb"
  records        = [aws_lb.main.dns_name]
  ttl     = 5

  weighted_routing_policy {
    weight = 100
  }
}