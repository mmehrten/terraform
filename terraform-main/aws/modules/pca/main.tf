/*
* Create a private certificate authority.
*/

resource "aws_acmpca_certificate_authority" "main" {
  type = "ROOT"
  certificate_authority_configuration {
    key_algorithm     = "RSA_4096"
    signing_algorithm = "SHA512WITHRSA"

    subject {
      common_name = var.subject-common-name
    }
  }

  permanent_deletion_time_in_days = 7
}

resource "aws_acmpca_certificate_authority_certificate" "main" {
  certificate_authority_arn = aws_acmpca_certificate_authority.main.arn

  certificate       = aws_acmpca_certificate.main.certificate
  certificate_chain = aws_acmpca_certificate.main.certificate_chain
}

resource "aws_acmpca_certificate" "main" {
  certificate_authority_arn   = aws_acmpca_certificate_authority.main.arn
  certificate_signing_request = aws_acmpca_certificate_authority.main.certificate_signing_request
  signing_algorithm           = "SHA512WITHRSA"

  template_arn = "arn:${var.partition}:acm-pca:::template/RootCACertificate/V1"

  validity {
    type  = "YEARS"
    value = 100
  }
}

output "certificate" {
  value = aws_acmpca_certificate.main.certificate
}

output "certificate_authority_arn" {
  value = aws_acmpca_certificate.main.certificate_authority_arn
}

output "certificate_chain" {
  value = aws_acmpca_certificate.main.certificate_chain
}

output "common_name" {
  value = aws_acmpca_certificate_authority.main.certificate_authority_configuration[0].subject[0].common_name
}
