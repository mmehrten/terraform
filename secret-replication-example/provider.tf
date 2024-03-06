provider "aws" {
  region = var.region
  # assume_role { role_arn = var.terraform-role }
  default_tags { tags = var.tags }
}

provider "aws" {
  alias  = "replica"
  region = var.replica-region
  # assume_role { role_arn = var.terraform-role }
  default_tags { tags = var.tags }
}
