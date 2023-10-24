  Create a Prometheus and Grafana instance in ECS Fargate.

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
| <a name="module_cluster"></a> [cluster](#module\_cluster) | ../terraform-main/aws/modules/ecs-cluster | n/a |
| <a name="module_grafana"></a> [grafana](#module\_grafana) | ../terraform-main/aws/modules/grafana-ecs | n/a |
| <a name="module_prometheus"></a> [prometheus](#module\_prometheus) | ../terraform-main/aws/modules/prometheus-ecs | n/a |

## Resources

| Name | Type |
|------|------|
| [aws_service_discovery_private_dns_namespace.main](https://registry.terraform.io/providers/hashicorp/aws/4.44.0/docs/resources/service_discovery_private_dns_namespace) | resource |
| [aws_ssm_parameter.conf](https://registry.terraform.io/providers/hashicorp/aws/4.44.0/docs/resources/ssm_parameter) | resource |
| [aws_ssm_parameter.dns](https://registry.terraform.io/providers/hashicorp/aws/4.44.0/docs/resources/ssm_parameter) | resource |
| [aws_subnet_ids.public](https://registry.terraform.io/providers/hashicorp/aws/4.44.0/docs/data-sources/subnet_ids) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_account-id"></a> [account-id](#input\_account-id) | The account to create resources in. | `string` | n/a | yes |
| <a name="input_app-name"></a> [app-name](#input\_app-name) | The longhand name of the app being provisioned. | `string` | n/a | yes |
| <a name="input_app-shorthand-name"></a> [app-shorthand-name](#input\_app-shorthand-name) | The shorthand name of the app being provisioned. | `string` | n/a | yes |
| <a name="input_partition"></a> [partition](#input\_partition) | The partition to create resources in. | `string` | `"aws"` | no |
| <a name="input_region"></a> [region](#input\_region) | The region to create resources in. | `string` | `"us-east-1"` | no |
| <a name="input_tags"></a> [tags](#input\_tags) | Tags to apply to all resources. | `map(string)` | n/a | yes |
| <a name="input_terraform-role"></a> [terraform-role](#input\_terraform-role) | The IAM role ARN to execute terraform with. | `string` | n/a | yes |
| <a name="input_vpc-id"></a> [vpc-id](#input\_vpc-id) | The VPC to deploy in | `string` | n/a | yes |

## Outputs

No outputs.
