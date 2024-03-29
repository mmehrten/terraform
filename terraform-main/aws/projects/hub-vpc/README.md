  Create hub VPC with VPC endpoints and an internet gateway, to be used as a transit hub for other VPCs.

## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | = 4.44.0 |

## Providers

No providers.

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_kinesis"></a> [kinesis](#module\_kinesis) | ../../modules/kinesis-stream | n/a |
| <a name="module_redshift"></a> [redshift](#module\_redshift) | ../../modules/redshift | n/a |
| <a name="module_s3-data"></a> [s3-data](#module\_s3-data) | ../../modules/s3 | n/a |
| <a name="module_s3-infra"></a> [s3-infra](#module\_s3-infra) | ../../modules/s3 | n/a |
| <a name="module_s3-logs"></a> [s3-logs](#module\_s3-logs) | ../../modules/s3 | n/a |
| <a name="module_terraform"></a> [terraform](#module\_terraform) | ../../modules/terraform-infra | n/a |
| <a name="module_vpc"></a> [vpc](#module\_vpc) | ../../modules/vpc | n/a |
| <a name="module_vpc-endpoints"></a> [vpc-endpoints](#module\_vpc-endpoints) | ../../modules/vpc-endpoints | n/a |

## Resources

No resources.

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_account-id"></a> [account-id](#input\_account-id) | The account to create resources in. | `string` | n/a | yes |
| <a name="input_app-name"></a> [app-name](#input\_app-name) | The longhand name of the app being provisioned. | `string` | n/a | yes |
| <a name="input_app-shorthand-name"></a> [app-shorthand-name](#input\_app-shorthand-name) | The shorthand name of the app being provisioned. | `string` | n/a | yes |
| <a name="input_cidr-block"></a> [cidr-block](#input\_cidr-block) | The root CIDR block for the VPC | `string` | n/a | yes |
| <a name="input_partition"></a> [partition](#input\_partition) | The partition to create resources in. | `string` | `"aws"` | no |
| <a name="input_pgp-key"></a> [pgp-key](#input\_pgp-key) | Optional PGP key if creating a console user | `string` | `""` | no |
| <a name="input_private-subnets"></a> [private-subnets](#input\_private-subnets) | A mapping of Availability Zone to the CIDR block for the subnet in that AZ. | `map(string)` | n/a | yes |
| <a name="input_public-subnets"></a> [public-subnets](#input\_public-subnets) | A mapping of Availability Zone to the CIDR block for the subnet in that AZ. | `map(string)` | n/a | yes |
| <a name="input_redshift-master-password"></a> [redshift-master-password](#input\_redshift-master-password) | The master password for the Redshift admin user | `string` | n/a | yes |
| <a name="input_region"></a> [region](#input\_region) | The region to create resources in. | `string` | `"us-east-1"` | no |
| <a name="input_tags"></a> [tags](#input\_tags) | Tags to apply to all resources. | `map(string)` | n/a | yes |
| <a name="input_terraform-role"></a> [terraform-role](#input\_terraform-role) | The IAM role ARN to execute terraform with. | `string` | n/a | yes |

## Outputs

No outputs.
