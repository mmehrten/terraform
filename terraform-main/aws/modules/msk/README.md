Create a msk culster.

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
| [aws_cloudwatch_log_group.main](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_log_group) | resource |
| [aws_iam_role.main](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_iam_role_policy.main](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy) | resource |
| [aws_kms_alias.alias](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/kms_alias) | resource |
| [aws_kms_key.main](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/kms_key) | resource |
| [aws_msk_cluster.main](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/msk_cluster) | resource |
| [aws_msk_configuration.main](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/msk_configuration) | resource |
| [aws_security_group.main](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group) | resource |
| [aws_msk_broker_nodes.main](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/msk_broker_nodes) | data source |
| [aws_subnets.main](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/subnets) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_account-id"></a> [account-id](#input\_account-id) | The account to create resources in. | `string` | n/a | yes |
| <a name="input_app-name"></a> [app-name](#input\_app-name) | The longhand name of the app being provisioned. | `string` | n/a | yes |
| <a name="input_app-shorthand-name"></a> [app-shorthand-name](#input\_app-shorthand-name) | The shorthand name of the app being provisioned. | `string` | n/a | yes |
| <a name="input_base-name"></a> [base-name](#input\_base-name) | The base name to create new resources with (e.g. {app\_shorthand}.%s). | `string` | n/a | yes |
| <a name="input_endpoints"></a> [endpoints](#input\_endpoints) | A list of the services to create interface endpoints for. | `map(any)` | <pre>{<br>  "ec2messages": null,<br>  "ecr.api": {<br>    "dns": "api.ecr",<br>    "service": "com.amazonaws.%s.ecr.api"<br>  },<br>  "ecr.dkr": {<br>    "dns": "dkr.ecr",<br>    "service": "com.amazonaws.%s.ecr.dkr"<br>  },<br>  "ecs": null,<br>  "elasticmapreduce": null,<br>  "execute-api": null,<br>  "glue": null,<br>  "kinesis-firehose": {<br>    "dns": "firehose",<br>    "service": "com.amazonaws.%s.kinesis-firehose"<br>  },<br>  "kinesis-streams": {<br>    "dns": "kinesis",<br>    "service": "com.amazonaws.%s.kinesis-streams"<br>  },<br>  "kms": null,<br>  "logs": null,<br>  "monitoring": null,<br>  "rds": null,<br>  "redshift": null,<br>  "sagemaker.api": null,<br>  "sagemaker.notebook": {<br>    "dns": "notebook",<br>    "service": "aws.sagemaker.%s.notebook"<br>  },<br>  "sagemaker.runtime": null,<br>  "sagemaker.studio": {<br>    "dns": "studio",<br>    "service": "aws.sagemaker.%s.studio"<br>  },<br>  "secretsmanager": null,<br>  "sns": null,<br>  "sqs": null,<br>  "ssm": null,<br>  "ssmmessages": null,<br>  "sts": null<br>}</pre> | no |
| <a name="input_msk-configuration"></a> [msk-configuration](#input\_msk-configuration) | The MSK configuration file to use | `string` | `"auto.create.topics.enable=true\nlog.retention.hours=8\ndefault.replication.factor=3\nmin.insync.replicas=2\nnum.io.threads=8\nnum.network.threads=5\nnum.partitions=6\nnum.replica.fetchers=2\nreplica.lag.time.max.ms=30000\nsocket.receive.buffer.bytes=102400\nsocket.request.max.bytes=104857600\nsocket.send.buffer.bytes=102400\nunclean.leader.election.enable=true\nzookeeper.session.timeout.ms=18000\nallow.everyone.if.no.acl.found=false\n"` | no |
| <a name="input_org-shorthand-name"></a> [org-shorthand-name](#input\_org-shorthand-name) | The organization's descriptor, shorthand (e.g. Any Company -> ac) | `string` | `"ac"` | no |
| <a name="input_partition"></a> [partition](#input\_partition) | The partition to create resources in. | `string` | n/a | yes |
| <a name="input_region"></a> [region](#input\_region) | The region to create resources in. | `string` | n/a | yes |
| <a name="input_tags"></a> [tags](#input\_tags) | Tags to apply to all resources. | `map(string)` | n/a | yes |
| <a name="input_terraform-role"></a> [terraform-role](#input\_terraform-role) | The role for Terraform to use, which dictates the account resources are created in. | `string` | n/a | yes |
| <a name="input_tls-certificate-arns"></a> [tls-certificate-arns](#input\_tls-certificate-arns) | ARNs of the ACM certs to use for TLS | `list(string)` | `[]` | no |
| <a name="input_vpc-id"></a> [vpc-id](#input\_vpc-id) | The VPC to create the cluster in | `string` | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_admin_iam_role_arn"></a> [admin\_iam\_role\_arn](#output\_admin\_iam\_role\_arn) | n/a |
| <a name="output_bootstrap_brokers"></a> [bootstrap\_brokers](#output\_bootstrap\_brokers) | Unauthenticated connection host:port pairs |
| <a name="output_bootstrap_brokers_sasl_iam"></a> [bootstrap\_brokers\_sasl\_iam](#output\_bootstrap\_brokers\_sasl\_iam) | SASL IAM connection host:port pairs |
| <a name="output_bootstrap_brokers_sasl_scram"></a> [bootstrap\_brokers\_sasl\_scram](#output\_bootstrap\_brokers\_sasl\_scram) | SASL SCRAM connection host:port pairs |
| <a name="output_bootstrap_brokers_tls"></a> [bootstrap\_brokers\_tls](#output\_bootstrap\_brokers\_tls) | TLS connection host:port pairs |
| <a name="output_bootstrap_brokers_vpc_connectivity_sasl_iam"></a> [bootstrap\_brokers\_vpc\_connectivity\_sasl\_iam](#output\_bootstrap\_brokers\_vpc\_connectivity\_sasl\_iam) | Multi-VPC SASL IAM connection host:port pairs |
| <a name="output_bootstrap_brokers_vpc_connectivity_sasl_scram"></a> [bootstrap\_brokers\_vpc\_connectivity\_sasl\_scram](#output\_bootstrap\_brokers\_vpc\_connectivity\_sasl\_scram) | Multi-VPC SASL SCRAM connection host:port pairs |
| <a name="output_bootstrap_brokers_vpc_connectivity_tls"></a> [bootstrap\_brokers\_vpc\_connectivity\_tls](#output\_bootstrap\_brokers\_vpc\_connectivity\_tls) | Multi-VPC TLS connection host:port pairs |
| <a name="output_broker_nodes"></a> [broker\_nodes](#output\_broker\_nodes) | n/a |
| <a name="output_cluster_arn"></a> [cluster\_arn](#output\_cluster\_arn) | n/a |
| <a name="output_cluster_name"></a> [cluster\_name](#output\_cluster\_name) | n/a |
| <a name="output_security_group_id"></a> [security\_group\_id](#output\_security\_group\_id) | n/a |
| <a name="output_zookeeper_connect_string"></a> [zookeeper\_connect\_string](#output\_zookeeper\_connect\_string) | n/a |
