data "archive_file" "ec2_stop" {
  type        = "zip"
  source_file = var.PATH_TO_EC2_STOP_SCRIPT
  output_path = "ec2_stop.zip"
}

resource "aws_lambda_function" "ec2_stop" {
  filename      = "ec2_stop.zip"
  function_name = "ec2_stop_auto"
  role          = aws_iam_role.lambda_role.arn
  handler       = "ec2_stop.lambda_handler"
  runtime       = "python3.9"
  timeout       = 60

  environment {
    variables = {
      REGION      = var.AWS_REGION
      INSTANCE_ID = var.INSTANCE_ID
    }
  }

  source_code_hash = data.archive_file.ec2_stop.output_base64sha256
}
