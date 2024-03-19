  Create an MSK Connect connector that accesses a cross-account MSK cluster using IAM authentication.

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
| <a name="module_internet-gateway"></a> [internet-gateway](#module\_internet-gateway) | ../../terraform-main/aws/modules/internet-gateway | n/a |
| <a name="module_nat-gateway"></a> [nat-gateway](#module\_nat-gateway) | ../../terraform-main/aws/modules/nat-gateway | n/a |
| <a name="module_rds"></a> [rds](#module\_rds) | ../../terraform-main/aws/modules/rds-postgresql | n/a |
| <a name="module_vpc"></a> [vpc](#module\_vpc) | ../../terraform-main/aws/modules/vpc | n/a |

## Resources

| Name | Type |
|------|------|
| [aws_cloudwatch_log_group.main](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_log_group) | resource |
| [aws_iam_role.main](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_msk_vpc_connection.iam](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/msk_vpc_connection) | resource |
| [aws_msk_vpc_connection.scram](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/msk_vpc_connection) | resource |
| [aws_msk_vpc_connection.tls](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/msk_vpc_connection) | resource |
| [aws_mskconnect_connector.main](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/mskconnect_connector) | resource |
| [aws_mskconnect_custom_plugin.main](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/mskconnect_custom_plugin) | resource |
| [aws_mskconnect_worker_configuration.main](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/mskconnect_worker_configuration) | resource |
| [aws_route53_record.main](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route53_record) | resource |
| [aws_route53_zone.main](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route53_zone) | resource |
| [aws_s3_object.main](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_object) | resource |
| [aws_security_group.main](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group) | resource |
| [aws_vpc_endpoint.main](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/vpc_endpoint) | resource |
| [aws_network_interface.interface_ips](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/network_interface) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_account-id"></a> [account-id](#input\_account-id) | The account to create resources in. | `string` | n/a | yes |
| <a name="input_app-name"></a> [app-name](#input\_app-name) | The longhand name of the app being provisioned. | `string` | n/a | yes |
| <a name="input_app-shorthand-name"></a> [app-shorthand-name](#input\_app-shorthand-name) | The shorthand name of the app being provisioned. | `string` | n/a | yes |
| <a name="input_broker-dns"></a> [broker-dns](#input\_broker-dns) | The broker DNS name (not including b-# prefix) | `string` | n/a | yes |
| <a name="input_broker-endpoint-service-map"></a> [broker-endpoint-service-map](#input\_broker-endpoint-service-map) | Mapping of AZ to the VPC endpoint service info for the AZ | `map(map(string))` | n/a | yes |
| <a name="input_cidr-block"></a> [cidr-block](#input\_cidr-block) | The root CIDR block for the VPC | `string` | n/a | yes |
| <a name="input_cluster-name"></a> [cluster-name](#input\_cluster-name) | Cluster name | `string` | n/a | yes |
| <a name="input_msk-cluster-arn"></a> [msk-cluster-arn](#input\_msk-cluster-arn) | MSK couster in another account / VPC to connect to privately | `string` | n/a | yes |
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
