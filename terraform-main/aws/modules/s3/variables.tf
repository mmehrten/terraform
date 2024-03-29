variable "bucket-name" {
  description = "The name of the bucket to provision."
  type        = string
}
variable "versioning" {
  description = "Whether or not to enable bucket versioning."
  default     = false
  type        = bool
}
variable "expiration-days" {
  description = "Number of days to wait before cleaning up objects."
  default     = 0
  type        = number
}
variable "use-cmk" {
  description = "Whether or not to use a CMK for encryption vs. SSE-S3."
  default     = true
  type        = bool
}