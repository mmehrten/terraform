
variable "vpc-id" {
  description = "The VPC to create the cluster in"
  type        = string
}

variable "tls-certificate-arns" {
  description = "ARNs of the ACM certs to use for TLS"
  type = list(string)
  default = [ ]
}
