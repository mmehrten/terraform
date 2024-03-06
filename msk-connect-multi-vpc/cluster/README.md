  Create an MSK cluster with Redshift cluster, and streaming ingestion with Avro and Glue Schema Registry using a NAT gateway or a Lambda function.

## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | >= 5.19.0 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | 5.19.0 |

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_avro-decode-lambda"></a> [avro-decode-lambda](#module\_avro-decode-lambda) | ../terraform-main/aws/modules/lambda | n/a |
| <a name="module_internet-gateway"></a> [internet-gateway](#module\_internet-gateway) | ../terraform-main/aws/modules/internet-gateway | n/a |
| <a name="module_kafka-consumer-lambda"></a> [kafka-consumer-lambda](#module\_kafka-consumer-lambda) | ../terraform-main/aws/modules/lambda | n/a |
| <a name="module_kafka-publisher-lambda"></a> [kafka-publisher-lambda](#module\_kafka-publisher-lambda) | ../terraform-main/aws/modules/lambda | n/a |
| <a name="module_msk"></a> [msk](#module\_msk) | ../terraform-main/aws/modules/msk | n/a |
| <a name="module_nat-gateway"></a> [nat-gateway](#module\_nat-gateway) | ../terraform-main/aws/modules/nat-gateway | n/a |
| <a name="module_redshift"></a> [redshift](#module\_redshift) | ../terraform-main/aws/modules/redshift | n/a |
| <a name="module_s3-data"></a> [s3-data](#module\_s3-data) | ../terraform-main/aws/modules/s3 | n/a |
| <a name="module_vpc"></a> [vpc](#module\_vpc) | ../terraform-main/aws/modules/vpc | n/a |
| <a name="module_vpc-endpoints"></a> [vpc-endpoints](#module\_vpc-endpoints) | ../terraform-main/aws/modules/vpc-endpoints | n/a |

## Resources

| Name | Type |
|------|------|
| [aws_cloudwatch_event_rule.publish](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_event_rule) | resource |
| [aws_cloudwatch_event_target.lambda](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_event_target) | resource |
| [aws_glue_registry.main](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/glue_registry) | resource |
| [aws_glue_schema.main](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/glue_schema) | resource |
| [aws_glue_schema.nested](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/glue_schema) | resource |
| [aws_lambda_event_source_mapping.main](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lambda_event_source_mapping) | resource |
| [aws_lambda_event_source_mapping.nested](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lambda_event_source_mapping) | resource |
| [aws_lambda_permission.allow_eventbridge](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lambda_permission) | resource |
| [aws_redshiftdata_statement.create-external](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/redshiftdata_statement) | resource |
| [aws_redshiftdata_statement.create-mv-main](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/redshiftdata_statement) | resource |
| [aws_redshiftdata_statement.create-mv-nested](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/redshiftdata_statement) | resource |
| [aws_redshiftdata_statement.create-udf](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/redshiftdata_statement) | resource |

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
| <a name="input_redshift-master-password"></a> [redshift-master-password](#input\_redshift-master-password) | n/a | `string` | n/a | yes |
| <a name="input_region"></a> [region](#input\_region) | The region to create resources in. | `string` | `"us-east-1"` | no |
| <a name="input_tags"></a> [tags](#input\_tags) | Tags to apply to all resources. | `map(string)` | n/a | yes |
| <a name="input_terraform-role"></a> [terraform-role](#input\_terraform-role) | The IAM role ARN to execute terraform with. | `string` | n/a | yes |
| <a name="input_use-nat-gateway"></a> [use-nat-gateway](#input\_use-nat-gateway) | n/a | `bool` | `true` | no |

## Outputs

No outputs.
