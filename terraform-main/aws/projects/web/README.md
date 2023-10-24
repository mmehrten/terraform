  Create hub VPC with VPC endpoints and an internet gateway, to be used as a transit hub for other VPCs.

## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | = 4.44.0 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | = 4.44.0 |

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_cognito"></a> [cognito](#module\_cognito) | ../../../terraform-main/aws/modules/cognito | n/a |
| <a name="module_ddb"></a> [ddb](#module\_ddb) | ../../../terraform-main/aws/modules/dynamodb | n/a |
| <a name="module_lambda"></a> [lambda](#module\_lambda) | ../../../terraform-main/aws/modules/lambda | n/a |
| <a name="module_s3-web"></a> [s3-web](#module\_s3-web) | ../../../terraform-main/aws/modules/s3 | n/a |

## Resources

| Name | Type |
|------|------|
| [aws_security_group.main](https://registry.terraform.io/providers/hashicorp/aws/4.44.0/docs/resources/security_group) | resource |
| [aws_subnet_ids.main](https://registry.terraform.io/providers/hashicorp/aws/4.44.0/docs/data-sources/subnet_ids) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_account-id"></a> [account-id](#input\_account-id) | The account to create resources in. | `string` | n/a | yes |
| <a name="input_app-name"></a> [app-name](#input\_app-name) | The longhand name of the app being provisioned. | `string` | n/a | yes |
| <a name="input_app-shorthand-name"></a> [app-shorthand-name](#input\_app-shorthand-name) | The shorthand name of the app being provisioned. | `string` | n/a | yes |
| <a name="input_partition"></a> [partition](#input\_partition) | The partition to create resources in. | `string` | `"aws"` | no |
| <a name="input_region"></a> [region](#input\_region) | The region to create resources in. | `string` | `"us-east-1"` | no |
| <a name="input_tags"></a> [tags](#input\_tags) | Tags to apply to all resources. | `map(string)` | n/a | yes |
| <a name="input_terraform-role"></a> [terraform-role](#input\_terraform-role) | The IAM role ARN to execute terraform with. | `string` | n/a | yes |

## Outputs

No outputs.
