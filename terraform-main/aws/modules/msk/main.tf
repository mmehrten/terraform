/*
* Create a msk culster.
*/

resource "aws_security_group" "main" {
  name        = "${var.base-name}.sg.msk"
  description = "Security group for msk clusters."
  vpc_id      = var.vpc-id

  ingress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }
  tags = {
    Name = "${var.base-name}.sg.msk"
  }
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

resource "aws_kms_key" "main" {
  description             = "msk KMS key."
  deletion_window_in_days = 30
  enable_key_rotation     = "true"
  tags = {
    "Name" = "${var.base-name}.kms.msk"
  }
}

resource "aws_kms_alias" "alias" {
  name          = replace("alias/${var.base-name}.kms.msk", ".", "_")
  target_key_id = aws_kms_key.main.key_id
}

resource "aws_cloudwatch_log_group" "main" {
  name = "/aws/msk/broker/${var.base-name}"
}

resource "aws_msk_configuration" "main" {
  kafka_versions    = ["3.5.1"]
  name              = replace("${var.base-name}.msk.config", ".", "-")
  server_properties = <<EOF
auto.create.topics.enable=true
log.retention.hours=8
default.replication.factor=3
min.insync.replicas=2
num.io.threads=8
num.network.threads=5
num.partitions=6
num.replica.fetchers=2
replica.lag.time.max.ms=30000
socket.receive.buffer.bytes=102400
socket.request.max.bytes=104857600
socket.send.buffer.bytes=102400
unclean.leader.election.enable=true
zookeeper.session.timeout.ms=18000
allow.everyone.if.no.acl.found=false
EOF
}
resource "aws_msk_cluster" "main" {
  cluster_name           = replace("${var.base-name}.msk.cluster", ".", "-")
  kafka_version          = "3.5.1"
  number_of_broker_nodes = 3

  configuration_info {
    arn      = aws_msk_configuration.main.arn
    revision = aws_msk_configuration.main.latest_revision
  }
  broker_node_group_info {
    instance_type  = "kafka.m5.large"
    client_subnets = data.aws_subnets.main.ids
    storage_info {
      ebs_storage_info {
        volume_size = 100
      }
    }
    security_groups = [aws_security_group.main.id]
    connectivity_info {
      public_access {
        type = "DISABLED"
      }
      vpc_connectivity {
        client_authentication {
          tls = length(var.tls-certificate-arns) > 0 ? true : false
          sasl {
            iam   = true
            scram = true
          }
        }
      }
    }
  }

  client_authentication {
    sasl {
      iam   = true
      scram = true
    }
    tls {
      certificate_authority_arns = var.tls-certificate-arns
    }
    unauthenticated = false
  }

  encryption_info {
    encryption_at_rest_kms_key_arn = aws_kms_key.main.arn
    encryption_in_transit {
      in_cluster    = true
      client_broker = "TLS"
    }
  }

  open_monitoring {
    prometheus {
      jmx_exporter {
        enabled_in_broker = true
      }
      node_exporter {
        enabled_in_broker = true
      }
    }
  }

  logging_info {
    broker_logs {
      cloudwatch_logs {
        enabled   = true
        log_group = aws_cloudwatch_log_group.main.name
      }
    }
  }
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
          "Resource" : "arn:${var.partition}:kafka:${var.region}:${var.account-id}:cluster/${aws_msk_cluster.main.cluster_name}/*"
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
          "Resource" : "arn:${var.partition}:kafka:${var.region}:${var.account-id}:topic/${aws_msk_cluster.main.cluster_name}/*"
        },
        {
          "Effect" : "Allow",
          "Action" : [
            "kafka-cluster:AlterGroup",
            "kafka-cluster:DeleteGroup",
            "kafka-cluster:DescribeGroup"
          ],
          "Resource" : "arn:${var.partition}:kafka:${var.region}:${var.account-id}:group/${aws_msk_cluster.main.cluster_name}/*"
        },
        {
          "Effect" : "Allow",
          "Action" : [
            "kafka-cluster:DescribeTransactionalId",
            "kafka-cluster:AlterTransactionalId",
          ],
          "Resource" : "arn:${var.partition}:kafka:${var.region}:${var.account-id}:transactional-id/${aws_msk_cluster.main.cluster_name}/*"
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

output "admin_iam_role_arn" {
  value = aws_iam_role.main.arn
}

data "aws_msk_broker_nodes" "main" {
  cluster_arn = aws_msk_cluster.main.arn
}

output "cluster_name" {
  value = aws_msk_cluster.main.cluster_name
}
output "cluster_arn" {
  value = aws_msk_cluster.main.arn
}

output "zookeeper_connect_string" {
  value = aws_msk_cluster.main.zookeeper_connect_string
}

output "bootstrap_brokers_tls" {
  description = "TLS connection host:port pairs"
  value       = aws_msk_cluster.main.bootstrap_brokers_tls
}

output "bootstrap_brokers" {
  description = "Unauthenticated connection host:port pairs"
  value       = aws_msk_cluster.main.bootstrap_brokers
}

output "bootstrap_brokers_sasl_iam" {
  description = "SASL IAM connection host:port pairs"
  value       = aws_msk_cluster.main.bootstrap_brokers_sasl_iam
}

output "bootstrap_brokers_sasl_scram" {
  description = "SASL SCRAM connection host:port pairs"
  value       = aws_msk_cluster.main.bootstrap_brokers_sasl_scram
}

output "bootstrap_brokers_vpc_connectivity_sasl_iam" {
  description = "Multi-VPC SASL IAM connection host:port pairs"
  value       = aws_msk_cluster.main.bootstrap_brokers_vpc_connectivity_sasl_iam
}
output "bootstrap_brokers_vpc_connectivity_sasl_scram" {
  description = "Multi-VPC SASL SCRAM connection host:port pairs"
  value       = aws_msk_cluster.main.bootstrap_brokers_vpc_connectivity_sasl_scram
}
output "bootstrap_brokers_vpc_connectivity_tls" {
  description = "Multi-VPC TLS connection host:port pairs"
  value       = aws_msk_cluster.main.bootstrap_brokers_vpc_connectivity_tls
}
output "broker_nodes" {
  value = data.aws_msk_broker_nodes.main.node_info_list
}
output "security_group_id" {
  value = aws_security_group.main.id
}
