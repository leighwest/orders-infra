resource "aws_s3_bucket" "orders" {
  bucket = "cupcake-orders-images"
}

resource "aws_s3_bucket" "deploy" {
  bucket = "orders-deploy-artefacts"
}