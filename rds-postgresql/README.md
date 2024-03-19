  Create an RDS database with AWS Backup configured.

## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | >= 5.19.0 |
| <a name="requirement_opensearch"></a> [opensearch](#requirement\_opensearch) | >= 2.0.0 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | 5.29.0 |

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_rds"></a> [rds](#module\_rds) | ../terraform-main/aws/modules/rds-postgresql | n/a |

## Resources

| Name | Type |
|------|------|
| [aws_backup_plan.main](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/backup_plan) | resource |
| [aws_backup_selection.main](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/backup_selection) | resource |
| [aws_backup_vault.main](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/backup_vault) | resource |
| [aws_backup_vault_lock_configuration.test](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/backup_vault_lock_configuration) | resource |
| [aws_iam_role.main](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_iam_role_policy_attachment.main](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [aws_iam_policy_document.assume](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_account-id"></a> [account-id](#input\_account-id) | The account to create resources in. | `string` | n/a | yes |
| <a name="input_app-name"></a> [app-name](#input\_app-name) | The longhand name of the app being provisioned. | `string` | n/a | yes |
| <a name="input_app-shorthand-name"></a> [app-shorthand-name](#input\_app-shorthand-name) | The shorthand name of the app being provisioned. | `string` | n/a | yes |
| <a name="input_database-name"></a> [database-name](#input\_database-name) | n/a | `string` | `"demo"` | no |
| <a name="input_partition"></a> [partition](#input\_partition) | The partition to create resources in. | `string` | `"aws"` | no |
| <a name="input_rds-master-password"></a> [rds-master-password](#input\_rds-master-password) | The master password to use for the RDS user | `string` | n/a | yes |
| <a name="input_region"></a> [region](#input\_region) | The region to create resources in. | `string` | `"us-east-1"` | no |
| <a name="input_tags"></a> [tags](#input\_tags) | Tags to apply to all resources. | `map(string)` | n/a | yes |
| <a name="input_terraform-role"></a> [terraform-role](#input\_terraform-role) | The IAM role ARN to execute terraform with. | `string` | n/a | yes |
| <a name="input_vpc-id"></a> [vpc-id](#input\_vpc-id) | n/a | `string` | `true` | no |

## Outputs

No outputs.
