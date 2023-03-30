  Create AWS Glue resources.

## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | = 4.6.0 |

## Providers

No providers.

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_glue"></a> [glue](#module\_glue) | ../../modules/glue | n/a |
| <a name="module_s3-data"></a> [s3-data](#module\_s3-data) | ../../modules/s3 | n/a |
| <a name="module_s3-logs"></a> [s3-logs](#module\_s3-logs) | ../../modules/s3 | n/a |

## Resources

No resources.

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_account-id"></a> [account-id](#input\_account-id) | n/a | `any` | n/a | yes |
| <a name="input_app-name"></a> [app-name](#input\_app-name) | n/a | `any` | n/a | yes |
| <a name="input_app-shorthand-name"></a> [app-shorthand-name](#input\_app-shorthand-name) | n/a | `any` | n/a | yes |
| <a name="input_partition"></a> [partition](#input\_partition) | n/a | `string` | `"aws"` | no |
| <a name="input_region"></a> [region](#input\_region) | n/a | `string` | `"us-east-1"` | no |

## Outputs

No outputs.
