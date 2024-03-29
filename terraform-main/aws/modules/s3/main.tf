/*
* Create a private S3 bucket with a dedicated KMS key.
*/

resource "aws_kms_key" "encrypt-main" {
  count                   = var.use-cmk ? 1 : 0
  description             = "${var.bucket-name} KMS key."
  deletion_window_in_days = 30
  enable_key_rotation     = "true"
  tags = {
    "Name" = "${var.base-name}.kms.${var.bucket-name}"
  }
}

resource "aws_kms_alias" "alias" {
  count         = var.use-cmk ? 1 : 0
  name          = replace("alias/${var.base-name}.kms.${var.bucket-name}", ".", "_")
  target_key_id = aws_kms_key.encrypt-main[0].key_id
}

resource "aws_s3_bucket" "main" {
  bucket        = var.bucket-name
  force_destroy = true
}

resource "aws_s3_bucket_versioning" "main-versioning" {
  bucket = aws_s3_bucket.main.bucket
  versioning_configuration {
    status = var.versioning == null || var.versioning == false ? "Suspended" : "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "main-encryption" {
  bucket = aws_s3_bucket.main.bucket
  rule {
    bucket_key_enabled = true
    apply_server_side_encryption_by_default {
      sse_algorithm     = var.use-cmk ? "aws:kms" : "AES256"
      kms_master_key_id = var.use-cmk ? aws_kms_key.encrypt-main[0].arn : null
    }
  }
}

resource "aws_s3_bucket_public_access_block" "main-block" {
  bucket                  = aws_s3_bucket.main.bucket
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_lifecycle_configuration" "main-expire" {
  bucket = aws_s3_bucket.main.bucket
  rule {
    id     = "expire_after_${var.expiration-days}_days"
    status = "Enabled"
    expiration {
      days = var.expiration-days
    }
  }
}
