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
variable "commercial-secret-key" {
  type        = string
  description = "The secret access key for the user in the commercial region"
}
variable "commercial-access-key" {
  type        = string
  description = "The access key ID for the user in the commercial region"
}
variable "commercial-region" {
  type        = string
  description = "The commercial region to connect to"
}
