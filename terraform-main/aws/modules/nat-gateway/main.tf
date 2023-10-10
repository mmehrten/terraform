/*
* Create an internet gateway in a public subnet.
*/

resource "aws_eip" "main" {
  domain = "vpc"
}
resource "aws_nat_gateway" "main" {
  allocation_id = aws_eip.main.id
  subnet_id     = var.subnet-id

  tags = {
    Description = "Allow inbound / outbound internet connections to VPC from private subnet"
    Name        = "${var.base-name}.natgw"
  }
}

resource "aws_route" "main" {
  route_table_id         = var.route-table-id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.main.id

  timeouts {
    create = "5m"
  }
}
