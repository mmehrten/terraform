/*
*   Create a YACE ECS service to export CloudWatch metrics from Commerical to GovCloud.
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

resource "aws_kms_key" "main" {
  description             = "${local.base-name}.kms.secret"
  deletion_window_in_days = 7
  enable_key_rotation     = "true"
  tags = {
    "Name" = "${local.base-name}.kms.secret"
  }
}

resource "aws_kms_alias" "main-alias" {
  name          = replace("alias/${aws_kms_key.main.description}", ".", "_")
  target_key_id = aws_kms_key.main.key_id
}

resource "aws_secretsmanager_secret" "main" {
  name        = "${local.base-name}.secret.commercial"
  description = "Commercial credentials for YACE"
  kms_key_id  = aws_kms_key.main.key_id
  policy = jsonencode(
    {
      "Version" : "2012-10-17",
      "Statement" : [
        {
          "Effect" : "Allow",
          "Action" : [
            "secretsmanager:*"
          ],
          "Principal" : {
            "AWS" : [
              "arn:${var.partition}:iam::${var.account-id}:root",
              "arn:${var.partition}:iam::${var.account-id}:role/Admin"
            ]
          }
          "Resource" : "*",
        },
        {
          "Effect" : "Deny",
          "Action" : [
            "secretsmanager:*"
          ],
          "Principal" : "*",
          "Resource" : "*",
          "Condition" : {
            "ArnNotLike" : {
              "aws:PrincipalArn" : [
                "arn:${var.partition}:iam::${var.account-id}:root",
                "arn:${var.partition}:iam::${var.account-id}:role/Admin",
                aws_iam_role.ecs_task_execution_role.arn,
              ]
            }
          }
        }
      ]
    }
  )
  recovery_window_in_days = 7
}
resource "aws_secretsmanager_secret_version" "main" {
  secret_id = aws_secretsmanager_secret.main.id
  secret_string = jsonencode(
    {
      "secret_key" : var.commercial-secret-key,
      "access_key" : var.commercial-access-key,
      "region" : var.commercial-region,
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
  inline_policy {
    name = "TaskExecSecrets"
    policy = jsonencode(
      {
        "Version" : "2012-10-17",
        "Statement" : [
          {
            "Sid" : "AllowSecretRead",
            "Effect" : "Allow",
            "Action" : [
              "secretsmanager:GetSecretValue",
              "kms:Decrypt"
            ],
            "Resource" : [
              #TODO: Secret/key
              "*"
            ]
          }
        ]
      }
    )
  }
}
resource "aws_iam_role" "ecs_task_role" {
  name               = "${var.app-shorthand-name}.ecs.task-role"
  assume_role_policy = data.aws_iam_policy_document.ecs_task.json
  inline_policy {
    name = "TaskSSM"
    policy = jsonencode(
      {
        "Version" : "2012-10-17",
        "Statement" : [
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
            "Sid" : "AllowIdentifyECSTasks",
            "Effect" : "Allow",
            "Action" : [
              "ecs:List*",
              "ecs:Describe*"
            ],
            "Resource" : [
              "*"
            ]
          }
        ]
      }
    )
  }
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
    from_port        = 5000
    to_port          = 5000
    protocol         = "tcp"
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

resource "aws_ecr_repository" "yace" {
  name                 = "yace"
  image_tag_mutability = "MUTABLE"
  force_delete         = true

  image_scanning_configuration {
    scan_on_push = true
  }
  encryption_configuration {
    encryption_type = "AES256"
  }
}
resource "aws_cloudwatch_log_group" "yace" {
  name              = "/ecs/yace"
  retention_in_days = 5
}
resource "aws_ecs_task_definition" "yace" {
  family                   = "yace"
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = "256"
  memory                   = "512"
  task_role_arn            = aws_iam_role.ecs_task_role.arn
  execution_role_arn       = aws_iam_role.ecs_task_execution_role.arn
  runtime_platform {
    cpu_architecture        = "X86_64"
    operating_system_family = "LINUX"
  }

  container_definitions = jsonencode(
    [
      {
        "name" : "yace",
        "image" : "${aws_ecr_repository.yace.repository_url}:latest",
        "cpu" : 0,
        "portMappings" : [
          {
            "name" : "5000",
            "containerPort" : 5000,
            "hostPort" : 5000,
            "protocol" : "tcp",
            "appProtocol" : "http"
          }
        ],
        "essential" : true,
        "secrets" : [
          {
            "name" : "AWS_ACCESS_KEY_ID",
            "valueFrom" : "arn:${var.partition}:secretsmanager:${var.region}:${var.account-id}:secret:${aws_secretsmanager_secret.main.name}:access_key::"
          },
          {
            "name" : "AWS_SECRET_ACCESS_KEY",
            "valueFrom" : "arn:${var.partition}:secretsmanager:${var.region}:${var.account-id}:secret:${aws_secretsmanager_secret.main.name}:secret_key::"
          },
          {
            "name" : "AWS_DEFAULT_REGION",
            "valueFrom" : "arn:${var.partition}:secretsmanager:${var.region}:${var.account-id}:secret:${aws_secretsmanager_secret.main.name}:region::"
          }
        ],
        "mountPoints" : [],
        "volumesFrom" : [],
        "systemControls" : [],
        "logConfiguration" : {
          "logDriver" : "awslogs",
          "options" : {
            "awslogs-create-group" : "true",
            "awslogs-group" : aws_cloudwatch_log_group.yace.name,
            "awslogs-region" : var.region,
            "awslogs-stream-prefix" : "ecs"
          }
        }
      }
    ]
  )
}
resource "aws_service_discovery_service" "yace" {
  name = "yace"

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
resource "aws_ecs_service" "yace" {
  name            = replace("${local.base-name}.ecs.service.yace", ".", "_")
  cluster         = module.cluster.id
  task_definition = aws_ecs_task_definition.yace.arn
  desired_count   = 1
  network_configuration {
    subnets          = data.aws_subnets.private.ids
    security_groups  = [aws_security_group.ecs.id]
    assign_public_ip = false
  }
  service_registries {
    registry_arn = aws_service_discovery_service.yace.arn
  }
  launch_type            = "FARGATE"
  enable_execute_command = true
}

