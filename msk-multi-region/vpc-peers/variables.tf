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
variable "vpc-ids" {
  type        = map(string)
  description = "The VPCs to peer for each region."
}
variable "broker-nodes" {
  type        = map(list(map(string)))
  description = "The list of broker node information (IP, AZ, and ID) from the cluster module for each region"
}
variable "broker-zones" {
  type        = map(string)
  description = "The broker zone names for the cluster for Route53"
}
