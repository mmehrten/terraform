resource "aws_organizations_account" "main" {
  name            = var.account-name
  email           = var.account-owner
  create_govcloud = var.partition == "aws" ? false : true
}

output "outputs" {
  value = {
    "account-id"            = var.partition == "aws" ? aws_organizations_account.main.id : aws_organizations_account.main.govcloud_id,
    "commercial-account-id" = aws_organizations_account.main.id
  }
}
