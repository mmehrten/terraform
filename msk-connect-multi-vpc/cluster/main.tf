/*
*   Create an MSK cluster with Redshift cluster, and streaming ingestion with Avro and Glue Schema Registry using a NAT gateway or a Lambda function.
*/
locals {
  base-name = "${var.app-shorthand-name}.${var.region}"
}

module "vpc" {
  region             = var.region
  account-id         = var.account-id
  app-shorthand-name = var.app-shorthand-name
  app-name           = var.app-name
  terraform-role     = var.terraform-role
  tags               = var.tags
  base-name          = local.base-name
  partition          = var.partition

  public-subnets  = var.public-subnets
  private-subnets = var.private-subnets
  cidr-block      = var.cidr-block
  source          = "../../terraform-main/aws/modules/vpc"
}

module "internet-gateway" {
  region             = var.region
  account-id         = var.account-id
  app-shorthand-name = var.app-shorthand-name
  app-name           = var.app-name
  terraform-role     = var.terraform-role
  tags               = var.tags
  base-name          = local.base-name
  partition          = var.partition

  vpc-id         = module.vpc.outputs.vpc-id
  subnet-ids     = module.vpc.outputs.public-subnet-ids
  route-table-id = module.vpc.outputs.public-route-table-id
  source         = "../../terraform-main/aws/modules/internet-gateway"
}

module "nat-gateway" {
  region             = var.region
  account-id         = var.account-id
  app-shorthand-name = var.app-shorthand-name
  app-name           = var.app-name
  terraform-role     = var.terraform-role
  tags               = var.tags
  base-name          = local.base-name
  partition          = var.partition

  vpc-id         = module.vpc.outputs.vpc-id
  subnet-id      = values(module.vpc.outputs.public-subnet-ids)[0]
  route-table-id = module.vpc.outputs.private-route-table-id
  source         = "../../terraform-main/aws/modules/nat-gateway"
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

  source              = "../../terraform-main/aws/modules/pca"
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

  source      = "../../terraform-main/aws/modules/acm"
  domain-name = "${local.base-name}.client"
  pca-arn     = module.pca.certificate_authority_arn
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

  vpc-id               = module.vpc.outputs.vpc-id
  tls-certificate-arns = [module.pca.certificate_authority_arn]
  source               = "../../terraform-main/aws/modules/msk"
}

resource "aws_msk_cluster_policy" "main" {
  cluster_arn = module.msk.cluster_arn

  policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Sid" : "AllowManageEndpoint",
        "Effect" : "Allow",
        "Principal" : { "AWS" : ["${var.shared-account-id}", "${var.account-id}"] },
        "Action" : [
          "kafka:CreateVpcConnection",
          "kafka:GetBootstrapBrokers",
          "kafka:DescribeCluster",
          "kafka:DescribeClusterV2",
        ],
        "Resource" : [module.msk.cluster_arn]
      },
      {
        "Sid" : "AllowConnect",
        "Effect" : "Allow",
        "Principal" : { "AWS" : ["arn:aws:iam::100781753907:role/spoke-zwy2.iam.role.msk.admin", "${var.account-id}"] },
        "Action" : [
          "kafka-cluster:Connect",
          "kafka-cluster:DescribeCluster"
        ],
        "Resource" : [module.msk.cluster_arn]
      },
      {
        "Sid" : "AllowTopicRead",
        "Effect" : "Allow",
        "Principal" : { "AWS" : ["arn:aws:iam::100781753907:role/spoke-zwy2.iam.role.msk.admin", "${var.account-id}"] },
        "Action" : [
          "kafka-cluster:ReadData",
          "kafka-cluster:DescribeTopic",
          "kafka-cluster:AlterTopicDynamicConfiguration",
        ],
        "Resource" : ["arn:${var.partition}:kafka:${var.region}:${var.account-id}:topic/${module.msk.cluster_name}/*"]
      },
      {
        "Sid" : "AllowTopiWrite",
        "Effect" : "Allow",
        "Principal" : { "AWS" : ["*"] },
        "Action" : [
          "kafka-cluster:WriteData",
          "kafka-cluster:CreateTopic",
          "kafka-cluster:AlterTopic",
          "kafka-cluster:DeleteTopic",
          "kafka-cluster:AlterTopicDynamicConfiguration",
        ],
        "Resource" : ["arn:${var.partition}:kafka:${var.region}:${var.account-id}:topic/${module.msk.cluster_name}/*"],
        "Condition" : { "ArnLike" : { "aws:PrincipalArn" : ["arn:aws:iam::100781753907:role/spoke-zwy2.iam.role.msk.admin"] } }
      },
      {
        "Sid" : "AllowManageGroups",
        "Effect" : "Allow",
        "Principal" : { "AWS" : ["arn:aws:iam::100781753907:role/spoke-zwy2.iam.role.msk.admin", "${var.account-id}"] },
        "Action" : [
          "kafka-cluster:AlterGroup",
          "kafka-cluster:DeleteGroup",
          "kafka-cluster:DescribeGroup"
        ],
        "Resource" : ["arn:${var.partition}:kafka:${var.region}:${var.account-id}:group/${module.msk.cluster_name}/*"]
      },
      {
        "Sid" : "AllowManageTransactions",
        "Effect" : "Allow",
        "Principal" : { "AWS" : ["arn:aws:iam::100781753907:role/spoke-zwy2.iam.role.msk.admin", "${var.account-id}"] },
        "Action" : [
          "kafka-cluster:DescribeTransactionalId",
          "kafka-cluster:AlterTransactionalId",
        ],
        "Resource" : "arn:${var.partition}:kafka:${var.region}:${var.account-id}:transactional-id/${module.msk.cluster_name}/*"
      }
    ]
  })
}

resource "aws_lb_target_group" "main" {
  for_each    = { for o in module.msk.broker_nodes : o.broker_id => o }
  name        = "msk-${each.value.broker_id}"
  port        = "9098"
  protocol    = "TCP"
  target_type = "ip"
  vpc_id      = module.vpc.outputs.vpc-id
}

resource "aws_lb_target_group_attachment" "main" {
  for_each         = { for o in module.msk.broker_nodes : o.broker_id => o }
  target_group_arn = aws_lb_target_group.main[each.key].arn
  target_id        = each.value.client_vpc_ip_address
  port             = "9098"
}

resource "aws_lb" "main" {
  for_each           = { for o in module.msk.broker_nodes : o.broker_id => o }
  name               = "msk-${each.value.broker_id}"
  internal           = true
  load_balancer_type = "network"
  subnets            = [each.value.client_subnet]

  enable_deletion_protection = false
}

resource "aws_lb_listener" "main-9098" {
  for_each          = { for o in module.msk.broker_nodes : o.broker_id => o }
  load_balancer_arn = aws_lb.main[each.key].arn
  port              = "9098"
  protocol          = "TCP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.main[each.key].arn
  }
}

resource "aws_lb_listener" "main-900X" {
  for_each          = { for o in module.msk.broker_nodes : o.broker_id => o }
  load_balancer_arn = aws_lb.main[each.key].arn
  port              = "900${each.key}"
  protocol          = "TCP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.main[each.key].arn
  }
}

resource "aws_vpc_endpoint_service" "main" {
  for_each                   = { for o in module.msk.broker_nodes : o.broker_id => o }
  acceptance_required        = true
  network_load_balancer_arns = [aws_lb.main[each.key].arn]
  allowed_principals         = ["arn:${var.partition}:iam::${var.shared-account-id}:root"]
}

output "endpoints" {
  value = {
    for k, v in aws_vpc_endpoint_service.main :
    one(v.availability_zones) => {
      "service_name" : v.service_name
      "service_type" : v.service_type
    }
  }
}
