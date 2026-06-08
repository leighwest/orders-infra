resource "aws_cloudfront_origin_access_control" "closed_page" {
  name                              = "orders-closed-page-oac"
  origin_access_control_origin_type = "s3"
  signing_behavior                  = "always"
  signing_protocol                  = "sigv4"
}

resource "aws_cloudfront_distribution" "closed_page" {
  enabled = true
  aliases = ["cupcakes-api.leighwest.dev"]

  # S3 origin — closed page assets
  origin {
    domain_name              = aws_s3_bucket.closed_page.bucket_regional_domain_name
    origin_id                = "s3-closed-page"
    origin_access_control_id = aws_cloudfront_origin_access_control.closed_page.id
  }

  # EC2 origin — live app
  origin {
    domain_name = "origin.cupcakes-api.leighwest.dev"
    origin_id   = "ec2-orders"

    custom_origin_config {
      http_port                = 80
      https_port               = 443
      origin_protocol_policy   = "http-only"
      origin_ssl_protocols     = ["TLSv1.2"]
      origin_keepalive_timeout = 5
      origin_read_timeout      = 10
    }
  }

  # /closed.webp — served from S3 directly, bypasses Lambda@Edge
  ordered_cache_behavior {
    path_pattern           = "/closed.webp"
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

    min_ttl     = 0
    default_ttl = 86400
    max_ttl     = 86400
  }

  # Default behaviour — all requests go to EC2, Lambda@Edge checks KVS flag first
  default_cache_behavior {
    target_origin_id       = "ec2-orders"
    viewer_protocol_policy = "redirect-to-https"
    allowed_methods        = ["DELETE", "GET", "HEAD", "OPTIONS", "PATCH", "POST", "PUT"]
    cached_methods         = ["GET", "HEAD"]

    forwarded_values {
      query_string = true
      headers      = ["Authorization", "Content-Type"]
      cookies {
        forward = "none"
      }
    }

    min_ttl     = 0
    default_ttl = 0
    max_ttl     = 0

    lambda_function_association {
      event_type   = "viewer-request"
      lambda_arn   = aws_lambda_function.lambda_edge.qualified_arn
      include_body = false
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
