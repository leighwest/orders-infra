terraform {
  backend "s3" {
    bucket = "orders-infra-tfstate"
    key    = "orders/terraform.tfstate"
    region = "ap-southeast-4"
  }
}