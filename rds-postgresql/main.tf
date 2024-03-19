/*
*   Create an RDS database with AWS Backup configured.
*/
locals {
  base-name = "${var.app-shorthand-name}.${var.region}"
}


module "rds" {
  region             = var.region
  account-id         = var.account-id
  app-shorthand-name = var.app-shorthand-name
  app-name           = var.app-name
  terraform-role     = var.terraform-role
  tags               = var.tags
  base-name          = local.base-name
  partition          = var.partition

  vpc-id          = var.vpc-id
  database-name   = var.database-name
  master-password = var.rds-master-password
  source          = "../terraform-main/aws/modules/rds-postgresql"
}

resource "aws_backup_vault" "main" {
  name        = replace("${local.base-name}.backup.vault", ".", "-")
  kms_key_arn = module.rds.kms_arn
}

resource "aws_backup_vault_lock_configuration" "test" {
  backup_vault_name = aws_backup_vault.main.name
  # changeable_for_days = 3
  max_retention_days = 150
  min_retention_days = 7
}

resource "aws_backup_plan" "main" {
  name = "${local.base-name}.backup.plan"

  rule {
    rule_name         = "${local.base-name}.backup.rule"
    target_vault_name = aws_backup_vault.main.name
    schedule          = "cron(0 12 * * ? *)"

    lifecycle {
      cold_storage_after = 10
      delete_after       = 100
    }
  }
}

data "aws_iam_policy_document" "assume" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["backup.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }
}
resource "aws_iam_role" "main" {
  name               = "${local.base-name}.iam.backup"
  assume_role_policy = data.aws_iam_policy_document.assume.json
}

resource "aws_iam_role_policy_attachment" "main" {
  policy_arn = "arn:${var.partition}:iam::aws:policy/service-role/AWSBackupServiceRolePolicyForBackup"
  role       = aws_iam_role.main.name
}

resource "aws_backup_selection" "main" {
  iam_role_arn = aws_iam_role.main.arn
  name         = "${local.base-name}.backup.selection"
  plan_id      = aws_backup_plan.main.id

  resources = [
    module.rds.arn
  ]
}
