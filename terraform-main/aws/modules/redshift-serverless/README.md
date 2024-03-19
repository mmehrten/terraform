Create a Redshift culster.

## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | >= 5.29.0 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | >= 5.29.0 |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [aws_iam_role.main](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_iam_role_policy.main](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy) | resource |
| [aws_iam_role_policy_attachment.main](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [aws_kms_alias.alias](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/kms_alias) | resource |
| [aws_kms_key.main](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/kms_key) | resource |
| [aws_redshiftserverless_namespace.main](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/redshiftserverless_namespace) | resource |
| [aws_redshiftserverless_workgroup.main](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/redshiftserverless_workgroup) | resource |
| [aws_route53_record.main](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route53_record) | resource |
| [aws_security_group.main](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group) | resource |
| [aws_route53_zone.main](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/route53_zone) | data source |
| [aws_subnets.main](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/subnets) | data source |
| [aws_vpc_endpoint.redshift](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/vpc_endpoint) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_account-id"></a> [account-id](#input\_account-id) | The account to create resources in. | `string` | n/a | yes |
| <a name="input_app-name"></a> [app-name](#input\_app-name) | The longhand name of the app being provisioned. | `string` | n/a | yes |
| <a name="input_app-shorthand-name"></a> [app-shorthand-name](#input\_app-shorthand-name) | The shorthand name of the app being provisioned. | `string` | n/a | yes |
| <a name="input_base-name"></a> [base-name](#input\_base-name) | The base name to create new resources with (e.g. {app\_shorthand}.%s). | `string` | n/a | yes |
| <a name="input_database-name"></a> [database-name](#input\_database-name) | The Redshift database name | `string` | `"dev"` | no |
| <a name="input_endpoints"></a> [endpoints](#input\_endpoints) | A list of the services to create interface endpoints for. | `map(any)` | <pre>{<br>  "ec2messages": null,<br>  "ecr.api": {<br>    "dns": "api.ecr",<br>    "service": "com.amazonaws.%s.ecr.api"<br>  },<br>  "ecr.dkr": {<br>    "dns": "dkr.ecr",<br>    "service": "com.amazonaws.%s.ecr.dkr"<br>  },<br>  "ecs": null,<br>  "elasticmapreduce": null,<br>  "execute-api": null,<br>  "glue": null,<br>  "kinesis-firehose": {<br>    "dns": "firehose",<br>    "service": "com.amazonaws.%s.kinesis-firehose"<br>  },<br>  "kinesis-streams": {<br>    "dns": "kinesis",<br>    "service": "com.amazonaws.%s.kinesis-streams"<br>  },<br>  "kms": null,<br>  "logs": null,<br>  "monitoring": null,<br>  "rds": null,<br>  "redshift": null,<br>  "sagemaker.api": null,<br>  "sagemaker.notebook": {<br>    "dns": "notebook",<br>    "service": "aws.sagemaker.%s.notebook"<br>  },<br>  "sagemaker.runtime": null,<br>  "sagemaker.studio": {<br>    "dns": "studio",<br>    "service": "aws.sagemaker.%s.studio"<br>  },<br>  "secretsmanager": null,<br>  "sns": null,<br>  "sqs": null,<br>  "ssm": null,<br>  "ssmmessages": null,<br>  "sts": null<br>}</pre> | no |
| <a name="input_master-password"></a> [master-password](#input\_master-password) | The cluster admin user password | `string` | n/a | yes |
| <a name="input_org-shorthand-name"></a> [org-shorthand-name](#input\_org-shorthand-name) | The organization's descriptor, shorthand (e.g. Any Company -> ac) | `string` | `"ac"` | no |
| <a name="input_partition"></a> [partition](#input\_partition) | The partition to create resources in. | `string` | n/a | yes |
| <a name="input_region"></a> [region](#input\_region) | The region to create resources in. | `string` | n/a | yes |
| <a name="input_route-53-zone"></a> [route-53-zone](#input\_route-53-zone) | The Route53 zone for the spoke network | `string` | n/a | yes |
| <a name="input_tags"></a> [tags](#input\_tags) | Tags to apply to all resources. | `map(string)` | n/a | yes |
| <a name="input_terraform-role"></a> [terraform-role](#input\_terraform-role) | The role for Terraform to use, which dictates the account resources are created in. | `string` | n/a | yes |
| <a name="input_vpc-id"></a> [vpc-id](#input\_vpc-id) | The VPC to create the cluster in | `string` | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_jdbc-url"></a> [jdbc-url](#output\_jdbc-url) | n/a |
