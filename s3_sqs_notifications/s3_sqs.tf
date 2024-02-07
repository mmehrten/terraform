
variable "queue_prefix" {
  description = "The prefix to put in front of SQS queue names"
  type        = string
}

variable "s3_bucket_arn" {
  description = "The ARN of the S3 bucket to configure notifications for"
  type        = string
}

variable "s3_bucket_prefixes" {
  description = "A list of S3 bucket prefixes to create notifications for"
  type        = list(string)
}

data "aws_iam_policy_document" "queue_policy" {
  for_each = { for o in var.s3_bucket_prefixes : o => o }
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
      values   = [var.s3_bucket_arn]
    }
  }
}
resource "aws_sqs_queue" "queue" {
  for_each = { for o in var.s3_bucket_prefixes : o => o }
  name     = "${var.queue_prefix}-${trim(replace(each.value, "/", "-"), "-")}"
  policy   = data.aws_iam_policy_document.queue_policy[each.key].json
}

resource "aws_s3_bucket_notification" "bucket_notification" {
  bucket = split(":", var.s3_bucket_arn)[5]

  dynamic "queue" {
    for_each = { for o in var.s3_bucket_prefixes : o => o }
    content {
      queue_arn     = aws_sqs_queue.queue[queue.key].arn
      events        = ["s3:ObjectCreated:*"]
      filter_prefix = queue.value
    }
  }
}


