variable "vpc_id" {
  description = "The VPC to deploy DataPrepper in"
  type        = string
}

variable "service_prefix" {
  description = "The prefix to use for the service name"
  type        = string
}

variable "opensearch_arn" {
  description = "The ARN of the OpenSearch cluster"
  type        = string
}

variable "kms_key_arn" {
  description = "The ARN of the KMS key for S3"
  type        = string
}

data "aws_caller_identity" "current" {}

data "aws_subnets" "public" {
  filter {
    name   = "vpc-id"
    values = [var.vpc_id]
  }
  filter {
    name   = "tag:Name"
    values = ["*private*"]
  }
}

resource "aws_service_discovery_private_dns_namespace" "main" {
  name        = "${var.service_prefix}.dataprepper.local"
  description = "${var.service_prefix} service discovery"
  vpc         = var.vpc_id
}

/*
* Create a dataprepper instance running on ECS.
*/
resource "aws_security_group" "dataprepper" {
  name        = "${var.service_prefix}.sg"
  description = "dataprepper"
  vpc_id      = var.vpc_id
}


resource "aws_iam_policy" "ecs_task_custom_policy" {
  name = "${var.service_prefix}.ecs.dataprepper.ecs-task-custom-policy"
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
        },
        {
          "Sid" : "AllowOpenSearchAPIAccess",
          "Effect" : "Allow",
          "Action" : [
            "es:HTTP*",
          ],
          "Resource" : "${var.opensearch_arn}/*"
        },
        {
          "Sid" : "AllowS3Read",
          "Effect" : "Allow",
          "Action" : [
            "s3:GetObject",
            "s3:ListBucket",
            "s3:DeleteObject"
          ],
          "Resource" : "${var.s3_bucket_arn}/*"
        },
        {
          "Sid" : "AllowSQSRead",
          "Effect" : "Allow",
          "Action" : [
            "sqs:ChangeMessageVisibility",
            "sqs:DeleteMessage",
            "sqs:ReceiveMessage"
          ],
          "Resource" : "arn:${var.partition}:sqs:*:${data.aws_caller_identity.current.account_id}:${var.queue_prefix}*"
        },
        {
          "Sid" : "AllowKMSDecrypt",
          "Effect" : "Allow",
          "Action" : "kms:Decrypt",
          "Resource" : "${var.kms_key_arn}"
        }
      ]
  })
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
# Create the IAM roles for the ECS Task
resource "aws_iam_role" "ecs_task_execution_role" {
  name               = "${var.service_prefix}.ecs.dataprepper.task-execution-role"
  assume_role_policy = data.aws_iam_policy_document.ecs_task.json
}
resource "aws_iam_role" "ecs_task_role" {
  name               = "${var.service_prefix}.ecs.dataprepper.task-role"
  assume_role_policy = data.aws_iam_policy_document.ecs_task.json
}
resource "aws_iam_role_policy_attachment" "task_custom" {
  role       = aws_iam_role.ecs_task_role.name
  policy_arn = aws_iam_policy.ecs_task_custom_policy.arn
}
resource "aws_iam_role_policy_attachment" "task_ecr" {
  role       = aws_iam_role.ecs_task_role.name
  policy_arn = "arn:${var.partition}:iam::aws:policy/AmazonEC2ContainerRegistryPowerUser"
}
resource "aws_iam_role_policy_attachment" "task_cloudwatch" {
  role       = aws_iam_role.ecs_task_role.name
  policy_arn = "arn:${var.partition}:iam::aws:policy/CloudWatchFullAccess"
}
resource "aws_iam_role_policy_attachment" "task_ssm_ro" {
  role       = aws_iam_role.ecs_task_role.name
  policy_arn = "arn:${var.partition}:iam::aws:policy/AmazonSSMReadOnlyAccess"
}
resource "aws_iam_role_policy_attachment" "task_execution_custom" {
  role       = aws_iam_role.ecs_task_execution_role.name
  policy_arn = aws_iam_policy.ecs_task_custom_policy.arn
}
resource "aws_iam_role_policy_attachment" "task_execution_ecr" {
  role       = aws_iam_role.ecs_task_execution_role.name
  policy_arn = "arn:${var.partition}:iam::aws:policy/AmazonEC2ContainerRegistryPowerUser"
}
resource "aws_iam_role_policy_attachment" "task_execution_cloudwatch" {
  role       = aws_iam_role.ecs_task_execution_role.name
  policy_arn = "arn:${var.partition}:iam::aws:policy/CloudWatchFullAccess"
}
resource "aws_iam_role_policy_attachment" "task_execution_ssm_ro" {
  role       = aws_iam_role.ecs_task_execution_role.name
  policy_arn = "arn:${var.partition}:iam::aws:policy/AmazonSSMReadOnlyAccess"
}

resource "aws_cloudwatch_log_group" "main" {
  name              = "/ecs/dataprepper/"
  retention_in_days = 5
}

resource "aws_ecs_task_definition" "dataprepper" {
  family                   = "dataprepper"
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = "256"
  memory                   = "512"
  task_role_arn            = aws_iam_role.ecs_task_role.arn
  execution_role_arn       = aws_iam_role.ecs_task_execution_role.arn

  container_definitions = <<DEFINITION
[
  {
    "name": "dataprepper",
    "image": "${data.aws_caller_identity.current.account_id}.dkr.ecr.us-gov-west-1.amazonaws.com/dataprepper:latest",
    "essential": true,
    "logConfiguration": { 
      "logDriver": "awslogs",
      "options": { 
          "awslogs-group" : "${aws_cloudwatch_log_group.main.name}",
          "awslogs-region": "${var.region}",
          "awslogs-stream-prefix": "ecs"
      }
    },
    "portMappings": []
  }
]
DEFINITION
}

resource "aws_service_discovery_service" "main" {
  name = "dataprepper"

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

resource "aws_ecs_cluster" "main" {
  name = replace("${var.service_prefix}.ecs.cluster", ".", "_")
}

resource "aws_ecs_service" "dataprepper" {
  name            = replace("${var.service_prefix}.ecs.service.dataprepper", ".", "_")
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.dataprepper.arn
  desired_count   = 1
  network_configuration {
    subnets          = data.aws_subnets.public.ids
    security_groups  = [aws_security_group.dataprepper.id]
    assign_public_ip = true
  }
  service_registries {
    registry_arn = aws_service_discovery_service.main.arn
  }
  launch_type            = "FARGATE"
  enable_execute_command = true
}
