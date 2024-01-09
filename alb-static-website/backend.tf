terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.19.0"
    }
    opensearch = {
      source  = "opensearch-project/opensearch"
      version = ">= 2.0.0"
    }
  }
}
