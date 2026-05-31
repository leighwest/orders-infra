resource "aws_acm_certificate" "cupcakes_api" {
  provider          = aws.us_east_1
  domain_name       = "cupcakes-api.leighwest.dev"
  validation_method = "DNS"

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_route53_record" "cupcakes_api_cert_validation" {
  for_each = {
    for dvo in aws_acm_certificate.cupcakes_api.domain_validation_options : dvo.domain_name => {
      name   = dvo.resource_record_name
      record = dvo.resource_record_value
      type   = dvo.resource_record_type
    }
  }

  zone_id = aws_route53_zone.leighwest_dev.zone_id
  name    = each.value.name
  type    = each.value.type
  records = [each.value.record]
  ttl     = 300
}

resource "aws_acm_certificate_validation" "cupcakes_api" {
  provider                = aws.us_east_1
  certificate_arn         = aws_acm_certificate.cupcakes_api.arn
  validation_record_fqdns = [for record in aws_route53_record.cupcakes_api_cert_validation : record.fqdn]
}
