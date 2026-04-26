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

###
# Dispatch Lambda
###

data "archive_file" "dispatch" {
  type        = "zip"
  source_dir  = "${path.module}/dispatch_lambda"
  output_path = "dispatch_lambda.zip"
}

resource "aws_lambda_function" "dispatch" {
  filename      = "dispatch_lambda.zip"
  function_name = "orders-dispatch"
  role          = aws_iam_role.dispatch_lambda_role.arn
  handler       = "index.handler"
  runtime       = "nodejs20.x"
  timeout       = 60

  environment {
    variables = {
      ORDER_DISPATCHED_QUEUE_URL = aws_sqs_queue.order_dispatched.url
    }
  }

  source_code_hash = data.archive_file.dispatch.output_base64sha256
}

resource "aws_lambda_event_source_mapping" "dispatch_sqs_trigger" {
  event_source_arn = aws_sqs_queue.order_created.arn
  function_name    = aws_lambda_function.dispatch.arn
  batch_size       = 1
  enabled          = true
}