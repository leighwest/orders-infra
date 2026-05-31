provider "aws" {
  region = var.AWS_REGION
}

provider "aws" {
  alias  = "us_east_1"
  region = "us-east-1"
}
