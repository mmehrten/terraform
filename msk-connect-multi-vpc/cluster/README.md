  Create an MSK cluster to be accessed between accounts using VPC Endpoints.

## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | >= 5.19.0 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | 5.39.1 |

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_acm"></a> [acm](#module\_acm) | ../../terraform-main/aws/modules/acm | n/a |
| <a name="module_internet-gateway"></a> [internet-gateway](#module\_internet-gateway) | ../../terraform-main/aws/modules/internet-gateway | n/a |
| <a name="module_msk"></a> [msk](#module\_msk) | ../../terraform-main/aws/modules/msk | n/a |
| <a name="module_nat-gateway"></a> [nat-gateway](#module\_nat-gateway) | ../../terraform-main/aws/modules/nat-gateway | n/a |
| <a name="module_pca"></a> [pca](#module\_pca) | ../../terraform-main/aws/modules/pca | n/a |
| <a name="module_vpc"></a> [vpc](#module\_vpc) | ../../terraform-main/aws/modules/vpc | n/a |

## Resources

| Name | Type |
|------|------|
| [aws_msk_cluster_policy.main](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/msk_cluster_policy) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_account-id"></a> [account-id](#input\_account-id) | The account to create resources in. | `string` | n/a | yes |
| <a name="input_app-name"></a> [app-name](#input\_app-name) | The longhand name of the app being provisioned. | `string` | n/a | yes |
| <a name="input_app-shorthand-name"></a> [app-shorthand-name](#input\_app-shorthand-name) | The shorthand name of the app being provisioned. | `string` | n/a | yes |
| <a name="input_cidr-block"></a> [cidr-block](#input\_cidr-block) | The root CIDR block for the VPC | `string` | n/a | yes |
| <a name="input_partition"></a> [partition](#input\_partition) | The partition to create resources in. | `string` | `"aws"` | no |
| <a name="input_private-subnets"></a> [private-subnets](#input\_private-subnets) | A mapping of Availability Zone to the CIDR block for the subnet in that AZ. | `map(string)` | n/a | yes |
| <a name="input_public-subnets"></a> [public-subnets](#input\_public-subnets) | A mapping of Availability Zone to the CIDR block for the subnet in that AZ. | `map(string)` | n/a | yes |
| <a name="input_region"></a> [region](#input\_region) | The region to create resources in. | `string` | `"us-east-1"` | no |
| <a name="input_shared-account-id"></a> [shared-account-id](#input\_shared-account-id) | Account to share connectivity with | `string` | n/a | yes |
| <a name="input_tags"></a> [tags](#input\_tags) | Tags to apply to all resources. | `map(string)` | n/a | yes |
| <a name="input_terraform-role"></a> [terraform-role](#input\_terraform-role) | The IAM role ARN to execute terraform with. | `string` | n/a | yes |

## Outputs

No outputs.
