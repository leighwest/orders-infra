###
# CloudFront KeyValueStore
###

resource "aws_cloudfront_key_value_store" "ec2_state" {
  name    = "ec2-state"
  comment = "Stores EC2 up/down state for Lambda@Edge closed page routing"
}
