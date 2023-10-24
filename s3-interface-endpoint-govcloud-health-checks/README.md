  Create lambda functions to run health checks on S3 interface endpoints.

## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | = 4.44.0 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | 4.44.0 |

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_health-check-lambda"></a> [health-check-lambda](#module\_health-check-lambda) | ../terraform-main/aws/modules/lambda | n/a |
| <a name="module_vpc-endpoints"></a> [vpc-endpoints](#module\_vpc-endpoints) | ../terraform-main/aws/modules/vpc-endpoints | n/a |

## Resources

| Name | Type |
|------|------|
| [aws_cloudwatch_event_rule.every5minutes](https://registry.terraform.io/providers/hashicorp/aws/4.44.0/docs/resources/cloudwatch_event_rule) | resource |
| [aws_cloudwatch_event_rule.main](https://registry.terraform.io/providers/hashicorp/aws/4.44.0/docs/resources/cloudwatch_event_rule) | resource |
| [aws_cloudwatch_event_target.lambda](https://registry.terraform.io/providers/hashicorp/aws/4.44.0/docs/resources/cloudwatch_event_target) | resource |
| [aws_cloudwatch_event_target.main](https://registry.terraform.io/providers/hashicorp/aws/4.44.0/docs/resources/cloudwatch_event_target) | resource |
| [aws_cloudwatch_metric_alarm.health-checks](https://registry.terraform.io/providers/hashicorp/aws/4.44.0/docs/resources/cloudwatch_metric_alarm) | resource |
| [aws_lambda_permission.allow_eventbridge](https://registry.terraform.io/providers/hashicorp/aws/4.44.0/docs/resources/lambda_permission) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_account-id"></a> [account-id](#input\_account-id) | The account to create resources in. | `string` | n/a | yes |
| <a name="input_app-name"></a> [app-name](#input\_app-name) | The longhand name of the app being provisioned. | `string` | n/a | yes |
| <a name="input_app-shorthand-name"></a> [app-shorthand-name](#input\_app-shorthand-name) | The shorthand name of the app being provisioned. | `string` | n/a | yes |
| <a name="input_partition"></a> [partition](#input\_partition) | The partition to create resources in. | `string` | `"aws"` | no |
| <a name="input_region"></a> [region](#input\_region) | The region to create resources in. | `string` | `"us-east-1"` | no |
| <a name="input_route-table-ids"></a> [route-table-ids](#input\_route-table-ids) | The VPC to deploy in | `list` | <pre>[<br>  "rtb-0d4537785b48e162e"<br>]</pre> | no |
| <a name="input_subnet-ids"></a> [subnet-ids](#input\_subnet-ids) | The VPC to deploy in | `map` | <pre>{<br>  "us-gov-west-1a": "subnet-0838c0a690833fd5d",<br>  "us-gov-west-1b": "subnet-00b3db3f74902bc0a",<br>  "us-gov-west-1c": "subnet-093de3674c6f2c16e"<br>}</pre> | no |
| <a name="input_tags"></a> [tags](#input\_tags) | Tags to apply to all resources. | `map(string)` | n/a | yes |
| <a name="input_terraform-role"></a> [terraform-role](#input\_terraform-role) | The IAM role ARN to execute terraform with. | `string` | n/a | yes |
| <a name="input_vpc-id"></a> [vpc-id](#input\_vpc-id) | The VPC to deploy in | `string` | n/a | yes |

## Outputs

No outputs.
