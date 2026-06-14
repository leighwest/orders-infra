resource "aws_acm_certificate" "cupcakes_api" {
  provider          = aws.us_east_1
  domain_name       = "cupcakes-api.leighwest.dev"
  validation_method = "DNS"

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_acm_certificate_validation" "cupcakes_api" {
  provider        = aws.us_east_1
  certificate_arn = aws_acm_certificate.cupcakes_api.arn

  # Validation record managed in dns-infra (Cloudflare) — hardcoded FQDN since
  # cross-state reference isn't possible and this value is stable for cert lifetime
  validation_record_fqdns = ["_ec4a3753641b03c53a399262943eef10.cupcakes-api.leighwest.dev"]
}
