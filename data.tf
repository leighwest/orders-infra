###
# Account & network data
###

data "aws_caller_identity" "current" {}

data "aws_vpc" "default" {
  default = true
}

###
# S3 bucket policy — CloudFront OAC access to closed page bucket
###

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

###
# Lambda@Edge — trust policy and permissions
###

data "aws_iam_policy_document" "lambda_edge_assume_role" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com", "edgelambda.amazonaws.com"]
    }
  }
}

data "aws_iam_policy_document" "lambda_edge" {
  statement {
    sid       = "KVSRead"
    effect    = "Allow"
    actions   = ["cloudfront-keyvaluestore:GetKey"]
    resources = [aws_cloudfront_key_value_store.ec2_state.arn]
  }

  statement {
    sid    = "CloudWatchLogs"
    effect = "Allow"
    actions = [
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents",
    ]
    resources = ["arn:aws:logs:*:*:*"]
  }
}

###
# Lambda@Edge — function artifact
###

data "archive_file" "lambda_edge" {
  type        = "zip"
  output_path = "${path.module}/lambda_edge.zip"

  source {
    content = templatefile("${path.module}/scripts/lambda_edge.mjs", {
      kvs_arn = aws_cloudfront_key_value_store.ec2_state.arn
    })
    filename = "lambda_edge.mjs"
  }
}
