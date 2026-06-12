###
# CloudFront KeyValueStore
###

resource "aws_cloudfront_key_value_store" "ec2_state" {
  name    = "ec2-state"
  comment = "Stores EC2 up/down state for CloudFront Function closed page routing"
}

###
# CloudFront Function
###

resource "aws_cloudfront_function" "viewer_request" {
  name    = "orders-viewer-request"
  runtime = "cloudfront-js-2.0"
  publish = true
  code    = file("${path.module}/scripts/viewer_request.js")

  key_value_store_associations = [aws_cloudfront_key_value_store.ec2_state.arn]
}
