locals {
  base-name    = "${var.app-shorthand-name}.${var.region}"
  replica-name = "${var.app-shorthand-name}.${var.replica-region}"
}

resource "aws_kms_key" "main" {
  count                   = var.use-cmk ? 1 : 0
  description             = "${local.base-name}.kms.secret"
  deletion_window_in_days = 7
  enable_key_rotation     = "true"
  tags = {
    "Name" = "${local.base-name}.kms.secret"
  }
}

resource "aws_kms_alias" "main-alias" {
  count         = var.use-cmk ? 1 : 0
  name          = replace("alias/${aws_kms_key.main[0].description}", ".", "_")
  target_key_id = aws_kms_key.main[0].key_id
}

resource "aws_kms_key" "replica" {
  provider                = aws.replica
  count                   = var.use-cmk ? 1 : 0
  description             = "${local.replica-name}.kms.secret"
  deletion_window_in_days = 7
  enable_key_rotation     = "true"
  tags = {
    "Name" = "${local.replica-name}.kms.secret"
  }
}

resource "aws_kms_alias" "replica-alias" {
  provider      = aws.replica
  count         = var.use-cmk ? 1 : 0
  name          = replace("alias/${aws_kms_key.replica[0].description}", ".", "_")
  target_key_id = aws_kms_key.replica[0].key_id
}

resource "aws_secretsmanager_secret" "main" {
  name        = "${local.base-name}.secret"
  description = "Demo secret for replication destroy testing"
  kms_key_id  = var.use-cmk ? aws_kms_key.main[0].key_id : null
  policy = jsonencode(
    {

      "Version" : "2012-10-17",
      "Statement" : [
        {
          "Effect" : "Deny",
          "Action" : [
            "secretsmanager:GetSecretValue"
          ],
          "Principal" : "*",
          "Resource" : "*",
          "Condition" : { "ArnNotLike" : { "aws:PrincipalArn" : ["arn:${var.partition}:iam::${var.account-id}:role/Admin", "arn:${var.partition}:iam::${var.account-id}:root"] } }
        }
      ]
    }
  )
  recovery_window_in_days = 7
  replica {
    kms_key_id = var.use-cmk ? aws_kms_key.replica[0].key_id : null
    region     = var.replica-region
  }
  force_overwrite_replica_secret = true
}
