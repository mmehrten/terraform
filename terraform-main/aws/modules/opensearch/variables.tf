variable "domain-name" {
  description = "The OpenSearch domain name"
  default     = "dev"
  type        = string
}
variable "vpc-id" {
  description = "The VPC to create the cluster in"
  type        = string
}
variable "master-password" {
  description = "Master password to use, if not using IAM"
  type        = string
}
variable "domain-version" {
  description = "OpenSearch version to use"
  type        = string
  default     = "OpenSearch_2.11"
}
