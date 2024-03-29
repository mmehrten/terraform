output "outputs" {
  value = {
    name    = aws_s3_bucket.main.bucket
    arn     = aws_s3_bucket.main.arn
    kms-arn = var.use-cmk ? aws_kms_key.encrypt-main[0].arn : null
  }
}