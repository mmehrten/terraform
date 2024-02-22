
data "aws_iam_policy_document" "queue_policy" {
  for_each = { for o in var.logs_s3_bucket_prefixes : o => o }
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["s3.amazonaws.com"]
    }

    actions   = ["sqs:SendMessage"]
    resources = ["arn:${var.partition}:sqs:*:*:${var.queue_prefix}-${trim(replace(each.value, "/", "-"), "-")}"]

    condition {
      test     = "ArnLike"
      variable = "aws:SourceArn"
      values   = [var.logs_s3_bucket_arn]
    }
  }
}
resource "aws_sqs_queue" "queue" {
  for_each = { for o in var.logs_s3_bucket_prefixes : o => o }
  name     = "${var.queue_prefix}-${trim(replace(each.value, "/", "-"), "-")}"
  policy   = data.aws_iam_policy_document.queue_policy[each.key].json
}

resource "aws_s3_bucket_notification" "bucket_notification" {
  bucket = split(":", var.logs_s3_bucket_arn)[5]

  dynamic "queue" {
    for_each = { for o in var.logs_s3_bucket_prefixes : o => o }
    content {
      queue_arn     = aws_sqs_queue.queue[queue.key].arn
      events        = ["s3:ObjectCreated:*"]
      filter_prefix = queue.value
    }
  }
}


