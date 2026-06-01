resource "aws_cloudfront_origin_access_control" "closed_page" {
  name                              = "orders-closed-page-oac"
  origin_access_control_origin_type = "s3"
  signing_behavior                  = "always"
  signing_protocol                  = "sigv4"
}

resource "aws_cloudfront_distribution" "closed_page" {
  enabled = true
  aliases = ["cupcakes-api.leighwest.dev"]

  # S3 origin — closed page fallback
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

  # Origin group — EC2 primary, S3 fallback
  origin_group {
    origin_id = "orders-origin-group"

    failover_criteria {
      status_codes = [500, 502, 503, 504]
    }

    member {
      origin_id = "ec2-orders"
    }

    member {
      origin_id = "s3-closed-page"
    }
  }

  # Default behaviour — read-only, uses origin group failover
  default_cache_behavior {
    target_origin_id       = "orders-origin-group"
    viewer_protocol_policy = "redirect-to-https"
    allowed_methods        = ["GET", "HEAD", "OPTIONS"]
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
  }

  # Swagger UI — EC2 origin directly
  ordered_cache_behavior {
    path_pattern           = "/swagger-ui*"
    target_origin_id       = "ec2-orders"
    viewer_protocol_policy = "redirect-to-https"
    allowed_methods        = ["GET", "HEAD", "OPTIONS"]
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
  }

  # OpenAPI spec — EC2 origin directly
  ordered_cache_behavior {
    path_pattern           = "/v3*"
    target_origin_id       = "ec2-orders"
    viewer_protocol_policy = "redirect-to-https"
    allowed_methods        = ["GET", "HEAD", "OPTIONS"]
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
  }

  # Orders API — all methods, EC2 origin directly
  ordered_cache_behavior {
    path_pattern           = "/orders*"
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
  }

  # Cupcakes API — all methods, EC2 origin directly
  ordered_cache_behavior {
    path_pattern           = "/cupcakes*"
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
  }

  # Actuator — health check endpoint
  ordered_cache_behavior {
    path_pattern           = "/actuator*"
    target_origin_id       = "ec2-orders"
    viewer_protocol_policy = "redirect-to-https"
    allowed_methods        = ["GET", "HEAD", "OPTIONS"]
    cached_methods         = ["GET", "HEAD"]

    forwarded_values {
      query_string = false
      headers      = ["Authorization", "Content-Type"]
      cookies {
        forward = "none"
      }
    }

    min_ttl     = 0
    default_ttl = 0
    max_ttl     = 0
  }

  custom_error_response {
    error_code         = 403
    response_code      = 200
    response_page_path = "/closed.html"
  }

  custom_error_response {
    error_code         = 404
    response_code      = 200
    response_page_path = "/closed.html"
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
