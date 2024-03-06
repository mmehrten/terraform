variable "account-id" {
  type        = string
  description = "The account to create resources in."
}
variable "app-shorthand-name" {
  type        = string
  description = "The shorthand name of the app being provisioned."
}
variable "replica-region" {
  type        = string
  description = "Region to replicate a secret to"
}
variable "use-cmk" {
  type        = bool
  description = "Whether or not to use a CMK to encrypt the secret"
}
