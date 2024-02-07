terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 4.44.0"
    }
  }
}

variable "partition" {
  description = "The AWS partition to use"
  type        = string
  default     = "aws"
}

variable "region" {
  type        = string
  description = "The region to create resources in."
  default     = "us-east-1"
}

variable "tags" {
  type        = map(string)
  description = "Tags to apply to all resources."
  default     = {}
}

provider "aws" {
  region = var.region
  default_tags { tags = var.tags }
}
