/*
* Create a prometheus instance running on ECS.
*/
resource "aws_security_group" "prometheus" {
  name        = "${var.base-name}.sg.prometheus"
  description = "prometheus"
  vpc_id      = var.vpc-id

  ingress {
    from_port        = 9090
    to_port          = 9090
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }
  egress {
    from_port        = 443
    to_port          = 443
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = {
    Name = "prometheus"
  }
}


resource "aws_iam_policy" "ecs_task_custom_policy" {
  name = "${var.app-shorthand-name}.ecs.prometheus.ecs-task-custom-policy"
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
      "Sid": "AllowReadCloudMap",
      "Effect": "Allow",
      "Action": [
        "servicediscovery:List*",
        "servicediscovery:Get*",
        "servicediscovery:Describe*"
      ],
      "Resource": "*"
    },
    {
      "Effect": "Allow",
      "Action": [
          "ssm:DescribeParameters"
      ],
      "Resource": "*"
    },
    {
      "Effect": "Allow",
      "Action": [
          "ssm:GetParameters"
      ],
      "Resource": "arn:${var.partition}:ssm:${var.region}:${var.account-id}:parameter/ECS-*"
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
  name               = "${var.app-shorthand-name}.ecs.prometheus.task-execution-role"
  assume_role_policy = data.aws_iam_policy_document.ecs_task.json
}
resource "aws_iam_role" "ecs_task_role" {
  name               = "${var.app-shorthand-name}.ecs.prometheus.task-role"
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

resource "aws_ecs_task_definition" "prometheus" {
  family                   = "prometheus"
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = "1024"
  memory                   = "2048"
  task_role_arn            = aws_iam_role.ecs_task_role.arn
  execution_role_arn       = aws_iam_role.ecs_task_execution_role.arn

  volume {
    name = "configVolume"
  }
  volume {
    name = "logsVolume"
    # efs_volume_configuration {
    #   root_directory          = "/data"
    #   transit_encryption      = "ENABLED"
    #   transit_encryption_port = 443

    # }
  }

  container_definitions = <<DEFINITION
[
    {
        "name": "config-reloader",
        "image": "public.ecr.aws/awsvijisarathy/prometheus-sdconfig-reloader:1.0",
        "user": "root",
        "cpu": 128,
        "memory": 128,
        "environment": [
            {
                "name": "CONFIG_FILE_DIR",
                "value": "/etc/config"
            },
            {
                "name": "CONFIG_RELOAD_FREQUENCY",
                "value": "60"
            },
            {
                "name": "PROMETHEUS_CONFIG_PARAMETER_NAME",
                "value": "ECS-Prometheus-Configuration"
            },
            {
                "name": "DISCOVERY_NAMESPACES_PARAMETER_NAME",
                "value": "ECS-ServiceDiscovery-Namespaces"
            }
        ],
        "mountPoints": [
            {
                "sourceVolume": "configVolume",
                "containerPath": "/etc/config",
                "readOnly": false
            }
        ],
        "logConfiguration": {
            "logDriver": "awslogs",
            "options": {
                "awslogs-group": "/ecs/prometheus",
                "awslogs-create-group": "true",
                "awslogs-region": "${var.region}",
                "awslogs-stream-prefix": "reloader"
            }
        },
        "essential": true
    },
    {
        "name": "prometheus-server",
        "image": "prom/prometheus:latest",
        "user": "root",
        "cpu": 512,
        "memory": 512,
        "portMappings": [
            {
                "containerPort": 9090,
                "hostPort": 9090,
                "protocol": "tcp"
            }
        ],
        "command": [
            "--storage.tsdb.retention.time=15d",
            "--config.file=/etc/config/prometheus.yaml",
            "--storage.tsdb.path=/data",
            "--web.console.libraries=/etc/prometheus/console_libraries",
            "--web.console.templates=/etc/prometheus/consoles",
            "--web.enable-lifecycle"
        ],
        "logConfiguration": {
            "logDriver": "awslogs",
            "options": {
                "awslogs-group": "/ecs/prometheus",
                "awslogs-create-group": "true",
                "awslogs-region": "${var.region}",
                "awslogs-stream-prefix": "server"
            }
        },
        "mountPoints": [
            {
                "sourceVolume": "configVolume",
                "containerPath": "/etc/config",
                "readOnly": false
            },
            {
                "sourceVolume": "logsVolume",
                "containerPath": "/data"
            }
        ],
        "healthCheck": {
            "command": [
                "CMD-SHELL",
                "wget http://localhost:9090/-/healthy -O /dev/null|| exit 1"
            ],
            "interval": 10,
            "timeout": 2,
            "retries": 2,
            "startPeriod": 10
        },
        "dependsOn": [
            {
                "containerName": "config-reloader",
                "condition": "START"
            }
        ],
        "essential": true
    }
]
DEFINITION
}

resource "aws_service_discovery_service" "main" {
  name = "prometheus"

  dns_config {
    namespace_id = var.service-discovery-namespace-id

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
  name            = replace("${var.base-name}.ecs.service.prometheus", ".", "_")
  cluster         = var.cluster-id
  task_definition = aws_ecs_task_definition.prometheus.arn
  desired_count   = 2
  network_configuration {
    subnets          = var.subnet-ids
    security_groups  = [aws_security_group.prometheus.id]
    assign_public_ip = true
  }
  service_registries {
    registry_arn = aws_service_discovery_service.main.arn

  }
  launch_type = "FARGATE"
}
