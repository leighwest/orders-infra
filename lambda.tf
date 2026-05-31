###
# EC2 Stop Lambda
###

resource "aws_lambda_function" "ec2_stop" {
  s3_bucket     = aws_s3_bucket.lambda_artifacts.bucket
  s3_key        = "ec2_stop/${var.GIT_SHA}.zip"
  function_name = "ec2_stop"
  role          = aws_iam_role.ec2_stop_lambda.arn
  handler       = "ec2_stop.lambda_handler"
  runtime       = "python3.9"
  timeout       = 60

  environment {
    variables = {
      REGION            = var.AWS_REGION
      HOSTED_ZONE_ID    = aws_route53_zone.leighwest_dev.zone_id
      CLOUDFRONT_DOMAIN = aws_cloudfront_distribution.closed_page.domain_name
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
  runtime       = "python3.9"
  timeout       = 300

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
