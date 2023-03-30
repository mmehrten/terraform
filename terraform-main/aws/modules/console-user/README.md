## Usage

Generate a GPG key:
```
gpg --full-generate-key
```

Retrieve the GPG key base64:
```
gpg --export $EMAIL | base64
```

Add the module and outputs:
```
moddule "user" {
    region             = var.region
    account-id         = var.account-id
    app-shorthand-name = var.app-shorthand-name
    app-name           = var.app-name
    terraform-role     = var.terraform-role
    tags               = var.tags
    base-name          = local.base-name
    name    = "..."
    pgp-key = "..."
    source  = "../../terraform-main/aws/modules/console-user"
}

output "access-key-id" {
  value = module.user.secrets.access_key_id
}
output "secret-access-key" {
  value = module.user.secrets.secret_access_key
}
output "password" {
  value = module.user.secrets.console
}
```

Retrieve a secret value:
```
terraform output access-key-id
terraform output password | tr -d '"' | base64 --decode | gpg --decrypt
terraform output secret-access-key | tr -d '"' | base64 --decode | gpg --decrypt
```

## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | = 4.44.0 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | = 4.44.0 |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [aws_iam_access_key.main](https://registry.terraform.io/providers/hashicorp/aws/4.44.0/docs/resources/iam_access_key) | resource |
| [aws_iam_user.main](https://registry.terraform.io/providers/hashicorp/aws/4.44.0/docs/resources/iam_user) | resource |
| [aws_iam_user_login_profile.main](https://registry.terraform.io/providers/hashicorp/aws/4.44.0/docs/resources/iam_user_login_profile) | resource |
| [aws_iam_user_policy_attachment.main](https://registry.terraform.io/providers/hashicorp/aws/4.44.0/docs/resources/iam_user_policy_attachment) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_account-id"></a> [account-id](#input\_account-id) | The account to create resources in. | `string` | n/a | yes |
| <a name="input_app-name"></a> [app-name](#input\_app-name) | The longhand name of the app being provisioned. | `string` | n/a | yes |
| <a name="input_app-shorthand-name"></a> [app-shorthand-name](#input\_app-shorthand-name) | The shorthand name of the app being provisioned. | `string` | n/a | yes |
| <a name="input_base-name"></a> [base-name](#input\_base-name) | The base name to create new resources with (e.g. {app\_shorthand}.{region}). | `string` | n/a | yes |
| <a name="input_name"></a> [name](#input\_name) | Username | `string` | n/a | yes |
| <a name="input_org-shorthand-name"></a> [org-shorthand-name](#input\_org-shorthand-name) | The organization's descriptor, shorthand (e.g. Any Company -> ac) | `string` | `"ac"` | no |
| <a name="input_partition"></a> [partition](#input\_partition) | The partition to create resources in. | `string` | `"aws"` | no |
| <a name="input_pgp-key"></a> [pgp-key](#input\_pgp-key) | PGP key to use for user password encryption | `string` | n/a | yes |
| <a name="input_region"></a> [region](#input\_region) | The region to create resources in. | `string` | n/a | yes |
| <a name="input_tags"></a> [tags](#input\_tags) | Tags to apply to all resources. | `map(string)` | n/a | yes |
| <a name="input_terraform-role"></a> [terraform-role](#input\_terraform-role) | The role for Terraform to use, which dictates the account resources are created in. | `string` | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_secrets"></a> [secrets](#output\_secrets) | n/a |
