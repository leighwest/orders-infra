data "aws_caller_identity" "current" {}

data "aws_vpc" "default" {
  default = true
}

data "aws_iam_policy_document" "closed_page_s3" {
  statement {
    principals {
      type        = "Service"
      identifiers = ["cloudfront.amazonaws.com"]
    }

    actions   = ["s3:GetObject"]
    resources = ["${aws_s3_bucket.closed_page.arn}/*"]

    condition {
      test     = "StringEquals"
      variable = "AWS:SourceArn"
      values   = [aws_cloudfront_distribution.closed_page.arn]
    }
  }
}
