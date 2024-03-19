/*
*   Demo using MSK Connect with Debezium to replicate RDS data into MSK Serverless topics.
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
  source          = "../terraform-main/aws/modules/vpc"
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
  source         = "../terraform-main/aws/modules/internet-gateway"
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
  source         = "../terraform-main/aws/modules/nat-gateway"
}

module "msk-serverless" {
  region             = var.region
  account-id         = var.account-id
  app-shorthand-name = var.app-shorthand-name
  app-name           = var.app-name
  terraform-role     = var.terraform-role
  tags               = var.tags
  base-name          = local.base-name
  partition          = var.partition

  vpc-id = module.vpc.outputs.vpc-id
  source = "../terraform-main/aws/modules/msk-serverless"
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
  source          = "../terraform-main/aws/modules/rds-postgresql"
}

resource "aws_mskconnect_worker_configuration" "main" {
  name                    = local.base-name
  properties_file_content = <<EOT
key.converter=org.apache.kafka.connect.storage.StringConverter
value.converter=org.apache.kafka.connect.storage.StringConverter
EOT
}

resource "aws_s3_object" "main" {
  bucket = var.plugin-s3-bucket-name
  key    = "debezium-connector-postgres.zip"
  source = "debezium-connector-postgres.zip"
}

resource "aws_mskconnect_custom_plugin" "main" {
  name         = "${local.base-name}.debezium-postgresql"
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

resource "aws_mskconnect_connector" "main" {
  name = "${local.base-name}.debezium-postgresql"

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
      bootstrap_servers = module.msk-serverless.bootstrap_brokers_sasl_iam

      vpc {
        security_groups = [module.msk-serverless.security_group_id]
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

  service_execution_role_arn = module.msk-serverless.admin_iam_role_arn

  log_delivery {
    worker_log_delivery {
      cloudwatch_logs {
        enabled   = true
        log_group = "/msk/connect/debezium-connector"
      }
    }
  }

  worker_configuration {
    arn      = aws_mskconnect_worker_configuration.main.arn
    revision = aws_mskconnect_worker_configuration.main.latest_revision
  }
}
