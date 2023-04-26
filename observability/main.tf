/*
*   Create hub VPC with VPC endpoints and an internet gateway, to be used as a transit hub for other VPCs.
*/
locals {
  base-name = "${var.app-shorthand-name}.${var.region}"
}

module "cluster" {
  region             = var.region
  account-id         = var.account-id
  app-shorthand-name = var.app-shorthand-name
  app-name           = var.app-name
  terraform-role     = var.terraform-role
  tags               = var.tags
  base-name          = local.base-name
  partition          = var.partition

  source = "../terraform-main/aws/modules/ecs-cluster"
}

data "aws_subnet_ids" "public" {
  vpc_id = var.vpc-id
  filter {
    name   = "tag:Name"
    values = ["*public*"]
  }
}

resource "aws_service_discovery_private_dns_namespace" "main" {
  name        = "${local.base-name}.local"
  description = "${local.base-name} service discovery"
  vpc         = var.vpc-id
}

resource "aws_ssm_parameter" "dns" {
  name  = "ECS-ServiceDiscovery-Namespaces"
  type  = "String"
  value = "${aws_service_discovery_private_dns_namespace.main.name},"
}

resource "aws_ssm_parameter" "conf" {
  name  = "ECS-Prometheus-Configuration"
  type  = "String"
  value = <<EOF
global:
  evaluation_interval: 1m
  scrape_interval: 30s
  scrape_timeout: 10s
remote_write:
  - url: http://localhost:8080/workspaces/WORKSPACE/api/v1/remote_write
scrape_configs:
  - job_name: ecs_services
    file_sd_configs:
      - files:
          - /etc/config/ecs-services.json
        refresh_interval: 30s
EOF
}

module "grafana" {
  region             = var.region
  account-id         = var.account-id
  app-shorthand-name = var.app-shorthand-name
  app-name           = var.app-name
  terraform-role     = var.terraform-role
  tags               = var.tags
  base-name          = local.base-name
  partition          = var.partition

  vpc-id                         = var.vpc-id
  subnet-ids                     = data.aws_subnet_ids.public.ids
  cluster-id                     = module.cluster.id
  service-discovery-namespace-id = aws_service_discovery_private_dns_namespace.main.id
  source                         = "../terraform-main/aws/modules/grafana-ecs"
}

module "prometheus" {
  region             = var.region
  account-id         = var.account-id
  app-shorthand-name = var.app-shorthand-name
  app-name           = var.app-name
  terraform-role     = var.terraform-role
  tags               = var.tags
  base-name          = local.base-name
  partition          = var.partition

  vpc-id                         = var.vpc-id
  subnet-ids                     = data.aws_subnet_ids.public.ids
  cluster-id                     = module.cluster.id
  service-discovery-namespace-id = aws_service_discovery_private_dns_namespace.main.id
  source                         = "../terraform-main/aws/modules/prometheus-ecs"
}

# "Sid":"Queue1_AllActions",
# "Effect": "Allow",
# "Principal": {
#    "AWS": "arn:aws:iam::<AccountA_ID>:role/cross-account-lambda-sqs-role",
# }      
# "Action": "sqs:*",
# "Resource": "arn:aws:sqs:us-east-1:<AccountB_ID>:LambdaCrossAccountQueue"
# {
#   "source": ["aws.s3"],
#   "detail-type": ["Object Created"],
#   "detail": {
#     "bucket": {
#       "name": ["BUCKET"]
#     }
#   }
# }

# "Sid": "AssumeRoleInSourceAccount",
# "Effect": "Allow",
# "Action": "sts:AssumeRole",
# "Resource": "arn:aws:iam::<AccountA_ID>:role/cross-account-kinesis-read-role"


# "Sid": "ReadInputStream",
# "Effect": "Allow",
# "Action": [
#     "kinesis:DescribeStream",
#     "kinesis:GetRecords",
#     "kinesis:GetShardIterator",
#     "kinesis:ListShards"
# ],
# "Resource": "arn:aws:kinesis:us-west-2:<AccountA_ID>:stream/SourceAccountExampleInputStream"