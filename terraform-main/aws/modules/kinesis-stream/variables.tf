variable "name" {
  description = "The stream name."
  type        = string
}
variable "retention-period" {
  description = "The number of hours to retain data for"
  type        = number
  default     = 24
}
