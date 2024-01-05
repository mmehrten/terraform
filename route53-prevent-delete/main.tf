/*
*   Test Route53 endpoint w/ prevent_destory lifecycle configuration.
*/


resource "aws_security_group" "allow_tls" {
  name        = "allow_tls"
  description = "Allow TLS inbound traffic - updated"
  vpc_id      = "vpc-0616c280677e8ad79"
}

resource "aws_route53_resolver_endpoint" "main" {
  name               = "demo"
  direction          = "INBOUND"
  security_group_ids = [aws_security_group.allow_tls.id]
  ip_address { subnet_id = "subnet-0f64e4a36e782bf25" }
  ip_address {
    subnet_id = "subnet-08726fd16b70d2dec"
    ip        = "10.0.1.72"
  }
  lifecycle { prevent_destroy = true }
}
