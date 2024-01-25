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
  count              = var.master-password == null ? 1 : 0
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
  count  = var.master-password == null ? 1 : 0
  name   = "${var.app-shorthand-name}.iam.role.opensearch-admin"
  role   = aws_iam_role.main[0].id
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
    internal_user_database_enabled = var.master-password == null ? false : true
    dynamic "master_user_options" {
      for_each = var.master-password == null ? [1] : []
      content {
        master_user_arn = aws_iam_role.main[0].arn
      }
    }
    dynamic "master_user_options" {
      for_each = var.master-password == null ? [] : [1]
      content {
        master_user_name     = "admin"
        master_user_password = var.master-password
      }
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


resource "aws_opensearch_domain_saml_options" "main" {
  domain_name = aws_opensearch_domain.main.domain_name

  saml_options {
    enabled                 = true
    roles_key               = "Role"
    session_timeout_minutes = 60

    idp {
      entity_id        = "urn:dev-rd4ugvvduiwgubhu.us.auth0.com"
      metadata_content = <<-EOT
<EntityDescriptor entityID="urn:dev-rd4ugvvduiwgubhu.us.auth0.com" xmlns="urn:oasis:names:tc:SAML:2.0:metadata">
  <IDPSSODescriptor protocolSupportEnumeration="urn:oasis:names:tc:SAML:2.0:protocol">
    <KeyDescriptor use="signing">
      <KeyInfo xmlns="http://www.w3.org/2000/09/xmldsig#">
        <X509Data>
          <X509Certificate>MIIDHTCCAgWgAwIBAgIJcDbfCgyg+/RyMA0GCSqGSIb3DQEBCwUAMCwxKjAoBgNVBAMTIWRldi1yZDR1Z3Z2ZHVpd2d1Ymh1LnVzLmF1dGgwLmNvbTAeFw0yMzA3MjUxNjM3NDlaFw0zNzA0MDIxNjM3NDlaMCwxKjAoBgNVBAMTIWRldi1yZDR1Z3Z2ZHVpd2d1Ymh1LnVzLmF1dGgwLmNvbTCCASIwDQYJKoZIhvcNAQEBBQADggEPADCCAQoCggEBAKh6zEFxHwgU1rSExiVywilygGKZxock4Hw81qr+JaeTuvsMpNIiKbnuuEchw4gvs746sXO8k4GHdNScm2kyXzTbVZeYfscofaTwD9wkxFsfHBcGxmPdkRbWG80j8KqqBKIrtaTqxYb4V82Cj779C1A2yj/mSIfzRf6NTIOkUQv7ZeI+bGZDrN7UtV8g5b8SB+rQjxxtxEWzyPfdoTdTIaInrXA8Kkm66NjnHYE22JYT4bctI2RjWpS2fV1IgDltESRy5lQP7Xw0FZV1Dv7AKz/fPw0KrF4ezRLaVjx4/Oo4Lrlv/3iVfY6w67Jocf1Ik0HDcO4sK+grGH4m4wpYBzcCAwEAAaNCMEAwDwYDVR0TAQH/BAUwAwEB/zAdBgNVHQ4EFgQU4RXRTzywWUq18eLvWYn3/7dh2wcwDgYDVR0PAQH/BAQDAgKEMA0GCSqGSIb3DQEBCwUAA4IBAQBWHl3vKGnDZ5hmakGwP1qpLsShwbBCNQnKuZkAHPOk4xoYFEHRPuc+woOBjru/uTFO4ahfrhrdDcW+Wnbbkw0WJIiQnmNDRCOllTt3St/b1xfPWzYiAN9847wsh7/7jhzEAsB6yXQ2Ukw5rlkaecG4KH8FJNmDq6OK6pyKGCQOmBJcXT7ryzEwlaqliIoLTe0WaQ5kgUgfEF3aUUKlsxb3528nnqgh9EQSJSIJW7ziAJ02PgqH2ey6VyAdKoM2si14G9z8USQGd+2JcvaMkGzUa4AAADE+OkyC/uMUy91RhdgjDKgAQNECy79kyaESPdnix0QBp+lM3TFEPd/Cldpw</X509Certificate>
        </X509Data>
      </KeyInfo>
    </KeyDescriptor>
    <SingleLogoutService Binding="urn:oasis:names:tc:SAML:2.0:bindings:HTTP-Redirect" Location="https://dev-rd4ugvvduiwgubhu.us.auth0.com/samlp/oL1MXfieBEV6spQb4DAcZdTPWMLdz8xa/logout"/>
    <SingleLogoutService Binding="urn:oasis:names:tc:SAML:2.0:bindings:HTTP-POST" Location="https://dev-rd4ugvvduiwgubhu.us.auth0.com/samlp/oL1MXfieBEV6spQb4DAcZdTPWMLdz8xa/logout"/>
    <NameIDFormat>urn:oasis:names:tc:SAML:1.1:nameid-format:emailAddress</NameIDFormat>
    <NameIDFormat>urn:oasis:names:tc:SAML:2.0:nameid-format:persistent</NameIDFormat>
    <NameIDFormat>urn:oasis:names:tc:SAML:2.0:nameid-format:transient</NameIDFormat>
    <SingleSignOnService Binding="urn:oasis:names:tc:SAML:2.0:bindings:HTTP-Redirect" Location="https://dev-rd4ugvvduiwgubhu.us.auth0.com/samlp/oL1MXfieBEV6spQb4DAcZdTPWMLdz8xa"/>
    <SingleSignOnService Binding="urn:oasis:names:tc:SAML:2.0:bindings:HTTP-POST" Location="https://dev-rd4ugvvduiwgubhu.us.auth0.com/samlp/oL1MXfieBEV6spQb4DAcZdTPWMLdz8xa"/>
    <Attribute Name="http://schemas.xmlsoap.org/ws/2005/05/identity/claims/emailaddress" NameFormat="urn:oasis:names:tc:SAML:2.0:attrname-format:uri" FriendlyName="E-Mail Address" xmlns="urn:oasis:names:tc:SAML:2.0:assertion"/>
    <Attribute Name="http://schemas.xmlsoap.org/ws/2005/05/identity/claims/givenname" NameFormat="urn:oasis:names:tc:SAML:2.0:attrname-format:uri" FriendlyName="Given Name" xmlns="urn:oasis:names:tc:SAML:2.0:assertion"/>
    <Attribute Name="http://schemas.xmlsoap.org/ws/2005/05/identity/claims/name" NameFormat="urn:oasis:names:tc:SAML:2.0:attrname-format:uri" FriendlyName="Name" xmlns="urn:oasis:names:tc:SAML:2.0:assertion"/>
    <Attribute Name="http://schemas.xmlsoap.org/ws/2005/05/identity/claims/surname" NameFormat="urn:oasis:names:tc:SAML:2.0:attrname-format:uri" FriendlyName="Surname" xmlns="urn:oasis:names:tc:SAML:2.0:assertion"/>
    <Attribute Name="http://schemas.xmlsoap.org/ws/2005/05/identity/claims/nameidentifier" NameFormat="urn:oasis:names:tc:SAML:2.0:attrname-format:uri" FriendlyName="Name ID" xmlns="urn:oasis:names:tc:SAML:2.0:assertion"/>
  </IDPSSODescriptor>
</EntityDescriptor>
EOT 
    }
  }
}

output "arn" {
  value = aws_opensearch_domain.main.arn
}
output "iam_role_arn" {
  value = var.master-password == null ? aws_iam_role.main[0].arn : ""
}
output "iam_role_id" {
  value = var.master-password == null ? aws_iam_role.main[0].id : ""
}
output "endpoint" {
  value = aws_opensearch_domain.main.endpoint
}
