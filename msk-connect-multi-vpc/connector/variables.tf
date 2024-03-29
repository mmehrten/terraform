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
variable "rds-master-password" {
  type        = string
  description = ""
}
variable "cidr-block" {
  type        = string
  description = "The root CIDR block for the VPC"
}
variable "public-subnets" {
  type        = map(string)
  description = "A mapping of Availability Zone to the CIDR block for the subnet in that AZ."
}
variable "private-subnets" {
  type        = map(string)
  description = "A mapping of Availability Zone to the CIDR block for the subnet in that AZ."
}
variable "plugin-s3-bucket-name" {
  type        = string
  description = "S3 bucket to store connector plugins"
}
variable "msk-cluster-arn" {
  type        = string
  description = "MSK couster in another account / VPC to connect to privately"
}
variable "cluster-name" {
  type        = string
  description = "Cluster name"
}
variable "broker-endpoint-service-map" {
  type        = map(map(string))
  description = "Mapping of AZ to the VPC endpoint service info for the AZ"
}
variable "broker-dns" {
  type        = string
  description = "The broker DNS name (not including b-# prefix)"
}
