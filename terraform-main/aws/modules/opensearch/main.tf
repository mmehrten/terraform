/*
* Create an OpenSearch culster.
*/

resource "aws_kms_key" "main" {
  description             = "OpenSearch KMS key."
  deletion_window_in_days = 30
  enable_key_rotation     = "true"
  tags = {
    "Name" = "${var.base-name}.kms.opensearch"
  }
}

resource "aws_kms_alias" "alias" {
  name          = replace("alias/${var.base-name}.kms.opensearch", ".", "_")
  target_key_id = aws_kms_key.main.key_id
}

resource "aws_security_group" "main" {
  name        = "${var.base-name}.sg.opensearch"
  description = "Security group for OpenSearch clusters."
  vpc_id      = var.vpc-id

  ingress {
    description      = "Allow all inbound connections"
    from_port        = 0
    to_port          = 65535
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = []
  }

  egress {
    description      = "Allow all outbound connections"
    from_port        = 0
    to_port          = 65535
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = []
  }

  tags = {
    Name = "${var.base-name}.sg.opensearch"
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

data "aws_iam_policy_document" "main" {
  statement {
    effect = "Allow"

    principals {
      type        = "*"
      identifiers = ["*"]
    }

    actions   = ["es:*"]
    resources = ["arn:${var.partition}:es:${var.region}:${var.account-id}:domain/${var.domain-name}/*"]
  }
}

resource "aws_iam_role" "main" {
  name               = "${var.app-shorthand-name}.iam.role.opensearch-admin"
  assume_role_policy = <<EOF
{
 "Version": "2012-10-17",
 "Statement": [
   {
     "Action": "sts:AssumeRole",
     "Principal": {
       "Service": "lambda.amazonaws.com"
     },
     "Effect": "Allow",
     "Sid": ""
   }
 ]
}
EOF
}


resource "aws_iam_role_policy" "main" {
  name   = "${var.app-shorthand-name}.iam.role.opensearch-admin"
  role   = aws_iam_role.main.id
  policy = <<EOF
{
   "Version": "2012-10-17",
   "Statement": [
        {
            "Effect": "Allow",
            "Action": "es:*",
            "Resource": "*"
        }
   ]
}
EOF
}

resource "aws_opensearch_domain" "main" {
  domain_name    = var.domain-name
  engine_version = "OpenSearch_2.9"

  cluster_config {
    instance_type  = "m4.large.search" # "t3.medium.search"
    instance_count = 3

    dedicated_master_enabled = true
    dedicated_master_type    = "m4.large.search"
    dedicated_master_count   = 3

    warm_enabled = true
    warm_count   = 2
    warm_type    = "ultrawarm1.medium.search"
    cold_storage_options {
      enabled = true
    }

    # multi_az_with_standby_enabled = true
    zone_awareness_enabled = true
    zone_awareness_config {
      availability_zone_count = 3
    }
  }

  ebs_options {
    ebs_enabled = true
    volume_size = 10
  }

  vpc_options {
    subnet_ids         = data.aws_subnets.main.ids
    security_group_ids = [aws_security_group.main.id]
  }

  # cognito_options {
  #   enabled = false
  # }

  encrypt_at_rest {
    enabled    = true
    kms_key_id = aws_kms_key.main.id
  }

  node_to_node_encryption {
    enabled = true
  }

  advanced_options = {
    "rest.action.multi.allow_explicit_index" = "true"
    "indices.fielddata.cache.size"           = "20"
    "indices.query.bool.max_clause_count"    = "1024"
  }

  domain_endpoint_options {
    enforce_https           = true
    tls_security_policy     = "Policy-Min-TLS-1-2-2019-07"
    custom_endpoint_enabled = false
  }

  advanced_security_options {
    enabled                        = true
    anonymous_auth_enabled         = false
    internal_user_database_enabled = false
    master_user_options {
      master_user_arn = aws_iam_role.main.arn
    }
  }

  off_peak_window_options {
    enabled = true
    off_peak_window {
      window_start_time {
        hours   = 0
        minutes = 0
      }
    }
  }

  software_update_options {
    auto_software_update_enabled = true
  }

  access_policies = data.aws_iam_policy_document.main.json

}

output "arn" {
  value = aws_opensearch_domain.main.arn
}
output "iam_role_arn" {
  value = aws_iam_role.main.arn
}
output "endpoint" {
  value = aws_opensearch_domain.main.endpoint
}