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
variable "opensearch-master-password" {
  type        = string
  description = "The master password to use for the OpenSearch user - if empty IAM role will be created"
  default     = null
}
variable "vpc-id" {
  type    = string
  default = true
}
variable "cluster-id" {
  default = "demo"
  type    = string
}