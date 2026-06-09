resource "aws_s3_bucket" "orders" {
  bucket = "cupcake-orders-images"
}

resource "aws_s3_bucket_public_access_block" "orders" {
  bucket = aws_s3_bucket.orders.id

  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false
}

resource "aws_s3_bucket_policy" "orders" {
  bucket     = aws_s3_bucket.orders.id
  depends_on = [aws_s3_bucket_public_access_block.orders]

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect    = "Allow"
        Principal = "*"
        Action    = "s3:GetObject"
        Resource  = "${aws_s3_bucket.orders.arn}/*"
      }
    ]
  })
}

resource "aws_s3_bucket" "deploy" {
  bucket = "orders-deploy-artefacts"
}

resource "aws_s3_bucket" "lambda_artifacts" {
  bucket = "orders-lambda-artifacts"
}

resource "aws_s3_bucket_versioning" "lambda_artifacts" {
  bucket = aws_s3_bucket.lambda_artifacts.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket" "closed_page" {
  bucket = "orders-closed-page"
}

resource "aws_s3_bucket_policy" "closed_page" {
  bucket = aws_s3_bucket.closed_page.id
  policy = data.aws_iam_policy_document.closed_page_s3.json
}

resource "aws_s3_bucket" "lambda_artifacts_us_east_1" {
  provider = aws.us_east_1
  bucket   = "orders-lambda-artifacts-us-east-1"
}

