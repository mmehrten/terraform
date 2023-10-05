/*
*   Create hub VPC with VPC endpoints and an internet gateway, to be used as a transit hub for other VPCs.
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
  partition = var.partition

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
  partition = var.partition

  vpc-id         = module.vpc.outputs.vpc-id
  subnet-id      = values(module.vpc.outputs.public-subnet-ids)[0]
  route-table-id = module.vpc.outputs.private-route-table-id
  source         = "../terraform-main/aws/modules/nat-gateway"
}

module "redshift" {
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
  master-password = var.redshift-master-password
  source          = "../terraform-main/aws/modules/redshift"
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

  vpc-id          = module.vpc.outputs.vpc-id
  source          = "../terraform-main/aws/modules/msk"
}

resource "aws_glue_registry" "main" {
  registry_name = "${local.base-name}.glue.registry"
}

resource "aws_glue_schema" "main" {
  schema_name       = "demo"
  registry_arn      = aws_glue_registry.main.arn
  data_format       = "AVRO"
  compatibility     = "BACKWARD_ALL"
  schema_definition = jsonencode({"type": "record", "name": "User", "namespace": "example.avro", "fields": [{"type": "string", "name": "name"}, {"type": ["int", "null"], "name": "favorite_number"}, {"type": ["string", "null"], "name": "favorite_color"}]})
}

module "avro-decode-lambda" {
  region             = var.region
  account-id         = var.account-id
  app-shorthand-name = var.app-shorthand-name
  app-name           = var.app-name
  terraform-role     = var.terraform-role
  tags               = var.tags
  base-name          = local.base-name
  partition          = var.partition

  policy = jsonencode(
    {
      "Version" : "2012-10-17",
      "Statement" : [
        {
          "Effect" : "Allow",
          "Action" : "glue:*",
          "Resource" : "*"
        }
      ]
  })
  name               = "rs-avro-decode"
  file-path          = "./redshift_avro_decode.py"
  handler            = "redshift_avro_decode.handler"
  runtime            = "python3.9"
  vpc-id = module.vpc.outputs.vpc-id
  subnet-ids         = values(module.vpc.outputs.private-subnet-ids)
  layer_arns = ["arn:aws-us-gov:lambda:us-gov-west-1:053633994311:layer:avro:1"]
  source             = "../terraform-main/aws/modules/lambda"
}

module "kafka-publisher-lambda" {
  region             = var.region
  account-id         = var.account-id
  app-shorthand-name = var.app-shorthand-name
  app-name           = var.app-name
  terraform-role     = var.terraform-role
  tags               = var.tags
  base-name          = local.base-name
  partition          = var.partition

  name               = "msk-publisher"
  policy = jsonencode(
    {
      "Version" : "2012-10-17",
      "Statement" : [
        {
          "Effect" : "Allow",
          "Action" : "glue:*",
          "Resource" : "*"
        }
      ]
  })
  file-path          = "./kafka_publisher.py"
  handler            = "kafka_publisher.handler"
  runtime            = "python3.9"
  vpc-id = module.vpc.outputs.vpc-id
  subnet-ids         = values(module.vpc.outputs.private-subnet-ids)
  layer_arns = [
    "arn:aws-us-gov:lambda:us-gov-west-1:053633994311:layer:avro:1",
    "arn:aws-us-gov:lambda:us-gov-west-1:053633994311:layer:kafka-python:1"
  ]
  environment = {
    BROKER_STRING = module.msk.bootstrap_brokers
  }
  source             = "../terraform-main/aws/modules/lambda"
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

  expiration-days = 7
  bucket-name = "${local.base-name}.s3.msk"
  versioning  = false
  source      = "../terraform-main/aws/modules/s3"
}

module "kafka-consumer-lambda" {
  region             = var.region
  account-id         = var.account-id
  app-shorthand-name = var.app-shorthand-name
  app-name           = var.app-name
  terraform-role     = var.terraform-role
  tags               = var.tags
  base-name          = local.base-name
  partition          = var.partition

  name               = "msk-consumer"
  policy = jsonencode(
    {
      "Version" : "2012-10-17",
      "Statement" : [
        {
          "Effect" : "Allow",
          "Action" : "glue:*",
          "Resource" : "*"
        },
        {
          "Effect" : "Allow",
          "Action" : "s3:*",
          "Resource" : "*"
        },
        {
          "Effect" : "Allow",
          "Action" : "redshift-data:*",
          "Resource" : "*"
        },
        {
          "Effect" : "Allow",
          "Action" : "redshift:*",
          "Resource" : "*"
        },
        {
          "Effect" : "Allow",
          "Action" : "kms:*",
          "Resource" : "*"
        },
        {
          "Effect" : "Allow",
          "Action" : "kafka:*",
          "Resource" : "*"
        },
        {
          "Effect" : "Allow",
          "Action" : "kafka-cluster:*",
          "Resource" : "*"
        }
      ]
  })
  file-path          = "./msk_to_s3_consumer.py"
  handler            = "msk_to_s3_consumer.handler"
  runtime            = "python3.9"
  vpc-id = module.vpc.outputs.vpc-id
  subnet-ids         = values(module.vpc.outputs.private-subnet-ids)
  source             = "../terraform-main/aws/modules/lambda"
  layer_arns = ["arn:aws-us-gov:lambda:us-gov-west-1:053633994311:layer:avro:1"]
  environment = {
    REGISTRY_NAME = aws_glue_registry.main.registry_name,
    BUCKET_NAME = module.s3-data.outputs.name
    CLUSTER_NAME = module.redshift.cluster_identifier
    DATABASE_NAME = "dev"
    USER_NAME = module.redshift.master_username
    REGION = var.region
    REDSHIFT_IAM_ROLE = module.redshift.iam_role_arn
  }
}

resource "aws_lambda_event_source_mapping" "consumer" {
  event_source_arn  = module.msk.cluster_arn
  function_name     = module.kafka-consumer-lambda.lambda_arn
  topics            = ["demo"]
  starting_position = "TRIM_HORIZON"
  enabled = true
}

resource "aws_cloudwatch_event_rule" "publish" {
  name                = "msk-publisher"
  schedule_expression = "rate(5 minutes)"
}

resource "aws_cloudwatch_event_target" "lambda" {
  rule      = aws_cloudwatch_event_rule.publish.name
  target_id = aws_cloudwatch_event_rule.publish.name
  arn       = module.kafka-publisher-lambda.lambda_arn
  input = jsonencode({
    arguments = [
      [aws_glue_registry.main.registry_name, "demo", jsonencode({favorite_color = "black", favorite_number = 1, name = "Mazrim"})],
      [aws_glue_registry.main.registry_name, "demo", jsonencode({favorite_color = "blue", favorite_number = 1, name = "Moiraine"})]
    ]
  })
}

resource "aws_lambda_permission" "allow_eventbridge" {
  statement_id  = "AllowExecutionFromEventBridge"
  action        = "lambda:InvokeFunction"
  function_name = module.kafka-publisher-lambda.lambda_arn
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.publish.arn
}


resource "aws_redshiftdata_statement" "create-udf" {
  cluster_identifier = module.redshift.cluster_identifier
  database           = "dev"
  db_user            = module.redshift.master_username
  sql                = <<EOF
    CREATE OR REPLACE EXTERNAL FUNCTION f_glue_schema_registry_avro_to_json (varchar, varchar, varchar) 
    RETURNS varchar 
    IMMUTABLE
    LAMBDA '${module.avro-decode-lambda.lambda_name}' 
    IAM_ROLE '${module.redshift.iam_role_arn}';
  EOF
  lifecycle {
    ignore_changes = [sql]
  }
}

resource "aws_redshiftdata_statement" "create-external" {
  cluster_identifier = module.redshift.cluster_identifier
  database           = "dev"
  db_user            = module.redshift.master_username
  sql                = <<EOF
    CREATE EXTERNAL SCHEMA IF NOT EXISTS msk 
    FROM MSK 
    IAM_ROLE '${module.redshift.iam_role_arn}'
    AUTHENTICATION iam
    CLUSTER_ARN '${module.msk.cluster_arn}';
EOF
  lifecycle {
    ignore_changes = [sql]
  }
}

resource "aws_redshiftdata_statement" "create-mv" {
  depends_on = [ aws_redshiftdata_statement.create-external ]
  cluster_identifier = module.redshift.cluster_identifier
  database           = "dev"
  db_user            = module.redshift.master_username
  sql                = <<EOF
    CREATE MATERIALIZED VIEW msk_demo_topic_decoded AUTO REFRESH YES AS
    SELECT
      t.kafka_offset,
      t.kafka_timestamp_type,
      t.kafka_timestamp,
      t.kafka_key,
      t.kafka_value,
      t.kafka_headers,
      t.kafka_partition,
      t.refresh_time,
      t.kafka_value AS binary_avro,
      to_hex(binary_avro) AS hex_avro,
      f_glue_schema_registry_avro_to_json('${aws_glue_registry.main.registry_name}', 'demo', hex_avro) AS json_string,
      JSON_PARSE(json_string) AS super_data
    FROM msk.demo AS t;
  EOF
}

