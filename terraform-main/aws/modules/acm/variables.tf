variable "pca-arn" {
  type        = string
  description = "ARN of the AWS PCA for signing"
}

variable "domain-name" {
  type        = string
  description = "The domain for the certificate"
}
variable "subject-alternative-names" {
  type        = list(string)
  default     = []
  description = "The domain for the certificate"
}