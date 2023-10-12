/*
* Create a Kinesis stream
*/

resource "aws_kms_key" "encrypt-main" {
  description             = "${var.name} KMS key."
  deletion_window_in_days = 30
  enable_key_rotation     = "true"
  tags = {
    "Name" = "${var.base-name}.kms.${var.name}"
  }
}

resource "aws_kms_alias" "alias" {
  name          = replace("alias/${var.base-name}.kms.${var.name}", ".", "_")
  target_key_id = aws_kms_key.encrypt-main.key_id
}

resource "aws_kinesis_stream" "main" {
  name             = var.name
  retention_period = var.retention-period
  encryption_type  = "KMS"
  kms_key_id       = aws_kms_key.encrypt-main.arn

  shard_level_metrics = [
    "IncomingBytes",
    "OutgoingBytes",
    "IncomingRecords",
    "OutgoingRecords",
  ]

  stream_mode_details {
    stream_mode = "ON_DEMAND"
  }
}