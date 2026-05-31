resource "aws_cloudfront_origin_access_control" "closed_page" {
  name                              = "orders-closed-page-oac"
  origin_access_control_origin_type = "s3"
  signing_behavior                  = "always"
  signing_protocol                  = "sigv4"
}

resource "aws_cloudfront_distribution" "closed_page" {
  enabled             = true
  default_root_object = "closed.html"
  aliases             = ["cupcakes-api.leighwest.dev"]

  origin {
    domain_name              = aws_s3_bucket.closed_page.bucket_regional_domain_name
    origin_id                = "s3-closed-page"
    origin_access_control_id = aws_cloudfront_origin_access_control.closed_page.id
  }

  default_cache_behavior {
    target_origin_id       = "s3-closed-page"
    viewer_protocol_policy = "redirect-to-https"
    allowed_methods        = ["GET", "HEAD"]
    cached_methods         = ["GET", "HEAD"]

    forwarded_values {
      query_string = false
      cookies {
        forward = "none"
      }
    }
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  viewer_certificate {
    acm_certificate_arn      = aws_acm_certificate_validation.cupcakes_api.certificate_arn
    ssl_support_method       = "sni-only"
    minimum_protocol_version = "TLSv1.2_2021"
  }
}
