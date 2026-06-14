variable "AWS_REGION" {
  default = "ap-southeast-4"
}
variable "PERSONAL_IP_ADDRESS" {}

variable "PATH_TO_EC2_STOP_SCRIPT" {
  default = "scripts/ec2_stop.py"
}

variable "ECR_REPO_NAME" {
  description = "Name of the ECR repository for the orders Docker image."
  type        = string
  default     = "orders"
}

variable "GIT_SHA" {
  description = "Git commit SHA for Lambda artifact versioning"
  type        = string
}

variable "CF_API_TOKEN" {
  description = "Cloudflare API token with Zone:DNS:Edit scope for leighwest.dev"
  type        = string
  sensitive   = true
}

variable "CF_ZONE_ID" {
  description = "Cloudflare zone ID for leighwest.dev"
  type        = string
  default     = "69b8f0eda93d9cb6569948c7faba86f9"
}

variable "CF_RECORD_ID" {
  description = "Cloudflare DNS record ID for origin.cupcakes-api.leighwest.dev"
  type        = string
  default     = "f51640ea43f41df7f2ddd47751679e4d"
}
