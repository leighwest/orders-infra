resource "aws_cloudwatch_event_rule" "evening_rule" {
  name                = "evening_rule"
  description         = "Rule to trigger Lambda function at 11:50 PM AEDT / 10:50 PM AEST"
  schedule_expression = "cron(50 12 * * ? *)"
}

resource "aws_cloudwatch_event_target" "evening_lambda_target" {
  rule      = aws_cloudwatch_event_rule.evening_rule.name
  arn       = aws_lambda_function.ec2_stop.arn
  target_id = "evening_lambda_target"
}

resource "aws_lambda_permission" "ec2_stop_permission" {
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.ec2_stop.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.evening_rule.arn
}
