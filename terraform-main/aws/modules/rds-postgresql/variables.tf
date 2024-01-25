variable "database-name" {
  description = "The RDS database name"
  default     = "dev"
  type        = string
}
variable "vpc-id" {
  description = "The VPC to create the cluster in"
  type        = string
}
variable "master-password" {
  description = "The cluster admin user password"
  type        = string
}
