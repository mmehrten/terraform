Create a prometheus instance running on ECS.

## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | >= 4.44.0 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | >= 4.44.0 |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [aws_ecs_service.prometheus](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ecs_service) | resource |
| [aws_ecs_task_definition.prometheus](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ecs_task_definition) | resource |
| [aws_iam_policy.ecs_task_custom_policy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_policy) | resource |
| [aws_iam_role.ecs_task_execution_role](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_iam_role.ecs_task_role](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_iam_role_policy_attachment.task_cloudwatch](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [aws_iam_role_policy_attachment.task_custom](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [aws_iam_role_policy_attachment.task_ecr](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [aws_iam_role_policy_attachment.task_execution_cloudwatch](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [aws_iam_role_policy_attachment.task_execution_custom](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [aws_iam_role_policy_attachment.task_execution_ecr](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [aws_iam_role_policy_attachment.task_execution_ssm_ro](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [aws_iam_role_policy_attachment.task_ssm_ro](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [aws_security_group.prometheus](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group) | resource |
| [aws_service_discovery_service.main](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/service_discovery_service) | resource |
| [aws_iam_policy_document.ecs_task](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_account-id"></a> [account-id](#input\_account-id) | The account to create resources in. | `string` | n/a | yes |
| <a name="input_app-name"></a> [app-name](#input\_app-name) | The longhand name of the app being provisioned. | `string` | n/a | yes |
| <a name="input_app-shorthand-name"></a> [app-shorthand-name](#input\_app-shorthand-name) | The shorthand name of the app being provisioned. | `string` | n/a | yes |
| <a name="input_base-name"></a> [base-name](#input\_base-name) | The base name to create new resources with (e.g. {app\_shorthand}.%s). | `string` | n/a | yes |
| <a name="input_cluster-id"></a> [cluster-id](#input\_cluster-id) | The ECS cluster ID. | `string` | n/a | yes |
| <a name="input_endpoints"></a> [endpoints](#input\_endpoints) | A list of the services to create interface endpoints for. | `map(any)` | <pre>{<br>  "ec2messages": null,<br>  "ecr.api": {<br>    "dns": "api.ecr",<br>    "service": "com.amazonaws.%s.ecr.api"<br>  },<br>  "ecr.dkr": {<br>    "dns": "dkr.ecr",<br>    "service": "com.amazonaws.%s.ecr.dkr"<br>  },<br>  "ecs": null,<br>  "elasticmapreduce": null,<br>  "execute-api": null,<br>  "glue": null,<br>  "kinesis-firehose": {<br>    "dns": "firehose",<br>    "service": "com.amazonaws.%s.kinesis-firehose"<br>  },<br>  "kinesis-streams": {<br>    "dns": "kinesis",<br>    "service": "com.amazonaws.%s.kinesis-streams"<br>  },<br>  "kms": null,<br>  "logs": null,<br>  "monitoring": null,<br>  "rds": null,<br>  "redshift": null,<br>  "sagemaker.api": null,<br>  "sagemaker.notebook": {<br>    "dns": "notebook",<br>    "service": "aws.sagemaker.%s.notebook"<br>  },<br>  "sagemaker.runtime": null,<br>  "sagemaker.studio": {<br>    "dns": "studio",<br>    "service": "aws.sagemaker.%s.studio"<br>  },<br>  "secretsmanager": null,<br>  "sns": null,<br>  "sqs": null,<br>  "ssm": null,<br>  "ssmmessages": null,<br>  "sts": null<br>}</pre> | no |
| <a name="input_org-shorthand-name"></a> [org-shorthand-name](#input\_org-shorthand-name) | The organization's descriptor, shorthand (e.g. Any Company -> ac) | `string` | `"ac"` | no |
| <a name="input_partition"></a> [partition](#input\_partition) | The partition to create resources in. | `string` | n/a | yes |
| <a name="input_region"></a> [region](#input\_region) | The region to create resources in. | `string` | n/a | yes |
| <a name="input_service-discovery-namespace-id"></a> [service-discovery-namespace-id](#input\_service-discovery-namespace-id) | The service discovery namespace to register to | `string` | n/a | yes |
| <a name="input_subnet-ids"></a> [subnet-ids](#input\_subnet-ids) | The name of the bucket to provision. | `list(string)` | n/a | yes |
| <a name="input_tags"></a> [tags](#input\_tags) | Tags to apply to all resources. | `map(string)` | n/a | yes |
| <a name="input_terraform-role"></a> [terraform-role](#input\_terraform-role) | The role for Terraform to use, which dictates the account resources are created in. | `string` | n/a | yes |
| <a name="input_vpc-id"></a> [vpc-id](#input\_vpc-id) | The name of the bucket to provision. | `string` | n/a | yes |

## Outputs

No outputs.
