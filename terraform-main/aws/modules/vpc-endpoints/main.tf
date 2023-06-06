/*
*   Create a VPC interface endpoints for the configured services, and a gateway endpoint for S3.
*/

data "aws_subnet" "main" {
  for_each = var.subnet-ids
  id       = each.value
}

resource "aws_security_group" "endpoint-security-group" {
  name        = "${var.base-name}.sg.endpoint"
  description = "Security group which contains relationships with all VPC endpoints."
  vpc_id      = var.vpc-id

  ingress {
    description      = "Allow all inbound connections"
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = []
  }

  egress {
    description      = "Allow all outbound connections"
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = []
  }

  tags = {
    Name = "${var.base-name}.sg.endpoint"
  }
}

resource "aws_vpc_endpoint" "access" {
  for_each            = var.endpoints
  vpc_id              = var.vpc-id
  service_name        = each.value == null ? "com.amazonaws.${var.region}.${each.key}" : format(each.value.service, var.region)
  vpc_endpoint_type   = "Interface"
  private_dns_enabled = !var.create-route53-zones
  security_group_ids  = [aws_security_group.endpoint-security-group.id]
  subnet_ids          = [for o in values(var.subnet-ids) : o]

  timeouts {
    create = "45m"
  }

  tags = {
    Name = "${var.base-name}.vpce.${each.key}"
  }
}

locals {
  route_53_aliases = var.create-route53-zones ? {
    for o in flatten([
      for key, value in aws_vpc_endpoint.access :
      {
        "zone_id" : value.dns_entry[0].hosted_zone_id,
        "dns_name" : value.dns_entry[0].dns_name,
        "service_name" : "${key}.${var.region}.amazonaws.com",
        "network_interface_ids" : value.network_interface_ids,
        # Transform vpce-####.service.us-gov-west-1.vpce.amazonaws.com into service.us-gov-west-1.amazonaws.com
        "dns_apex" : join(
          ".",
          slice(
            [for i in split(".", value.dns_entry[0].dns_name) : i if i != "vpce"],
            # We only want the {service}.{region}.amazonaws.com portion
            length(split(".", value.dns_entry[0].dns_name)) - 5,
            length(split(".", value.dns_entry[0].dns_name)) - 1
          )
        )
      }
      ]
    ) :
    o.service_name => o
  } : {}
}

data "aws_network_interface" "interface_ips" {
  for_each = { for o in flatten([for k, v in local.route_53_aliases : [for i in v.network_interface_ids : { "key" : "${k}_${i}", "value" : i }]]) : o.key => o.value }
  id       = each.value
}

resource "aws_route53_zone" "main" {
  for_each = local.route_53_aliases

  name = each.value.dns_apex
  vpc {
    vpc_id = var.vpc-id
  }
  lifecycle { ignore_changes = [vpc] }
  tags = {
    "zone-service" : each.key
  }
}

resource "aws_route53_record" "main" {
  for_each = {
    for o in flatten([
      for k, v in local.route_53_aliases: [
        for id in v.network_interface_ids: {"key": k, "id": id, "value": v}
      ]
    ]): "${o.key}_${o.id}" => o}
  zone_id  = aws_route53_zone.main[each.value.key].zone_id
  name     = each.value.value.dns_apex
  # Commercial:
  # type     = "A"
  # alias {
  #   zone_id                = each.value.zone_id
  #   name                   = each.value.dns_name
  #   evaluate_target_health = true
  # }

  # GovCloud:
  type    = "A"
  ttl     = 300
  records = [data.aws_network_interface.interface_ips["${each.key}"].private_ip]
  multivalue_answer_routing_policy = true
  set_identifier = data.aws_network_interface.interface_ips["${each.key}"].availability_zone
}

// Create an org-wide DNS hosted zone for cross-account resource sharing when needed
resource "aws_route53_zone" "org" {
  count = var.create-route53-zones && var.create-org-zone ? 1 : 0
  name  = "${var.org-shorthand-name}.aws.local"
  vpc {
    vpc_id = var.vpc-id
  }
  lifecycle { ignore_changes = [vpc] }
  tags = {
    "zone-service" : var.app-shorthand-name
  }
}

output "outputs" {
  value = {
    zone_ids = {
      for key, value in aws_route53_zone.main :
      key => value.zone_id
    }
  }
}
