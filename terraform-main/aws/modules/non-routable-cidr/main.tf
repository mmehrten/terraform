/*
*   Create a VPC with configured public and private subnets, with a public and private route table.
*/
resource "aws_vpc_ipv4_cidr_block_association" "main" {
  vpc_id     = var.vpc-id
  cidr_block = var.cidr-block
}

resource "aws_subnet" "main" {
  count      = length(var.subnets)
  cidr_block = element(values(var.subnets), count.index)
  vpc_id     = aws_vpc_ipv4_cidr_block_association.main.vpc_id

  map_public_ip_on_launch = true
  availability_zone       = element(keys(var.subnets), count.index)

  tags = {
    Name = "${var.base-name}.subnet.non-routable.${count.index}"
  }
}

resource "aws_route_table" "main" {
  vpc_id = var.vpc-id

  tags = {
    Name = "${var.base-name}.rtb.non-routable"
  }
}

resource "aws_route_table_association" "private" {
  count          = length(var.subnets)
  subnet_id      = element(aws_subnet.main.*.id, count.index)
  route_table_id = aws_route_table.main.id
}
