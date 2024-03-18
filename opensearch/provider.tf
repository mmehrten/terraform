provider "aws" {
  region = var.region
  # assume_role { role_arn = var.terraform-role }
  default_tags { tags = var.tags }
}

provider "aws" {
  alias  = "remote"
  region = var.remote-region
  # assume_role { role_arn = var.terraform-role }
  default_tags { tags = var.tags }
}
