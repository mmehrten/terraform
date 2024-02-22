/*
*   Create an MSK cluster with Redshift cluster, and streaming ingestion with Avro and Glue Schema Registry using a NAT gateway or a Lambda function.
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
data "aws_subnets" "public" {
  filter {
    name   = "vpc-id"
    values = [var.vpc-id]
  }
  filter {
    name   = "tag:Name"
    values = ["*public*"]
  }
}
data "aws_route_table" "private" {
  filter {
    name   = "vpc-id"
    values = [var.vpc-id]
  }
  filter {
    name   = "tag:Name"
    values = ["*private*"]
  }
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

  vpc-id         = var.vpc-id
  subnet-id      = data.aws_subnets.public.ids[0]
  route-table-id = data.aws_route_table.private.route_table_id
  source         = "../terraform-main/aws/modules/nat-gateway"
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


resource "aws_iam_policy" "ecs_task_custom_policy" {
  name = "${var.app-shorthand-name}.ecs.ecs-task-custom-policy"
  path = "/"

  policy = jsonencode(
    {
      "Version" : "2012-10-17",
      "Statement" : [
        {
          "Sid" : "AllowReadingTagsInstancesRegionsFromEC2",
          "Effect" : "Allow",
          "Action" : ["ec2:DescribeTags", "ec2:DescribeInstances", "ec2:DescribeRegions"],
          "Resource" : "*"
        },
        {
          "Sid" : "AllowReadingResourcesForTags",
          "Effect" : "Allow",
          "Action" : "tag:GetResources",
          "Resource" : "*"
        },
        {
          "Sid" : "AllowExecuteCommand",
          "Effect" : "Allow",
          "Action" : [
            "ssmmessages:CreateControlChannel",
            "ssmmessages:CreateDataChannel",
            "ssmmessages:OpenControlChannel",
            "ssmmessages:OpenDataChannel"
          ],
          "Resource" : "*"
        }
      ]
    }
  )
}
data "aws_iam_policy_document" "ecs_task" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ecs-tasks.amazonaws.com"]
    }
  }
}
resource "aws_iam_role" "ecs_task_execution_role" {
  name               = "${var.app-shorthand-name}.ecs.task-execution-role"
  assume_role_policy = data.aws_iam_policy_document.ecs_task.json
}
resource "aws_iam_role" "ecs_task_role" {
  name               = "${var.app-shorthand-name}.ecs.task-role"
  assume_role_policy = data.aws_iam_policy_document.ecs_task.json
}
resource "aws_iam_role_policy_attachment" "task_custom" {
  role       = aws_iam_role.ecs_task_role.name
  policy_arn = aws_iam_policy.ecs_task_custom_policy.arn
}
resource "aws_iam_role_policy_attachment" "task_ssm_ro" {
  role       = aws_iam_role.ecs_task_role.name
  policy_arn = "arn:${var.partition}:iam::aws:policy/AmazonSSMReadOnlyAccess"
}
resource "aws_iam_role_policy_attachment" "task_execution_ecr" {
  role       = aws_iam_role.ecs_task_execution_role.name
  policy_arn = "arn:${var.partition}:iam::aws:policy/AmazonEC2ContainerRegistryPowerUser"
}
resource "aws_iam_role_policy_attachment" "task_execution_cloudwatch" {
  role       = aws_iam_role.ecs_task_execution_role.name
  policy_arn = "arn:${var.partition}:iam::aws:policy/CloudWatchFullAccess"
}
resource "aws_iam_role_policy" "task_msk" {
  name = "${var.app-shorthand-name}.iam.ecs-msk-admin"
  role = aws_iam_role.ecs_task_role.id
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
          "Resource" : "arn:${var.partition}:kafka:${var.region}:${var.account-id}:cluster/${module.msk.cluster_name}/*"
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
          "Resource" : "arn:${var.partition}:kafka:${var.region}:${var.account-id}:topic/${module.msk.cluster_name}/*"
        },
        {
          "Effect" : "Allow",
          "Action" : [
            "kafka-cluster:AlterGroup",
            "kafka-cluster:DeleteGroup",
            "kafka-cluster:DescribeGroup"
          ],
          "Resource" : "arn:${var.partition}:kafka:${var.region}:${var.account-id}:group/${module.msk.cluster_name}/*"
        },
        {
          "Effect" : "Allow",
          "Action" : [
            "kafka-cluster:DescribeTransactionalId",
            "kafka-cluster:AlterTransactionalId",
          ],
          "Resource" : "arn:${var.partition}:kafka:${var.region}:${var.account-id}:transactional-id/${module.msk.cluster_name}/*"
        }
      ]
    }
  )
}


resource "aws_service_discovery_private_dns_namespace" "main" {
  name        = "${local.base-name}.local"
  description = "${local.base-name} service discovery"
  vpc         = var.vpc-id
}
resource "aws_security_group" "ecs" {
  name        = "${local.base-name}.sg.ecs"
  description = "ECS"
  vpc_id      = var.vpc-id

  ingress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }
  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }
}

resource "aws_ecr_repository" "kafka-connect" {
  name                 = "kafka-connect"
  image_tag_mutability = "IMMUTABLE"
  force_delete         = true

  image_scanning_configuration {
    scan_on_push = true
  }
  encryption_configuration {
    encryption_type = "AES256"
  }
}
resource "aws_cloudwatch_log_group" "kafka-connect" {
  name              = "/ecs/kafka-connect"
  retention_in_days = 5
}
resource "aws_ecs_task_definition" "kafka-connect" {
  family                   = "kafka-connect"
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = "1024"
  memory                   = "4096"
  task_role_arn            = aws_iam_role.ecs_task_role.arn
  execution_role_arn       = aws_iam_role.ecs_task_execution_role.arn
  runtime_platform {
    cpu_architecture        = "X86_64"
    operating_system_family = "LINUX"
  }

  container_definitions = jsonencode(
    [
      {
        "name" : "kafka-connect",
        "image" : "${aws_ecr_repository.kafka-connect.repository_url}:latest",
        "cpu" : 0,
        "portMappings" : [
          {
            "name" : "kafka-connect-8083-tcp",
            "containerPort" : 8083,
            "hostPort" : 8083,
            "protocol" : "tcp",
            "appProtocol" : "http"
          },
          {
            "name" : "kafka-connect-3600-tcp",
            "containerPort" : 3600,
            "hostPort" : 3600,
            "protocol" : "tcp",
            "appProtocol" : "http"
          }
        ],
        "essential" : true,
        "environment" : [
          {
            "name" : "GROUP",
            "value" : "kafka-connect-fargate"
          },
          {
            "name" : "BROKERS",
            "value" : module.msk.bootstrap_brokers_sasl_iam,
          }
        ],
        "mountPoints" : [],
        "volumesFrom" : [],
        "dockerLabels" : {
          "PROMETHEUS_EXPORTER_JOB_NAME" : "kafka-connect",
          "PROMETHEUS_EXPORTER_PORT" : "3600"
        },
        "logConfiguration" : {
          "logDriver" : "awslogs",
          "options" : {
            "awslogs-create-group" : "true",
            "awslogs-group" : "/ecs/kafka-connect",
            "awslogs-region" : var.region,
            "awslogs-stream-prefix" : "ecs"
          }
        }
      }
    ]
  )
}
resource "aws_service_discovery_service" "kafka-connect" {
  name = "kafka-connect"

  dns_config {
    namespace_id = aws_service_discovery_private_dns_namespace.main.id

    dns_records {
      ttl  = 10
      type = "A"
    }

    routing_policy = "MULTIVALUE"
  }

  health_check_custom_config {
    failure_threshold = 1
  }
}
resource "aws_ecs_service" "kafka-connect" {
  name            = replace("${local.base-name}.ecs.service.kafka-connect", ".", "_")
  cluster         = module.cluster.id
  task_definition = aws_ecs_task_definition.kafka-connect.arn
  desired_count   = 1
  network_configuration {
    subnets          = data.aws_subnets.private.ids
    security_groups  = [aws_security_group.ecs.id]
    assign_public_ip = false
  }
  service_registries {
    registry_arn = aws_service_discovery_service.kafka-connect.arn
  }
  launch_type            = "FARGATE"
  enable_execute_command = true
}

resource "aws_ecr_repository" "prometheus" {
  name                 = "prometheus"
  image_tag_mutability = "IMMUTABLE"
  force_delete         = true

  image_scanning_configuration {
    scan_on_push = true
  }
  encryption_configuration {
    encryption_type = "AES256"
  }
}
resource "aws_cloudwatch_log_group" "prometheus" {
  name              = "/ecs/prometheus"
  retention_in_days = 5
}
resource "aws_ecs_task_definition" "prometheus" {
  family                   = "prometheus"
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = "2048"
  memory                   = "4096"
  task_role_arn            = aws_iam_role.ecs_task_role.arn
  execution_role_arn       = aws_iam_role.ecs_task_execution_role.arn
  volume {
    name = "config"
  }
  ephemeral_storage {
    size_in_gib = 100
  }
  runtime_platform {
    cpu_architecture        = "X86_64"
    operating_system_family = "LINUX"
  }

  container_definitions = jsonencode(
    [
      {
        "name" : "prometheus",
        "image" : "${aws_ecr_repository.prometheus.repository_url}:latest",
        "cpu" : 0,
        "portMappings" : [
          {
            "name" : "prometheus-9090-tcp",
            "containerPort" : 9090,
            "hostPort" : 9090,
            "protocol" : "tcp",
            "appProtocol" : "http"
          }
        ],
        "essential" : true,
        "environment" : [],
        "mountPoints" : [
          {
            "sourceVolume" : "config",
            "containerPath" : "/output",
            "readOnly" : false
          }
        ],
        "volumesFrom" : [],
        "logConfiguration" : {
          "logDriver" : "awslogs",
          "options" : {
            "awslogs-create-group" : "true",
            "awslogs-group" : "/ecs/prometheus",
            "awslogs-region" : var.region,
            "awslogs-stream-prefix" : "ecs-prometheus"
          }
        }
      },
      {
        "name" : "discovery",
        "image" : "tkgregory/prometheus-ecs-discovery",
        "cpu" : 0,
        "portMappings" : [],
        "essential" : false,
        "command" : [
          "-config.write-to=/output/ecs_file_sd.yml"
        ],
        "environment" : [
          {
            "name" : "JMX_EXPORTER_BROKER_LIST",
            "value" : ""
          },
          {
            "name" : "NODE_EXPORTER_BROKER_LIST",
            "value" : ""
          }
        ],
        "mountPoints" : [
          {
            "sourceVolume" : "config",
            "containerPath" : "/output",
            "readOnly" : false
          }
        ],
        "volumesFrom" : [],
        "logConfiguration" : {
          "logDriver" : "awslogs",
          "options" : {
            "awslogs-create-group" : "true",
            "awslogs-group" : "/ecs/prometheus",
            "awslogs-region" : var.region,
            "awslogs-stream-prefix" : "ecs-discovery"
          }
        }
      }
    ]
  )
}
resource "aws_service_discovery_service" "prometheus" {
  name = "prometheus"

  dns_config {
    namespace_id = aws_service_discovery_private_dns_namespace.main.id

    dns_records {
      ttl  = 10
      type = "A"
    }

    routing_policy = "MULTIVALUE"
  }

  health_check_custom_config {
    failure_threshold = 1
  }
}
resource "aws_ecs_service" "prometheus" {
  name            = replace("${local.base-name}.ecs.service.prometheus", ".", "_")
  cluster         = module.cluster.id
  task_definition = aws_ecs_task_definition.prometheus.arn
  desired_count   = 1
  network_configuration {
    subnets          = data.aws_subnets.private.ids
    security_groups  = [aws_security_group.ecs.id]
    assign_public_ip = false
  }
  service_registries {
    registry_arn = aws_service_discovery_service.prometheus.arn
  }
  launch_type            = "FARGATE"
  enable_execute_command = true
}

resource "aws_cloudwatch_log_group" "grafana" {
  name              = "/ecs/grafana"
  retention_in_days = 5
}
resource "aws_ecs_task_definition" "grafana" {
  family                   = "grafana"
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = "1024"
  memory                   = "3072"
  task_role_arn            = aws_iam_role.ecs_task_role.arn
  execution_role_arn       = aws_iam_role.ecs_task_execution_role.arn
  runtime_platform {
    cpu_architecture        = "X86_64"
    operating_system_family = "LINUX"
  }

  container_definitions = jsonencode(
    [
      {
        "name" : "grafana",
        "image" : "grafana/grafana",
        "cpu" : 0,
        "portMappings" : [
          {
            "name" : "grafana-3000-tcp",
            "containerPort" : 3000,
            "hostPort" : 3000,
            "protocol" : "tcp",
            "appProtocol" : "http"
          }
        ],
        "essential" : true,
        "environment" : [
          {
            "name" : "GF_INSTALL_PLUGINS",
            "value" : "grafana-clock-panel"
          }
        ],
        "environmentFiles" : [],
        "mountPoints" : [],
        "volumesFrom" : [],
        "ulimits" : [],
        "logConfiguration" : {
          "logDriver" : "awslogs",
          "options" : {
            "awslogs-create-group" : "true",
            "awslogs-group" : "/ecs/grafana",
            "awslogs-region" : var.region,
            "awslogs-stream-prefix" : "ecs"
          }
        }
      }
    ]
  )
}
resource "aws_service_discovery_service" "grafana" {
  name = "grafana"

  dns_config {
    namespace_id = aws_service_discovery_private_dns_namespace.main.id

    dns_records {
      ttl  = 10
      type = "A"
    }

    routing_policy = "MULTIVALUE"
  }

  health_check_custom_config {
    failure_threshold = 1
  }
}
resource "aws_ecs_service" "grafana" {
  name            = replace("${local.base-name}.ecs.service.grafana", ".", "_")
  cluster         = module.cluster.id
  task_definition = aws_ecs_task_definition.grafana.arn
  desired_count   = 1
  network_configuration {
    subnets          = data.aws_subnets.private.ids
    security_groups  = [aws_security_group.ecs.id]
    assign_public_ip = false
  }
  service_registries {
    registry_arn = aws_service_discovery_service.grafana.arn
  }
  launch_type            = "FARGATE"
  enable_execute_command = true
}


resource "aws_s3_bucket" "main" {
  bucket        = "${local.base-name}.configs"
  force_destroy = true
}
resource "aws_s3_bucket_versioning" "main-versioning" {
  bucket = aws_s3_bucket.main.bucket
  versioning_configuration {
    status = "Enabled"
  }
}
resource "aws_s3_bucket_server_side_encryption_configuration" "main-encryption" {
  bucket = aws_s3_bucket.main.bucket
  rule {
    bucket_key_enabled = true
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}
resource "aws_s3_bucket_public_access_block" "main-block" {
  bucket                  = aws_s3_bucket.main.bucket
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}
resource "aws_s3_object" "connector-cpc" {
  bucket = aws_s3_bucket.main.bucket
  key    = "connector/mm2-cpc-iam-auth.json"
  content = jsonencode({
    "name" : "mm2-cpc",
    "connector.class" : "org.apache.kafka.connect.mirror.MirrorCheckpointConnector",
    "clusters" : "msksource,mskdest",
    "source.cluster.alias" : "msksource",
    "target.cluster.alias" : "mskdest",
    "target.cluster.bootstrap.servers" : "{TARGET CLUSTER BROKERS ADDRESS}",
    "source.cluster.bootstrap.servers" : "${module.msk.bootstrap_brokers_sasl_iam}",
    "tasks.max" : "1",
    "key.converter" : " org.apache.kafka.connect.converters.ByteArrayConverter",
    "value.converter" : "org.apache.kafka.connect.converters.ByteArrayConverter",
    "replication.policy.class" : "com.amazonaws.kafka.samples.CustomMM2ReplicationPolicy",
    "replication.factor" : "3",
    "checkpoints.topic.replication.factor" : "3",
    "emit.checkpoints.interval.seconds" : "20",
    "sync.group.offsets.enabled" : "true",
    "source.cluster.security.protocol" : "SASL_SSL",
    "source.cluster.sasl.mechanism" : "AWS_MSK_IAM",
    "source.cluster.sasl.jaas.config" : "software.amazon.msk.auth.iam.IAMLoginModule required;",
    "source.cluster.sasl.client.callback.handler.class" : "software.amazon.msk.auth.iam.IAMClientCallbackHandler",
    "target.cluster.security.protocol" : "SASL_SSL",
    "target.cluster.sasl.mechanism" : "AWS_MSK_IAM",
    "target.cluster.sasl.jaas.config" : "software.amazon.msk.auth.iam.IAMLoginModule required;",
    "target.cluster.sasl.client.callback.handler.class" : "software.amazon.msk.auth.iam.IAMClientCallbackHandler"
  })
}
resource "aws_s3_object" "connector-hbc" {
  bucket = aws_s3_bucket.main.bucket
  key    = "connector/mm2-hbc-iam-auth.json"
  content = jsonencode({
    "name" : "mm2-hbc",
    "connector.class" : "org.apache.kafka.connect.mirror.MirrorHeartbeatConnector",
    "clusters" : "msksource,mskdest",
    "source.cluster.alias" : "msksource",
    "target.cluster.alias" : "mskdest",
    "target.cluster.bootstrap.servers" : "{TARGET CLUSTER BROKERS ADDRESS}",
    "source.cluster.bootstrap.servers" : "${module.msk.bootstrap_brokers_sasl_iam}",
    "tasks.max" : "1",
    "key.converter" : " org.apache.kafka.connect.converters.ByteArrayConverter",
    "value.converter" : "org.apache.kafka.connect.converters.ByteArrayConverter",
    "replication.factor" : "3",
    "heartbeats.topic.replication.factor" : "3",
    "emit.heartbeats.interval.seconds" : "20",
    "source.cluster.security.protocol" : "SASL_SSL",
    "source.cluster.sasl.mechanism" : "AWS_MSK_IAM",
    "source.cluster.sasl.jaas.config" : "software.amazon.msk.auth.iam.IAMLoginModule required;",
    "source.cluster.sasl.client.callback.handler.class" : "software.amazon.msk.auth.iam.IAMClientCallbackHandler",
    "target.cluster.security.protocol" : "SASL_SSL",
    "target.cluster.sasl.mechanism" : "AWS_MSK_IAM",
    "target.cluster.sasl.jaas.config" : "software.amazon.msk.auth.iam.IAMLoginModule required;",
    "target.cluster.sasl.client.callback.handler.class" : "software.amazon.msk.auth.iam.IAMClientCallbackHandler"
  })
}
resource "aws_s3_object" "connector-msc" {
  bucket = aws_s3_bucket.main.bucket
  key    = "connector/mm2-msc-iam-auth.json"
  content = jsonencode({
    "name" : "mm2-msc",
    "connector.class" : "org.apache.kafka.connect.mirror.MirrorSourceConnector",
    "clusters" : "msksource,mskdest",
    "source.cluster.alias" : "msksource",
    "target.cluster.alias" : "mskdest",
    "target.cluster.bootstrap.servers" : "{TARGET CLUSTER BROKERS ADDRESS}",
    "source.cluster.bootstrap.servers" : "${module.msk.bootstrap_brokers_sasl_iam}",
    "topics" : "^ExampleTopic[\\w]*",
    "tasks.max" : "4",
    "key.converter" : " org.apache.kafka.connect.converters.ByteArrayConverter",
    "value.converter" : "org.apache.kafka.connect.converters.ByteArrayConverter",
    "replication.factor" : "3",
    "offset-syncs.topic.replication.factor" : "3",
    "sync.topic.acls.interval.seconds" : "20",
    "sync.topic.configs.interval.seconds" : "20",
    "refresh.topics.interval.seconds" : "20",
    "refresh.groups.interval.seconds" : "20",
    "producer.enable.idempotence" : "true",
    "consumer.group.id" : "mm2-msc",
    "source.cluster.max.poll.records" : "50000",
    "source.cluster.receive.buffer.bytes" : "33554432",
    "source.cluster.send.buffer.bytes" : "33554432",
    "source.cluster.max.partition.fetch.bytes" : "33554432",
    "source.cluster.message.max.bytes" : "37755000",
    "source.cluster.compression.type" : "gzip",
    "source.cluster.max.request.size" : "26214400",
    "source.cluster.buffer.memory" : "524288000",
    "source.cluster.batch.size" : "524288",
    "target.cluster.max.poll.records" : "20000",
    "target.cluster.receive.buffer.bytes" : "33554432",
    "target.cluster.send.buffer.bytes" : "33554432",
    "target.cluster.max.partition.fetch.bytes" : "33554432",
    "target.cluster.message.max.bytes" : "37755000",
    "target.cluster.compression.type" : "gzip",
    "target.cluster.max.request.size" : "26214400",
    "target.cluster.buffer.memory" : "524288000",
    "target.cluster.batch.size" : "52428",
    "source.cluster.security.protocol" : "SASL_SSL",
    "source.cluster.sasl.mechanism" : "AWS_MSK_IAM",
    "source.cluster.sasl.jaas.config" : "software.amazon.msk.auth.iam.IAMLoginModule required;",
    "source.cluster.sasl.client.callback.handler.class" : "software.amazon.msk.auth.iam.IAMClientCallbackHandler",
    "target.cluster.security.protocol" : "SASL_SSL",
    "target.cluster.sasl.mechanism" : "AWS_MSK_IAM",
    "target.cluster.sasl.jaas.config" : "software.amazon.msk.auth.iam.IAMLoginModule required;",
    "target.cluster.sasl.client.callback.handler.class" : "software.amazon.msk.auth.iam.IAMClientCallbackHandler"
  })
}
resource "aws_s3_object" "worker" {
  bucket  = aws_s3_bucket.main.bucket
  key     = "worker/connect-distributed.properties"
  content = <<EOF
bootstrap.servers=${module.msk.bootstrap_brokers_sasl_iam}
group.id=mm2-worker
key.converter=org.apache.kafka.connect.json.JsonConverter
value.converter=org.apache.kafka.connect.json.JsonConverter
key.converter.schemas.enable=true
value.converter.schemas.enable=true
offset.storage.topic=connect-offsets-mm2-worker
offset.storage.replication.factor=3
config.storage.topic=connect-configs-mm2-worker
config.storage.replication.factor=3
status.storage.topic=connect-status-mm2-worker
status.storage.replication.factor=3
offset.flush.interval.ms=10000
connector.client.config.override.policy=All
security.protocol=SASL_SSL
sasl.mechanism = AWS_MSK_IAM
sasl.jaas.config = software.amazon.msk.auth.iam.IAMLoginModule required;
sasl.client.callback.handler.class = software.amazon.msk.auth.iam.IAMClientCallbackHandler
producer.security.protocol=SASL_SSL
producer.sasl.mechanism = AWS_MSK_IAM
producer.sasl.jaas.config = software.amazon.msk.auth.iam.IAMLoginModule required;
producer.sasl.client.callback.handler.class = software.amazon.msk.auth.iam.IAMClientCallbackHandler
EOF
}
