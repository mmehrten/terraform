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

resource "aws_msk_vpc_connection" "iam" {
  authentication     = "SASL_IAM"
  target_cluster_arn = var.msk-cluster-arn
  vpc_id             = module.vpc.outputs.vpc-id
  client_subnets     = values(module.vpc.outputs.private-subnet-ids)
  security_groups    = [aws_security_group.main.id]
}

resource "aws_msk_vpc_connection" "scram" {
  authentication     = "SASL_SCRAM"
  target_cluster_arn = var.msk-cluster-arn
  vpc_id             = module.vpc.outputs.vpc-id
  client_subnets     = values(module.vpc.outputs.private-subnet-ids)
  security_groups    = [aws_security_group.main.id]
}

resource "aws_msk_vpc_connection" "tls" {
  authentication     = "TLS"
  target_cluster_arn = var.msk-cluster-arn
  vpc_id             = module.vpc.outputs.vpc-id
  client_subnets     = values(module.vpc.outputs.private-subnet-ids)
  security_groups    = [aws_security_group.main.id]
}

resource "aws_vpc_endpoint" "main" {
  for_each            = var.broker-endpoint-service-map
  service_name        = each.value.service_name
  subnet_ids          = [module.vpc.outputs.private-subnet-ids-by-az[each.key]]
  vpc_endpoint_type   = each.value.service_type
  vpc_id              = module.vpc.outputs.vpc-id
  private_dns_enabled = false
  security_group_ids  = [aws_security_group.main.id]
}

data "aws_network_interface" "interface_ips" {
  for_each = var.broker-endpoint-service-map
  id       = one(aws_vpc_endpoint.main[each.key].network_interface_ids)
}

resource "aws_route53_zone" "main" {
  name = var.broker-dns
  vpc {
    vpc_id = module.vpc.outputs.vpc-id
  }
  lifecycle { ignore_changes = [vpc] }
  tags = {
    "zone-service" : var.broker-dns
  }
}

resource "aws_route53_record" "main" {
  for_each                         = var.broker-endpoint-service-map
  zone_id                          = aws_route53_zone.main.zone_id
  name                             = each.value.broker
  type                             = "A"
  ttl                              = 300
  records                          = [data.aws_network_interface.interface_ips["${each.key}"].private_ip]
  multivalue_answer_routing_policy = true
  set_identifier                   = data.aws_network_interface.interface_ips["${each.key}"].availability_zone
}

module "rds" {
  region             = var.region
  account-id         = var.account-id
  app-shorthand-name = var.app-shorthand-name
  app-name           = var.app-name
  terraform-role     = var.terraform-role
  tags               = var.tags
  base-name          = local.base-name
  partition          = var.partition

  vpc-id          = module.vpc.outputs.vpc-id
  database-name   = "dev"
  master-password = var.rds-master-password
  instance-count  = 1
  source          = "../../terraform-main/aws/modules/rds-postgresql"
}

resource "aws_mskconnect_worker_configuration" "main" {
  name                    = replace(local.base-name, ".", "-")
  properties_file_content = <<EOT
    key.converter=org.apache.kafka.connect.storage.StringConverter
    value.converter=org.apache.kafka.connect.storage.StringConverter
  EOT
  # config.providers.secretManager.class=com.github.jcustenborder.kafka.config.aws.SecretsManagerConfigProvider
  # config.providers=secretManager
  # config.providers.secretManager.param.aws.region=${var.region}
}

resource "aws_s3_object" "main" {
  bucket = var.plugin-s3-bucket-name
  key    = "debezium-connector-postgres.zip"
  source = "debezium-connector-postgres.zip"
}

resource "aws_mskconnect_custom_plugin" "main" {
  name         = replace("${local.base-name}.debezium-postgresql", ".", "-")
  content_type = "ZIP"
  location {
    s3 {
      bucket_arn = "arn:${var.partition}:s3:::${var.plugin-s3-bucket-name}"
      file_key   = aws_s3_object.main.key
    }
  }
}

resource "aws_cloudwatch_log_group" "main" {
  name = "/msk/connect/${local.base-name}-debezium-connector"
}

resource "aws_security_group" "main" {
  name        = "${local.base-name}.sg.msk"
  description = "Security group for msk clusters."
  vpc_id      = module.vpc.outputs.vpc-id

  ingress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }
  tags = {
    Name = "${local.base-name}.sg.msk-connect"
  }
}

resource "aws_iam_role_policy" "main" {
  name = "${var.app-shorthand-name}.iam.role.msk.admin"
  role = aws_iam_role.main.id
  policy = jsonencode(
    {
      "Version" : "2012-10-17",
      "Statement" : [
        {
          "Effect" : "Allow",
          "Action" : [
            "kafka-cluster:Connect",
            "kafka-cluster:AlterCluster",
            "kafka-cluster:DescribeCluster",
            "kafka-cluster:DescribeClusterDynamicConfiguration",
            "kafka-cluster:AlterClusterDynamicConfiguration",
            "kafka-cluster:WriteDataIdempotently",
          ],
          "Resource" : "arn:${var.partition}:kafka:${var.region}:*:cluster/${var.cluster-name}/*"
        },
        {
          "Effect" : "Allow",
          "Action" : [
            "kafka-cluster:CreateTopic",
            "kafka-cluster:DescribeTopic",
            "kafka-cluster:AlterTopic",
            "kafka-cluster:DeleteTopic",
            "kafka-cluster:DescribeTopicDynamicConfiguration",
            "kafka-cluster:AlterTopicDynamicConfiguration",
            "kafka-cluster:WriteData",
            "kafka-cluster:ReadData"
          ],
          "Resource" : "arn:${var.partition}:kafka:${var.region}:*:topic/${var.cluster-name}/*"
        },
        {
          "Effect" : "Allow",
          "Action" : [
            "kafka-cluster:AlterGroup",
            "kafka-cluster:DeleteGroup",
            "kafka-cluster:DescribeGroup"
          ],
          "Resource" : "arn:${var.partition}:kafka:${var.region}:*:group/${var.cluster-name}/*"
        },
        {
          "Effect" : "Allow",
          "Action" : [
            "kafka-cluster:DescribeTransactionalId",
            "kafka-cluster:AlterTransactionalId",
          ],
          "Resource" : "arn:${var.partition}:kafka:${var.region}:*:transactional-id/${var.cluster-name}/*"
        },
        {
          "Effect" : "Allow",
          "Action" : [
            "logs:CreateLogGroup",
            "logs:CreateLogStream",
            "logs:DescribeLogStreams",
            "logs:PutLogEvents",
            "logs:GetLogEvents"
          ],
          "Resource" : [
            "arn:${var.partition}:logs:${var.region}:${var.account-id}:log-group:*",
            "arn:${var.partition}:logs:${var.region}:${var.account-id}:log-group:*:*",
            "arn:${var.partition}:logs:${var.region}:${var.account-id}:log-stream:*",
            "arn:${var.partition}:logs:${var.region}:${var.account-id}:log-stream:*:*",
          ]
        }
      ]
    }
  )
}

resource "aws_iam_role" "main" {
  name = "${var.app-shorthand-name}.iam.role.msk.admin"
  assume_role_policy = jsonencode(
    {
      "Version" : "2012-10-17",
      "Statement" : [
        {
          "Action" : "sts:AssumeRole",
          "Principal" : {
            "Service" : ["lambda.amazonaws.com", "kafkaconnect.amazonaws.com"]
          },
          "Effect" : "Allow"
        }
      ]
    }
  )
}

resource "aws_mskconnect_connector" "main" {
  name = replace("${local.base-name}.debezium-postgresql", ".", "-")

  kafkaconnect_version = "2.7.1"

  capacity {
    provisioned_capacity {
      mcu_count    = 1
      worker_count = 1
    }
  }

  connector_configuration = {
    "connector.class"   = "io.debezium.connector.postgresql.PostgresConnector"
    "tasks.max"         = "1"
    "database.hostname" = module.rds.endpoint
    "database.port"     = "5432"
    "database.user"     = "dev"
    "database.password" = var.rds-master-password
    "database.dbname"   = "dev"
    "topic.prefix"      = "demo"
  }

  kafka_cluster {
    apache_kafka_cluster {
      bootstrap_servers = join(
        ",",
        [for k, v in aws_route53_record.main : "${v.fqdn}:9098"]
      )
      vpc {
        security_groups = [aws_security_group.main.id]
        subnets         = values(module.vpc.outputs.private-subnet-ids)
      }
    }
  }

  kafka_cluster_client_authentication {
    authentication_type = "IAM"
  }

  kafka_cluster_encryption_in_transit {
    encryption_type = "TLS"
  }

  plugin {
    custom_plugin {
      arn      = aws_mskconnect_custom_plugin.main.arn
      revision = aws_mskconnect_custom_plugin.main.latest_revision
    }
  }

  service_execution_role_arn = aws_iam_role.main.arn

  log_delivery {
    worker_log_delivery {
      cloudwatch_logs {
        enabled   = true
        log_group = aws_cloudwatch_log_group.main.name
      }
    }
  }

  worker_configuration {
    arn      = aws_mskconnect_worker_configuration.main.arn
    revision = aws_mskconnect_worker_configuration.main.latest_revision
  }
}

