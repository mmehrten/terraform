/*
* Create a rds culster.
*/

locals {
  engine_major_version = split(".", var.engine-version)[0]
}

resource "aws_security_group" "main" {
  name        = "${var.base-name}.sg.rds-pg"
  description = "Security group for rds clusters."
  vpc_id      = var.vpc-id

  ingress {
    description      = "Allow all inbound connections over 5432"
    from_port        = 5432
    to_port          = 5432
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = []
  }

  tags = {
    Name = "${var.base-name}.sg.rds"
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
data "aws_subnet" "main" {
  for_each = { for o in data.aws_subnets.main.ids : o => o }
  id       = each.value
}

resource "aws_kms_key" "main" {
  description             = "rds KMS key."
  deletion_window_in_days = 30
  enable_key_rotation     = "true"
  tags = {
    "Name" = "${var.base-name}.kms.rds"
  }
}

resource "aws_kms_alias" "alias" {
  name          = replace("alias/${var.base-name}.kms.rds", ".", "_")
  target_key_id = aws_kms_key.main.key_id
}

resource "aws_db_parameter_group" "main" {
  name   = replace("${var.base-name}.rds${local.engine_major_version}", ".", "-")
  # family = "aurora-postgresql15"
  family = "aurora-postgresql${local.engine_major_version}"

  parameter {
    name  = "log_connections"
    value = "1"
  }
  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_rds_cluster_parameter_group" "main" {
  name   = replace("${var.base-name}.rds${local.engine_major_version}", ".", "-")
  # family = "aurora-postgresql15"
  family = "aurora-postgresql${local.engine_major_version}"

  parameter {
    name  = "log_connections"
    value = "1"
  }
  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_db_subnet_group" "main" {
  name       = replace("${var.base-name}.rds", ".", "-")
  subnet_ids = data.aws_subnets.main.ids
}

resource "aws_rds_cluster" "main" {
  cluster_identifier                  = replace("${var.base-name}.rds.${var.database-name}", ".", "-")
  engine                              = "aurora-postgresql"
  engine_version                      = "${var.engine-version}"
  availability_zones                  = [for k, v in data.aws_subnet.main : v.availability_zone]
  database_name                       = "dev"
  master_username                     = "dev"
  master_password                     = var.master-password
  backup_retention_period             = 5
  preferred_backup_window             = "07:00-09:00"
  db_subnet_group_name                = aws_db_subnet_group.main.name
  skip_final_snapshot                 = true
  kms_key_id                          = aws_kms_key.main.arn
  storage_encrypted                   = true
  iam_database_authentication_enabled = true
  vpc_security_group_ids              = [aws_security_group.main.id]
  db_cluster_parameter_group_name = aws_rds_cluster_parameter_group.main.name
  db_instance_parameter_group_name = aws_db_parameter_group.main.name
  allow_major_version_upgrade = true
}

resource "aws_rds_cluster_instance" "main" {
  count                           = var.instance-count
  identifier                      = "${replace("${var.base-name}.rds.${var.database-name}", ".", "-")}-${count.index}"
  cluster_identifier              = aws_rds_cluster.main.id
  instance_class                  = "db.t4g.medium"
  engine                          = aws_rds_cluster.main.engine
  engine_version                  = aws_rds_cluster.main.engine_version
  db_parameter_group_name         = aws_db_parameter_group.main.name
  db_subnet_group_name            = aws_db_subnet_group.main.name
  performance_insights_enabled    = true
  performance_insights_kms_key_id = aws_kms_key.main.arn
}

output "arn" {
  value = aws_rds_cluster.main.arn
}
output "master_username" {
  value = aws_rds_cluster.main.master_username
}
output "kms_arn" {
  value = aws_kms_key.main.arn
}
output "endpoint" {
  value = aws_rds_cluster.main.endpoint
}
