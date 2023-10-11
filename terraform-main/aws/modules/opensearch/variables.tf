variable "domain-name" {
  description = "The OpenSearch domain name"
  default     = "dev"
  type        = string
}
variable "vpc-id" {
  description = "The VPC to create the cluster in"
  type        = string
}
