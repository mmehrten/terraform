  Create a spoke VPC with only private subnets, that uses the hub VPC as a transit center.

## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | = 4.6.0 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws.root"></a> [aws.root](#provider\_aws.root) | 4.6.0 |

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_account"></a> [account](#module\_account) | ../../modules/organization-child | n/a |
| <a name="module_transit-gateway-attachment"></a> [transit-gateway-attachment](#module\_transit-gateway-attachment) | ../../modules/transit-gateway-attachment | n/a |
| <a name="module_vpc"></a> [vpc](#module\_vpc) | ../../modules/vpc | n/a |

## Resources

| Name | Type |
|------|------|
| [aws_ec2_transit_gateway.tgw](https://registry.terraform.io/providers/hashicorp/aws/4.6.0/docs/data-sources/ec2_transit_gateway) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_app-name"></a> [app-name](#input\_app-name) | The name of the spoke app to deploy. | `string` | n/a | yes |
| <a name="input_app-shorthand-name"></a> [app-shorthand-name](#input\_app-shorthand-name) | The shorthand name to use in resource naming. | `string` | n/a | yes |
| <a name="input_create-account"></a> [create-account](#input\_create-account) | Whether or not to create a child account for the spoke VPC. | `bool` | `false` | no |
| <a name="input_owner-email"></a> [owner-email](#input\_owner-email) | The email for the spoke account owner, required if creat-account is true. | `string` | `""` | no |
| <a name="input_region"></a> [region](#input\_region) | The region to deploy resources into. | `string` | `"us-east-1"` | no |
| <a name="input_root-account-id"></a> [root-account-id](#input\_root-account-id) | The account ID of the root (hub networking) account. | `string` | n/a | yes |
| <a name="input_root-region"></a> [root-region](#input\_root-region) | The region where the root transit gateway is deployed. | `string` | n/a | yes |

## Outputs

No outputs.
