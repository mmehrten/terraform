  Demo using MSK Connect with Debezium to replicate RDS data into MSK Serverless topics.

## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | >= 5.19.0 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | >= 5.19.0 |

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_internet-gateway"></a> [internet-gateway](#module\_internet-gateway) | ../terraform-main/aws/modules/internet-gateway | n/a |
| <a name="module_msk-serverless"></a> [msk-serverless](#module\_msk-serverless) | ../terraform-main/aws/modules/msk-serverless | n/a |
| <a name="module_nat-gateway"></a> [nat-gateway](#module\_nat-gateway) | ../terraform-main/aws/modules/nat-gateway | n/a |
| <a name="module_rds"></a> [rds](#module\_rds) | ../terraform-main/aws/modules/rds-postgresql | n/a |
| <a name="module_vpc"></a> [vpc](#module\_vpc) | ../terraform-main/aws/modules/vpc | n/a |

## Resources

| Name | Type |
|------|------|
| [aws_cloudwatch_log_group.main](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_log_group) | resource |
| [aws_mskconnect_connector.main](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/mskconnect_connector) | resource |
| [aws_mskconnect_custom_plugin.main](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/mskconnect_custom_plugin) | resource |
| [aws_mskconnect_worker_configuration.main](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/mskconnect_worker_configuration) | resource |
| [aws_s3_object.main](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_object) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_account-id"></a> [account-id](#input\_account-id) | The account to create resources in. | `string` | n/a | yes |
| <a name="input_app-name"></a> [app-name](#input\_app-name) | The longhand name of the app being provisioned. | `string` | n/a | yes |
| <a name="input_app-shorthand-name"></a> [app-shorthand-name](#input\_app-shorthand-name) | The shorthand name of the app being provisioned. | `string` | n/a | yes |
| <a name="input_cidr-block"></a> [cidr-block](#input\_cidr-block) | The root CIDR block for the VPC | `string` | n/a | yes |
| <a name="input_partition"></a> [partition](#input\_partition) | The partition to create resources in. | `string` | `"aws"` | no |
| <a name="input_plugin-s3-bucket-name"></a> [plugin-s3-bucket-name](#input\_plugin-s3-bucket-name) | S3 bucket to store connector plugins | `string` | n/a | yes |
| <a name="input_private-subnets"></a> [private-subnets](#input\_private-subnets) | A mapping of Availability Zone to the CIDR block for the subnet in that AZ. | `map(string)` | n/a | yes |
| <a name="input_public-subnets"></a> [public-subnets](#input\_public-subnets) | A mapping of Availability Zone to the CIDR block for the subnet in that AZ. | `map(string)` | n/a | yes |
| <a name="input_rds-master-password"></a> [rds-master-password](#input\_rds-master-password) | n/a | `string` | n/a | yes |
| <a name="input_region"></a> [region](#input\_region) | The region to create resources in. | `string` | `"us-east-1"` | no |
| <a name="input_tags"></a> [tags](#input\_tags) | Tags to apply to all resources. | `map(string)` | n/a | yes |
| <a name="input_terraform-role"></a> [terraform-role](#input\_terraform-role) | The IAM role ARN to execute terraform with. | `string` | n/a | yes |

## Outputs

No outputs.
