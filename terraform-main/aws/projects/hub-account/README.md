  Create hub VPC with VPC endpoints and an internet gateway, to be used as a transit hub for other VPCs.

## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | = 4.6.0 |

## Providers

No providers.

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_internet-gateway"></a> [internet-gateway](#module\_internet-gateway) | ../../modules/internet-gateway | n/a |
| <a name="module_organization-root"></a> [organization-root](#module\_organization-root) | ../../modules/organization-root | n/a |
| <a name="module_terraform"></a> [terraform](#module\_terraform) | ../../modules/terraform-infra | n/a |
| <a name="module_transit-gateway"></a> [transit-gateway](#module\_transit-gateway) | ../../modules/transit-gateway | n/a |
| <a name="module_vpc"></a> [vpc](#module\_vpc) | ../../modules/vpc | n/a |
| <a name="module_vpc-endpoints"></a> [vpc-endpoints](#module\_vpc-endpoints) | ../../modules/vpc-endpoints | n/a |

## Resources

No resources.

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_account-id"></a> [account-id](#input\_account-id) | n/a | `any` | n/a | yes |
| <a name="input_app-name"></a> [app-name](#input\_app-name) | n/a | `any` | n/a | yes |
| <a name="input_app-shorthand-name"></a> [app-shorthand-name](#input\_app-shorthand-name) | n/a | `any` | n/a | yes |
| <a name="input_region"></a> [region](#input\_region) | n/a | `string` | `"us-east-1"` | no |

## Outputs

No outputs.
