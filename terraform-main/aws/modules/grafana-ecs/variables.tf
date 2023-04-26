variable "vpc-id" {
  description = "The name of the bucket to provision."
  type        = string
}
variable "subnet-ids" {
  description = "The name of the bucket to provision."
  type        = list(string)
}
variable "cluster-id" {
  description = "The ECS cluster ID."
  type = string  
}
variable "service-discovery-namespace-id" {
  description = "The service discovery namespace to register to"
  type        = string
}
