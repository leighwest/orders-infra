resource "aws_lambda_function" "ec2_stop" {
  s3_bucket        = aws_s3_bucket.lambda_artifacts.bucket
  s3_key           = "ec2_stop/${var.GIT_SHA}.zip"
  function_name    = "ec2_stop_auto"
  role             = aws_iam_role.lambda_role.arn
  handler          = "ec2_stop.lambda_handler"
  runtime          = "python3.9"
  timeout          = 60
  source_code_hash = filebase64sha256("ec2_stop.zip")

  environment {
    variables = {
      REGION = var.AWS_REGION
    }
  }
}

###
# Dispatch Lambda
###

resource "aws_lambda_function" "dispatch" {
  s3_bucket        = aws_s3_bucket.lambda_artifacts.bucket
  s3_key           = "dispatch/${var.GIT_SHA}.zip"
  function_name    = "orders-dispatch"
  role             = aws_iam_role.dispatch_lambda_role.arn
  handler          = "index.handler"
  runtime          = "nodejs20.x"
  timeout          = 60
  source_code_hash = filebase64sha256("dispatch_lambda.zip")

  environment {
    variables = {
      ORDER_DISPATCHED_QUEUE_URL = aws_sqs_queue.order_dispatched.url
    }
  }

}

resource "aws_lambda_event_source_mapping" "dispatch_sqs_trigger" {
  event_source_arn = aws_sqs_queue.order_created.arn
  function_name    = aws_lambda_function.dispatch.arn
  batch_size       = 1
  enabled          = true
}
