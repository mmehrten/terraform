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
variable "subnet-ids" {
  default        = {
  "us-gov-west-1a": "subnet-0838c0a690833fd5d",
	"us-gov-west-1b": "subnet-00b3db3f74902bc0a",
	"us-gov-west-1c": "subnet-093de3674c6f2c16e",
  }
  description = "The VPC to deploy in"
}
variable "route-table-ids" {
  default        = ["rtb-0d4537785b48e162e"]
  description = "The VPC to deploy in"
}