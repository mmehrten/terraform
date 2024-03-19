  Create an OpenSearch cluster and assocaited infrastructure.

## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | >= 5.19.0 |
| <a name="requirement_opensearch"></a> [opensearch](#requirement\_opensearch) | >= 2.0.0 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | 5.29.0 |
| <a name="provider_aws.remote"></a> [aws.remote](#provider\_aws.remote) | 5.29.0 |

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_cloudwatch-parse-lambda"></a> [cloudwatch-parse-lambda](#module\_cloudwatch-parse-lambda) | ../terraform-main/aws/modules/lambda | n/a |
| <a name="module_opensearch"></a> [opensearch](#module\_opensearch) | ../terraform-main/aws/modules/opensearch | n/a |
| <a name="module_opensearch-remote"></a> [opensearch-remote](#module\_opensearch-remote) | ../terraform-main/aws/modules/opensearch | n/a |
| <a name="module_os-configure-lambda"></a> [os-configure-lambda](#module\_os-configure-lambda) | ../terraform-main/aws/modules/lambda | n/a |
| <a name="module_s3-data"></a> [s3-data](#module\_s3-data) | ../terraform-main/aws/modules/s3 | n/a |

## Resources

| Name | Type |
|------|------|
| [aws_iam_role.main](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_iam_role_policy.admin-snap](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy) | resource |
| [aws_iam_role_policy.main](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy) | resource |
| [aws_opensearch_inbound_connection_accepter.main](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/opensearch_inbound_connection_accepter) | resource |
| [aws_opensearch_outbound_connection.main](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/opensearch_outbound_connection) | resource |
| [aws_subnets.main](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/subnets) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_account-id"></a> [account-id](#input\_account-id) | The account to create resources in. | `string` | n/a | yes |
| <a name="input_app-name"></a> [app-name](#input\_app-name) | The longhand name of the app being provisioned. | `string` | n/a | yes |
| <a name="input_app-shorthand-name"></a> [app-shorthand-name](#input\_app-shorthand-name) | The shorthand name of the app being provisioned. | `string` | n/a | yes |
| <a name="input_cluster-id"></a> [cluster-id](#input\_cluster-id) | n/a | `string` | `"demo"` | no |
| <a name="input_opensearch-master-password"></a> [opensearch-master-password](#input\_opensearch-master-password) | The master password to use for the OpenSearch user - if empty IAM role will be created | `string` | `null` | no |
| <a name="input_partition"></a> [partition](#input\_partition) | The partition to create resources in. | `string` | `"aws"` | no |
| <a name="input_region"></a> [region](#input\_region) | The region to create resources in. | `string` | `"us-east-1"` | no |
| <a name="input_remote-region"></a> [remote-region](#input\_remote-region) | Remote region to connect to. | `string` | n/a | yes |
| <a name="input_remote-vpc-id"></a> [remote-vpc-id](#input\_remote-vpc-id) | n/a | `string` | `""` | no |
| <a name="input_tags"></a> [tags](#input\_tags) | Tags to apply to all resources. | `map(string)` | n/a | yes |
| <a name="input_terraform-role"></a> [terraform-role](#input\_terraform-role) | The IAM role ARN to execute terraform with. | `string` | n/a | yes |
| <a name="input_use-cross-region"></a> [use-cross-region](#input\_use-cross-region) | Whether or not to create a cross-region cluster | `bool` | `false` | no |
| <a name="input_vpc-id"></a> [vpc-id](#input\_vpc-id) | n/a | `string` | n/a | yes |

## Outputs

No outputs.
