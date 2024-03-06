variable "partition" {
  description = "The AWS partition to use"
  type        = string
  default     = "aws"
}

variable "region" {
  type        = string
  description = "The region to create resources in."
  default     = "us-east-1"
}

variable "tags" {
  type        = map(string)
  description = "Tags to apply to all resources."
  default     = {}
}

variable "vpc_id" {
  description = "The VPC to deploy DataPrepper in"
  type        = string
}

variable "service_prefix" {
  description = "The prefix to use for the service name"
  type        = string
}

variable "opensearch_arn" {
  description = "The ARN of the OpenSearch cluster"
  type        = string
}

variable "kms_key_arn" {
  description = "The ARN of the KMS key for S3"
  type        = string
}

variable "pipeline_config_bucket_name" {
  description = "The name of the S3 bucket where DataPrepper pipeline yaml is stored"
  type        = string
}

variable "queue_prefix" {
  description = "The prefix to put in front of SQS queue names"
  type        = string
}

variable "logs_s3_bucket_arn" {
  description = "The ARN of the S3 bucket to configure notifications for"
  type        = string
}

variable "logs_s3_bucket_prefixes" {
  description = "A list of S3 bucket prefixes to create notifications for"
  type        = list(string)
}
