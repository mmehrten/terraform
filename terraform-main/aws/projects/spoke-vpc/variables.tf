variable "root-account-id" {
    type = string
    description = "The account ID of the root (hub networking) account."
}
variable "root-region" {
    type = string
    description = "The region where the root transit gateway is deployed."
}
variable "app-name" {
    type = string
    description = "The name of the spoke app to deploy."
}
variable "app-shorthand-name" {
    type = string
    description = "The shorthand name to use in resource naming."
}
variable "owner-email" {
    type = string
    description = "The email for the spoke account owner, required if creat-account is true."
    default = ""
}
variable create-account {
    type = bool
    description = "Whether or not to create a child account for the spoke VPC."
    default = false
}