variable "policy" {
  description = "The IAM role policy block for the execution role."
  type        = string
}

variable "name" {
  description = "The function name."
  type        = string
}


variable "timeout" {
  description = "The timeout in seconds."
  type        = number
  default = 30
}

variable "file-path" {
  description = "Path to the lambda function code."
  type        = string
}

variable "handler" {
  description = "The name of the handler method."
  type        = string
}


variable "runtime" {
  description = "The lambda runtime."
  type        = string
}
variable "environment" {
  description = "A mapping of environment variables."
  type        = map(string)
  default     = { "na" : "na" }
}
variable "subnet-ids" {
  description = "Subnets to run lambda in."
  type        = list(string)
  default     = []
}
variable "security-group-ids" {
  description = "Security groups to run lambda in."
  type        = list(string)
  default     = []
}
variable "layer_arns" {
  default = []
  type = list(string)
  description = "ARNs of Lambda layers to use"
}
variable "vpc-id" {
  description = "VPC ID for Lambda to run in."
  type        = string
  default = null
}