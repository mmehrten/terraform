/*
*   Create a root organization with CloudTrail and Config service principals, and all features enabled.
*/
resource "aws_organizations_organization" "main" {
  aws_service_access_principals = [
    "cloudtrail.amazonaws.com",
    "config.amazonaws.com",
  ]
  feature_set = "ALL"
}

resource "aws_s3_bucket_policy" "main" {
  bucket = var.logs-bucket
  policy = jsonencode(
    {
      "Version" : "2012-10-17",
      "Statement" : [
        {
          "Effect" : "Allow",
          "Principal" : {
            "Service" : "cloudtrail.amazonaws.com"
          },
          "Action" : "s3:GetBucketAcl",
          "Resource" : "arn:${var.partition}:s3:::${var.logs-bucket}",
          "Condition" : {
            "StringEquals" : {
              "AWS:SourceArn" : "arn:${var.partition}:cloudtrail:${var.region}:${var.account-id}:trail/${var.base-name}.cloudtrail.organization"
            }
          }
        },
        {
          "Effect" : "Allow",
          "Principal" : {
            "Service" : "cloudtrail.amazonaws.com"
          },
          "Action" : "s3:PutObject",
          "Resource" : "arn:${var.partition}:s3:::${var.logs-bucket}/*",
          "Condition" : {
            "StringEquals" : {
              "s3:x-amz-acl" : "bucket-owner-full-control",
              "AWS:SourceArn" : "arn:${var.partition}:cloudtrail:${var.region}:${var.account-id}:trail/${var.base-name}.cloudtrail.organization"
            }
          }
        },
        {
          "Effect" : "Allow",
          "Principal" : {
            "Service" : "config.amazonaws.com"
          },
          "Action" : "s3:PutObject",
          "Resource" : "arn:${var.partition}:s3:::${var.logs-bucket}/*",
          "Condition" : {
            "StringEquals" : {
              "s3:x-amz-acl" : "bucket-owner-full-control",
              "AWS:SourceArn" : "arn:${var.partition}:cloudtrail:${var.region}:${var.account-id}:trail/${var.base-name}.cloudtrail.organization"
            }
          }
        }
      ]
    }
  )
}

resource "aws_config_config_rule" "main" {
  for_each = {
    "ACCESS_KEYS_ROTATED" : jsonencode({ "maxAccessKeyAge" : "30" }),
    "CLOUD_TRAIL_CLOUD_WATCH_LOGS_ENABLED" : "",
    "CLOUD_TRAIL_ENCRYPTION_ENABLED" : "",
    "CLOUD_TRAIL_ENABLED" : "",
    "CLOUDWATCH_LOG_GROUP_ENCRYPTED" : "",
    "IAM_ROOT_ACCESS_KEY_CHECK" : "",
  }
  name             = each.key
  input_parameters = each.value

  source {
    owner             = "AWS"
    source_identifier = each.key
  }
}

resource "aws_cloudtrail" "main" {
  name                          = "${var.base-name}.cloudtrail.organization"
  s3_bucket_name                = var.logs-bucket
  s3_key_prefix                 = "cloudtrail"
  include_global_service_events = true
  is_multi_region_trail         = true
  is_organization_trail         = true
}
