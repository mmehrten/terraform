/*
* Create an ACM certificate.
*/

resource "aws_acm_certificate" "main" {
  certificate_authority_arn = var.pca-arn
  domain_name               = var.domain-name
  subject_alternative_names = var.subject-alternative-names
}

output "arn" {
  value = aws_acm_certificate.main.arn
}
output "domain_name" {
  value = aws_acm_certificate.main.domain_name
}
