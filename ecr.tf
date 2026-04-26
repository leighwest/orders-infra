resource "aws_ecr_repository" "orders" {
  name                 = var.ECR_REPO_NAME
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }
}