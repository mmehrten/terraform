terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "= 4.44.0"
    }
  }
  # backend "s3" {
  #   bucket         = "core-zwy2.us-gov-west-1.s3.terraform"
  #   key            = "core-zwy2/state/prod.tfstate"
  #   region         = "us-gov-west-1"
  #   dynamodb_table = "core-zwy2.us-gov-west-1.dynamodb.terraform"
  # }
}
