  Create a spoke VPC with only private subnets, that uses the hub VPC as a transit center.

## Requirements

No requirements.

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | 4.44.0 |

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_account"></a> [account](#module\_account) | ../../modules/organization-child | n/a |
| <a name="module_child-terraform-role"></a> [child-terraform-role](#module\_child-terraform-role) | ../../modules/terraform-role | n/a |
| <a name="module_redshift"></a> [redshift](#module\_redshift) | ../../modules/redshift | n/a |
| <a name="module_s3-data"></a> [s3-data](#module\_s3-data) | ../../modules/s3 | n/a |
| <a name="module_transit-gateway-attachment"></a> [transit-gateway-attachment](#module\_transit-gateway-attachment) | ../../modules/transit-gateway-attachment | n/a |
| <a name="module_vpc"></a> [vpc](#module\_vpc) | ../../modules/vpc | n/a |

## Resources

| Name | Type |
|------|------|
| [aws_ec2_transit_gateway.tgw](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/ec2_transit_gateway) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_app-name"></a> [app-name](#input\_app-name) | The name of the spoke app to deploy. | `string` | n/a | yes |
| <a name="input_app-shorthand-name"></a> [app-shorthand-name](#input\_app-shorthand-name) | The shorthand name to use in resource naming. | `string` | n/a | yes |
| <a name="input_child-account-id"></a> [child-account-id](#input\_child-account-id) | The account ID of the child (spoke) account, if not creating an account. | `string` | `""` | no |
| <a name="input_cidr-block"></a> [cidr-block](#input\_cidr-block) | The root CIDR block for the VPC | `string` | n/a | yes |
| <a name="input_create-account"></a> [create-account](#input\_create-account) | Whether or not to create a child account for the spoke VPC. | `bool` | `false` | no |
| <a name="input_enable-transitgateway"></a> [enable-transitgateway](#input\_enable-transitgateway) | Whether or not to include a Transit Gateway | `bool` | `true` | no |
| <a name="input_owner-email"></a> [owner-email](#input\_owner-email) | The email for the spoke account owner, required if creat-account is true. | `string` | `""` | no |
| <a name="input_partition"></a> [partition](#input\_partition) | The partition to create resources in. | `string` | `"aws"` | no |
| <a name="input_pgp-key"></a> [pgp-key](#input\_pgp-key) | Optional PGP key if creating a console user | `string` | `""` | no |
| <a name="input_private-subnets"></a> [private-subnets](#input\_private-subnets) | A mapping of Availability Zone to the CIDR block for the subnet in that AZ. | `map(string)` | n/a | yes |
| <a name="input_public-subnets"></a> [public-subnets](#input\_public-subnets) | A mapping of Availability Zone to the CIDR block for the subnet in that AZ. | `map(string)` | n/a | yes |
| <a name="input_redshift-master-password"></a> [redshift-master-password](#input\_redshift-master-password) | The master password for the Redshift admin user | `string` | n/a | yes |
| <a name="input_region"></a> [region](#input\_region) | The region to create resources in. | `string` | `"us-east-1"` | no |
| <a name="input_root-account-id"></a> [root-account-id](#input\_root-account-id) | The account ID of the root (hub networking) account. | `string` | n/a | yes |
| <a name="input_root-region"></a> [root-region](#input\_root-region) | The region where the root transit gateway is deployed. | `string` | n/a | yes |
| <a name="input_tags"></a> [tags](#input\_tags) | Tags to apply to all resources. | `map(string)` | n/a | yes |
| <a name="input_terraform-role"></a> [terraform-role](#input\_terraform-role) | The IAM role ARN to execute terraform with. | `string` | n/a | yes |

## Outputs

No outputs.
