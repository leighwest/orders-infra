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
