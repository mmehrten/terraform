variable "vpc-id" {
  type        = string
  description = "The VPC to create the gateway in."
}
variable "subnet-id" {
  type        = string
  description = "The subnet ID to associate the gateway to."
}
variable "route-table-id" {
  type        = string
  description = "The route table to associate the gateway to."
}
