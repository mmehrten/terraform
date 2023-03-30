/*
* Create a Cognito user pool.
*/

resource "aws_iam_role" "main" {
  name               = "${var.base-name}.iam.role.cognito.sns"
  assume_role_policy = <<EOF
{
 "Version": "2012-10-17",
 "Statement": [
   {
     "Action": "sts:AssumeRole",
     "Principal": {
       "Service": "cognito-idp.amazonaws.com"
     },
     "Effect": "Allow",
     "Sid": ""
   }
 ]
}
EOF
}


resource "aws_iam_role_policy" "main" {
  name   = "${var.base-name}.iam.role.cognito.sns"
  role   = aws_iam_role.main.id
  policy = <<EOF
{
   "Version": "2012-10-17",
   "Statement": [
        {
            "Effect": "Allow",
            "Action": "sns:publish",
            "Resource": "*"
        }
   ]
}
EOF
}

resource "aws_cognito_user_pool" "main" {
  name                     = "${var.base-name}.cognito.pool"
  auto_verified_attributes = ["email", "phone_number"]
  alias_attributes = [
    "email",
    "phone_number",
    "preferred_username",
  ]
  mfa_configuration          = "ON"
  sms_authentication_message = "Your code is {####}"
  sms_configuration {
    external_id    = "7093ad00-d913-443f-b269-4fe77cdac250"
    sns_caller_arn = aws_iam_role.main.arn
    sns_region     = var.region
  }
  software_token_mfa_configuration {
    enabled = true
  }
  account_recovery_setting {
    recovery_mechanism {
      name     = "verified_email"
      priority = 1
    }
    recovery_mechanism {
      name     = "verified_phone_number"
      priority = 2
    }
  }
  password_policy {
    minimum_length                   = 8
    require_lowercase                = true
    require_numbers                  = true
    require_symbols                  = true
    require_uppercase                = true
    temporary_password_validity_days = 7
  }
  email_configuration {
    email_sending_account = "COGNITO_DEFAULT"
  }
}

# resource "aws_cognito_identity_provider" "main" {
#   for_each = {
#     "Google" : {
#       "authorize_scopes" : "email",
#       "client_id" : each.value.client_id,
#       "client_secret" : each.value.client_secret,

#     },
#     "Facebook" : {
#       "authorize_scopes" : "email",
#       "client_id" : each.value.client_id,
#       "client_secret" : each.value.client_secret,
#       "api_version" : "",
#     },
#     "SAML" : {
#       "MetadataFile" : "",
#       # "MetadataURL": 
#       # "IDPSignout": 
#     },
#     "ODIC" : {
#       "client_id" : "",
#       "client_secret" : "",
#       "attributes_request_method" : "",
#       "oidc_issuer" : "",
#       "authorize_scopes" : "",
#       # authorize_url
#       # token_url
#       # attributes_url
#       # jwks_uri
#     },
#   }
#   user_pool_id     = aws_cognito_user_pool.main.id
#   provider_name    = each.key
#   provider_type    = each.key
#   provider_details = each.value
#   attribute_mapping = {
#     email    = "email"
#     username = "sub"
#   }
# }
