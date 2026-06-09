###
# EC2 Stop Lambda
###

resource "aws_lambda_function" "ec2_stop" {
  s3_bucket     = aws_s3_bucket.lambda_artifacts.bucket
  s3_key        = "ec2_stop/${var.GIT_SHA}.zip"
  function_name = "ec2_stop"
  role          = aws_iam_role.ec2_stop_lambda.arn
  handler       = "ec2_stop.lambda_handler"
  runtime       = "python3.12"
  timeout       = 60

  environment {
    variables = {
      REGION  = var.AWS_REGION
      KVS_ARN = aws_cloudfront_key_value_store.ec2_state.arn
    }
  }
}

###
# EC2 Start Lambda
###

resource "aws_lambda_function" "ec2_start" {
  s3_bucket     = aws_s3_bucket.lambda_artifacts.bucket
  s3_key        = "ec2_start/${var.GIT_SHA}.zip"
  function_name = "ec2_start"
  role          = aws_iam_role.ec2_start_lambda.arn
  handler       = "ec2_start.lambda_handler"
  runtime       = "python3.12"
  timeout       = 300

  environment {
    variables = {
      REGION         = var.AWS_REGION
      HOSTED_ZONE_ID = aws_route53_zone.leighwest_dev.zone_id
      KVS_ARN        = aws_cloudfront_key_value_store.ec2_state.arn
    }
  }
}

###
# Dispatch Lambda
###

resource "aws_lambda_function" "dispatch" {
  s3_bucket     = aws_s3_bucket.lambda_artifacts.bucket
  s3_key        = "dispatch/${var.GIT_SHA}.zip"
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
}

resource "aws_lambda_event_source_mapping" "dispatch_sqs_trigger" {
  event_source_arn = aws_sqs_queue.order_created.arn
  function_name    = aws_lambda_function.dispatch.arn
  batch_size       = 1
  enabled          = true
}

###
# Lambda@Edge
###

resource "aws_lambda_function" "lambda_edge" {
  provider      = aws.us_east_1
  s3_bucket     = aws_s3_bucket.lambda_artifacts.bucket
  s3_key        = "lambda_edge/${var.GIT_SHA}.zip"
  function_name = "orders-lambda-edge"
  role          = aws_iam_role.lambda_edge.arn
  handler       = "lambda_edge.handler"
  runtime       = "nodejs20.x"
  timeout       = 5
  publish       = true
}
