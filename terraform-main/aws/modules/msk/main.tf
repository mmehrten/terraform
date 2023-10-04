/*
* Create a msk culster.
*/

resource "aws_security_group" "main" {
  name        = "${var.base-name}.sg.msk"
  description = "Security group for msk clusters."
  vpc_id      = var.vpc-id

  # ingress {
  #   description      = "Allow all inbound connections"
  #   from_port        = 0
  #   to_port          = 65535
  #   protocol         = "tcp"
  #   cidr_blocks      = ["0.0.0.0/0"]
  #   ipv6_cidr_blocks = []
  # }

  # egress {
  #   description      = "Allow all outbound connections"
  #   from_port        = 0
  #   to_port          = 65535
  #   protocol         = "tcp"
  #   cidr_blocks      = ["0.0.0.0/0"]
  #   ipv6_cidr_blocks = []
  # }

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
  name = "/aws/msk/broker"
}

resource "aws_msk_configuration" "main" {
  kafka_versions = ["3.5.1"]
  name = replace("${var.base-name}.msk.config", ".", "-")
  server_properties = <<EOF
auto.create.topics.enable=true
default.replication.factor=3
min.insync.replicas=2
num.io.threads=8
num.network.threads=5
num.partitions=1
num.replica.fetchers=2
replica.lag.time.max.ms=30000
socket.receive.buffer.bytes=102400
socket.request.max.bytes=104857600
socket.send.buffer.bytes=102400
unclean.leader.election.enable=true
zookeeper.session.timeout.ms=18000
EOF
}
resource "aws_msk_cluster" "main" {
  cluster_name           = replace("${var.base-name}.msk.cluster", ".", "-")
  kafka_version          = "3.5.1"
  number_of_broker_nodes = 3

  configuration_info {
    arn = aws_msk_configuration.main.arn
    revision = aws_msk_configuration.main.latest_revision
  }
  broker_node_group_info {
    instance_type = "kafka.t3.small"
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
    }
  }

  client_authentication {
    sasl {
      iam = true
      scram = true
    }
    # tls {
    #   certificate_authority_arns = []
    # }
    unauthenticated = true
  }

  encryption_info {
    encryption_at_rest_kms_key_arn = aws_kms_key.main.arn
    encryption_in_transit {
      in_cluster = true
      client_broker = "TLS_PLAINTEXT"
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
      # firehose {
      #   enabled         = true
      #   delivery_stream = aws_kinesis_firehose_delivery_stream.test_stream.name
      # }
      # s3 {
      #   enabled = true
      #   bucket  = aws_s3_bucket.bucket.id
      #   prefix  = "logs/msk-"
      # }
    }
  }

}

output cluster_arn {
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
  description = "TLS connection host:port pairs"
  value       = aws_msk_cluster.main.bootstrap_brokers
}

output "bootstrap_brokers_sasl_iam" {
  description = "TLS connection host:port pairs"
  value       = aws_msk_cluster.main.bootstrap_brokers_sasl_iam
}

output "bootstrap_brokers_sasl_scram" {
  description = "TLS connection host:port pairs"
  value       = aws_msk_cluster.main.bootstrap_brokers_sasl_scram
}