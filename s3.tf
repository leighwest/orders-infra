resource "aws_s3_bucket" "orders" {
  bucket = "cupcake-orders-images"
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

