/*
*   Peer two VPCs to connect MSK clusters across regions
*/
locals {
  base-name = "${var.app-shorthand-name}.${var.region}"
}

provider "aws" {
  region = keys(var.vpc-ids)[0]
  alias  = "primary"
}

data "aws_vpc" "primary" {
  provider = aws.primary
  id       = var.vpc-ids[keys(var.vpc-ids)[0]]
}

data "aws_vpc" "secondary" {
  id = var.vpc-ids[keys(var.vpc-ids)[1]]
}

data "aws_route_table" "primary-private" {
  provider = aws.primary
  vpc_id   = var.vpc-ids[keys(var.vpc-ids)[0]]

  filter {
    name   = "tag:Name"
    values = ["*private*"]
  }
}

data "aws_route_table" "secondary-private" {
  vpc_id = var.vpc-ids[keys(var.vpc-ids)[1]]

  filter {
    name   = "tag:Name"
    values = ["*private*"]
  }
}

# Requester's side of the connection.
resource "aws_vpc_peering_connection" "primary" {
  provider      = aws.primary
  vpc_id        = data.aws_vpc.primary.id
  peer_vpc_id   = data.aws_vpc.secondary.id
  peer_owner_id = var.account-id
  peer_region   = keys(var.vpc-ids)[1]
  auto_accept   = false

  tags = {
    Side = "Requester"
  }
}

# Accepter's side of the connection.
resource "aws_vpc_peering_connection_accepter" "secondary" {
  vpc_peering_connection_id = aws_vpc_peering_connection.primary.id
  auto_accept               = true

  tags = {
    Side = "Accepter"
  }
}

resource "aws_route" "primary2secondary" {
  provider                  = aws.primary
  route_table_id            = data.aws_vpc.primary.main_route_table_id
  destination_cidr_block    = data.aws_vpc.secondary.cidr_block
  vpc_peering_connection_id = aws_vpc_peering_connection.primary.id
}
resource "aws_route" "secondary2primary" {
  route_table_id            = data.aws_vpc.secondary.main_route_table_id
  destination_cidr_block    = data.aws_vpc.primary.cidr_block
  vpc_peering_connection_id = aws_vpc_peering_connection.primary.id
}
resource "aws_route" "primary2secondaryprivate" {
  provider                  = aws.primary
  route_table_id            = data.aws_route_table.primary-private.id
  destination_cidr_block    = data.aws_vpc.secondary.cidr_block
  vpc_peering_connection_id = aws_vpc_peering_connection.primary.id
}
resource "aws_route" "secondary2primaryprivate" {
  route_table_id            = data.aws_route_table.secondary-private.id
  destination_cidr_block    = data.aws_vpc.primary.cidr_block
  vpc_peering_connection_id = aws_vpc_peering_connection.primary.id
}

resource "aws_route53_zone" "main" {
  for_each = var.vpc-ids

  name = "kafka.${each.key}.amazonaws.com"
  dynamic "vpc" {
    # Map the domain to the remote VPC (e.g. east zone in west VPC, west zone in east VPC)
    for_each = { for k, v in var.vpc-ids : k => v if k != each.key }
    content {
      vpc_id     = vpc.value
      vpc_region = vpc.key
    }
  }
}

resource "aws_route53_record" "main" {
  for_each = {
    for o in flatten([
      for region, nodes in var.broker-nodes : [
        for node in nodes : [
          {
            "region" : region,
            "node" : node,
          }
        ]
      ]
      ]
    ) :
    "${o.region}_${o.node.id}" => o
  }
  zone_id = aws_route53_zone.main[each.value.region].zone_id
  name    = "b-${each.value.node.id}.${var.broker-zones[each.value.region]}"

  # GovCloud:
  type                             = "A"
  ttl                              = 300
  records                          = [each.value.node.ip]
  multivalue_answer_routing_policy = true
  set_identifier                   = each.value.node.availability_zone
}

# resource "aws_route53_record" "per_method" {
#   for_each = {
#     for o in flatten([
#       for region, nodes in var.broker-nodes : [
#         for node in nodes : [
#           for method in ["tls", "sasl", "iam"] : [
#             {
#               "region" : region,
#               "node" : node,
#               "method" : method,
#             }
#         ]]
#       ]
#       ]
#     ) :
#     "${o.region}_${o.node.id}_${o.method}" => o
#   }
#   zone_id = aws_route53_zone.main[each.value.region].zone_id
#   name    = "b-${each.value.node.id}.${each.value.method}.${var.broker-zones[each.value.region]}"

#   # GovCloud:
#   type                             = "A"
#   ttl                              = 300
#   records                          = [each.value.node.ip]
#   multivalue_answer_routing_policy = true
#   set_identifier                   = "${each.value.node.availability_zone}_${each.value.method}"
# }
