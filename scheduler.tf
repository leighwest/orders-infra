resource "aws_scheduler_schedule" "start_ec2" {
  name       = "orders-start-ec2"
  group_name = "default"

  flexible_time_window {
    mode = "OFF"
  }

  schedule_expression          = "cron(50 6 * * ? *)"
  schedule_expression_timezone = "Australia/Melbourne"

  target {
    arn      = aws_lambda_function.ec2_start.arn
    role_arn = aws_iam_role.eventbridge_scheduler.arn
  }
}

resource "aws_scheduler_schedule" "stop_ec2" {
  name       = "orders-stop-ec2"
  group_name = "default"

  flexible_time_window {
    mode = "OFF"
  }

  schedule_expression          = "cron(0 20 * * ? *)"
  schedule_expression_timezone = "Australia/Melbourne"

  target {
    arn      = aws_lambda_function.ec2_stop.arn
    role_arn = aws_iam_role.eventbridge_scheduler.arn
  }
}
