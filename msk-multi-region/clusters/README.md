  Create an MSK cluster to be accessed across regions via VPC peering or transit gateways using mTLS auth.

## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | >= 5.19.0 |

## Providers

No providers.

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_acm"></a> [acm](#module\_acm) | ../../terraform-main/aws/modules/acm | n/a |
| <a name="module_kafka-publisher-lambda"></a> [kafka-publisher-lambda](#module\_kafka-publisher-lambda) | ../../terraform-main/aws/modules/lambda | n/a |
| <a name="module_msk"></a> [msk](#module\_msk) | ../../terraform-main/aws/modules/msk | n/a |
| <a name="module_pca"></a> [pca](#module\_pca) | ../../terraform-main/aws/modules/pca | n/a |
| <a name="module_vpc"></a> [vpc](#module\_vpc) | ../../terraform-main/aws/modules/vpc | n/a |
| <a name="module_vpc-endpoints"></a> [vpc-endpoints](#module\_vpc-endpoints) | ../../terraform-main/aws/modules/vpc-endpoints | n/a |

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
| <a name="input_private-cert-passphrase"></a> [private-cert-passphrase](#input\_private-cert-passphrase) | The passphrase for the client certificate for MSK | `string` | n/a | yes |
| <a name="input_private-subnets"></a> [private-subnets](#input\_private-subnets) | A mapping of Availability Zone to the CIDR block for the subnet in that AZ. | `map(string)` | n/a | yes |
| <a name="input_public-subnets"></a> [public-subnets](#input\_public-subnets) | A mapping of Availability Zone to the CIDR block for the subnet in that AZ. | `map(string)` | n/a | yes |
| <a name="input_region"></a> [region](#input\_region) | The region to create resources in. | `string` | `"us-east-1"` | no |
| <a name="input_tags"></a> [tags](#input\_tags) | Tags to apply to all resources. | `map(string)` | n/a | yes |
| <a name="input_terraform-role"></a> [terraform-role](#input\_terraform-role) | The IAM role ARN to execute terraform with. | `string` | n/a | yes |

## Outputs

No outputs.
