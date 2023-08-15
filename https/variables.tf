variable "account-id" {
  type        = string
  description = "The account to create resources in."
}
variable "app-shorthand-name" {
  type        = string
  description = "The shorthand name of the app being provisioned."
}
variable "app-name" {
  type        = string
  description = "The longhand name of the app being provisioned."
}
variable "vpc-id" {
  type        = string
  description = "The VPC to deploy in"
}
variable "acm-cert-arn" {
  type = string
  description = "The ARN of the ACM certificate to use for SSL"
}
variable "acm-cert-pass" {
  type = string
  description = "The password for the ACM certificate private key to use for SSL"
}
