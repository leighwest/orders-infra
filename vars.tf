variable "AWS_REGION" {
  default = "ap-southeast-4"
}
variable "PERSONAL_IP_ADDRESS" {}

variable "PATH_TO_EC2_STOP_SCRIPT" {
  default = "scripts/ec2_stop.py"
}

variable "INSTANCE_ID" {
  description = "The ID of the orders EC2 instance."
  type        = string
}

variable "ECR_REPO_NAME" {
  description = "Name of the ECR repository for the orders Docker image."
  type        = string
  default     = "orders"
}
