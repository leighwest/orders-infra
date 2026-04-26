resource "aws_sqs_queue" "order_created" {
  name                       = "order-created"
  visibility_timeout_seconds = 60
  message_retention_seconds  = 86400
}

resource "aws_sqs_queue" "order_dispatched" {
  name                       = "order-dispatched"
  visibility_timeout_seconds = 60
  message_retention_seconds  = 86400
}