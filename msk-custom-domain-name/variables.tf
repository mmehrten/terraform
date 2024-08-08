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
  description = "VPC ID to deploy into"
}
variable "scram-username" {
  type        = string
  description = "Username for user to create for SASL/SCRAM auth"
}
variable "scram-password" {
  type        = string
  description = "Password for user to create for SASL/SCRAM auth"
}
