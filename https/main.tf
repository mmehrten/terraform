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

/*
* Create a https instance running on ECS.
*/
resource "aws_security_group" "https" {
  name        = "${local.base-name}.sg.https"
  description = "https"
  vpc_id      = var.vpc-id

  ingress {
    from_port        = 443
    to_port          = 443
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }
  ingress {
    from_port        = 80
    to_port          = 80
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }
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


resource "aws_iam_policy" "ecs_task_custom_policy" {
  name = "${var.app-shorthand-name}.ecs.https.ecs-task-custom-policy"
  path = "/"

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "AllowReadingTagsInstancesRegionsFromEC2",
      "Effect": "Allow",
      "Action": ["ec2:DescribeTags", "ec2:DescribeInstances", "ec2:DescribeRegions"],
      "Resource": "*"
    },
    {
      "Sid": "AllowReadingResourcesForTags",
      "Effect": "Allow",
      "Action": "tag:GetResources",
      "Resource": "*"
    },
    {
      "Sid": "AllowExecuteCommand",
      "Effect": "Allow",
      "Action": [
        "ssmmessages:CreateControlChannel",
        "ssmmessages:CreateDataChannel",
        "ssmmessages:OpenControlChannel",
        "ssmmessages:OpenDataChannel"
      ],
      "Resource": "*"
    },
    {
      "Sid": "AllowACMCertExport",
      "Effect": "Allow",
      "Action": "acm:ExportCertificate",
      "Resource": "${var.acm-cert-arn}"
    }
  ]
}
EOF
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
  name               = "${var.app-shorthand-name}.ecs.https.task-execution-role"
  assume_role_policy = data.aws_iam_policy_document.ecs_task.json
}
resource "aws_iam_role" "ecs_task_role" {
  name               = "${var.app-shorthand-name}.ecs.https.task-role"
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
  name              = "/ecs/https/"
  retention_in_days = 5
}

resource "aws_ecs_task_definition" "https" {
  family                   = "https"
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = "256"
  memory                   = "512"
  task_role_arn            = aws_iam_role.ecs_task_role.arn
  execution_role_arn       = aws_iam_role.ecs_task_execution_role.arn

  container_definitions = <<DEFINITION
[
  {
    "name": "https",
    "image": "053633994311.dkr.ecr.us-gov-west-1.amazonaws.com/https-demo:latest",
    "essential": true,
    "entryPoint": [
      "sh", 
      "run.sh",     
      "--bind", 
      ":443",
      "-w", 
      "4",
      "--ca-certs", 
      "CertificateChain",
      "--keyfile", 
      "PrivateKey",
      "--certfile", 
      "Certificate",
      "--access-logfile", 
      "-",
      "--log-level", 
      "DEBUG",
      "--ssl-version", 
      "TLS_SERVER",
      "-c", 
      "gunicorn_hooks_config.py",
      "app:app"
    ],
    "logConfiguration": { 
      "logDriver": "awslogs",
      "options": { 
          "awslogs-group" : "${aws_cloudwatch_log_group.main.name}",
          "awslogs-region": "${var.region}",
          "awslogs-stream-prefix": "ecs"
      }
    },
    "environment": [
      {"name": "AWS_ACM_CERT_ARN", "value": "${var.acm-cert-arn}"},
      {"name": "AWS_ACM_CERT_PASS", "value": "${var.acm-cert-pass}"}
    ],
    "portMappings": [ 
        { 
            "containerPort": 80,
            "hostPort": 80,
            "protocol": "tcp"
        },
        { 
            "containerPort": 443,
            "hostPort": 443,
            "protocol": "tcp"
        }
    ]
  }
]
DEFINITION
}

resource "aws_service_discovery_service" "main" {
  name = "https"

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

resource "aws_ecs_service" "https" {
  name            = replace("${local.base-name}.ecs.service.https", ".", "_")
  cluster         = module.cluster.id
  task_definition = aws_ecs_task_definition.https.arn
  desired_count   = 2
  network_configuration {
    subnets          = data.aws_subnet_ids.public.ids
    security_groups  = [aws_security_group.https.id]
    assign_public_ip = true
  }
  service_registries {
    registry_arn = aws_service_discovery_service.main.arn

  }
  launch_type            = "FARGATE"
  enable_execute_command = true
}
