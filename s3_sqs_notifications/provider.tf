terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 4.44.0"
    }
  }
}

provider "aws" {
  region = var.region
  default_tags { tags = var.tags }
}
