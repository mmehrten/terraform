variable "cidr-block" {
  type        = string
  description = "The CIDR block for the subnets"
}
variable "subnets" {
  type        = map(string)
  description = "A mapping of Availability Zone to the CIDR block for the subnet in that AZ."
}
variable "vpc-id" {
  type        = string
  description = "The VPC to associate with."
}

