/*
* Create a msk culster.
*/

resource "aws_security_group" "main" {
  name        = "${var.base-name}.sg.msk-serverless"
  description = "Security group for msk serverless clusters."
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
  tags = {
    Name = "${var.base-name}.sg.msk-serverless"
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


resource "aws_msk_serverless_cluster" "main" {
  cluster_name = replace("${var.base-name}.msk.cluster", ".", "-")

  vpc_config {
    subnet_ids         = data.aws_subnets.main.ids
    security_group_ids = [aws_security_group.main.id]
  }

  client_authentication {
    sasl {
      iam {
        enabled = true
      }
    }
  }
}

resource "aws_iam_role" "main" {
  name = "${var.app-shorthand-name}.iam.role.msk-serverless.admin"
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
  name = "${var.app-shorthand-name}.iam.role.msk-serverless.admin"
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
          "Resource" : "arn:${var.partition}:kafka:${var.region}:${var.account-id}:cluster/${aws_msk_serverless_cluster.main.cluster_name}/*"
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
          "Resource" : "arn:${var.partition}:kafka:${var.region}:${var.account-id}:topic/${aws_msk_serverless_cluster.main.cluster_name}/*"
        },
        {
          "Effect" : "Allow",
          "Action" : [
            "kafka-cluster:AlterGroup",
            "kafka-cluster:DeleteGroup",
            "kafka-cluster:DescribeGroup"
          ],
          "Resource" : "arn:${var.partition}:kafka:${var.region}:${var.account-id}:group/${aws_msk_serverless_cluster.main.cluster_name}/*"
        },
        {
          "Effect" : "Allow",
          "Action" : [
            "kafka-cluster:DescribeTransactionalId",
            "kafka-cluster:AlterTransactionalId",
          ],
          "Resource" : "arn:${var.partition}:kafka:${var.region}:${var.account-id}:transactional-id/${aws_msk_serverless_cluster.main.cluster_name}/*"
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


data "aws_msk_bootstrap_brokers" "main" {
  cluster_arn = aws_msk_serverless_cluster.main.arn
}

output "cluster_arn" {
  value = aws_msk_serverless_cluster.main.arn
}
output "security_group_id" {
  value = aws_security_group.main.id
}

output "admin_iam_role_arn" {
  value = aws_iam_role.main.arn
}

output "bootstrap_brokers_sasl_iam" {
  description = "SASL IAM connection host:port pairs"
  value       = data.aws_msk_bootstrap_brokers.main.bootstrap_brokers_sasl_iam
}

