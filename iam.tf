resource "aws_iam_user" "smtp_user" {
  name = "ses-smtp-user"
}

resource "aws_iam_user_policy_attachment" "ses_send_policy" {
  user       = aws_iam_user.smtp_user.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSESFullAccess"
}

resource "aws_iam_access_key" "smtp_credentials" {
  user = aws_iam_user.smtp_user.name
}

resource "aws_ssm_parameter" "smtp_username" {
  name  = "orders_iam_access_key_id"
  type  = "String"
  value = aws_iam_access_key.smtp_credentials.id
}

resource "aws_ssm_parameter" "smtp_password" {
  name  = "orders_iam_secret_access_key"
  type  = "SecureString"
  value = aws_iam_access_key.smtp_credentials.secret
}

###
# EC2 Instance Manager
###

resource "aws_iam_user" "ec2_manager" {
  name = "ec2-manager"
}

resource "aws_iam_policy" "ec2_mgmt_policy" {
  name        = "EC2ManagementPolicy"
  path        = "/"
  description = "Allow starting and stopping EC2 instances"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "ec2:StartInstances",
          "ec2:StopInstances",
          "ec2:DescribeInstances",
          "ec2:CreateTags",
        ]
        Resource = [
          "*",
        ]
      },
    ]
  })
}

resource "aws_iam_user_policy_attachment" "ec2_manager_policy_attach" {
  user       = aws_iam_user.ec2_manager.name
  policy_arn = aws_iam_policy.ec2_mgmt_policy.arn
}

resource "aws_iam_access_key" "ec2_manager_credentials" {
  user = aws_iam_user.ec2_manager.name
}

resource "aws_ssm_parameter" "ec2_manager_access_key_id" {
  name  = "ec2_manager_access_key_id"
  type  = "String"
  value = aws_iam_access_key.ec2_manager_credentials.id
}

resource "aws_ssm_parameter" "ec2_manager_secret_access_key" {
  name  = "ec2_manager_secret_access_key"
  type  = "SecureString"
  value = aws_iam_access_key.ec2_manager_credentials.secret
}

###
# Lambda Scheduled Stop
###

resource "aws_iam_role" "lambda_role" {
  name = "lambda_execution_role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Principal = {
          Service = "lambda.amazonaws.com"
        },
        Action = "sts:AssumeRole"
      }
    ]
  })
}

resource "aws_iam_policy" "lambda_policy" {
  name = "ec2_stop_start_policy"
  policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Effect" : "Allow",
        "Action" : [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ],
        "Resource" : "arn:aws:logs:*:*:*"
      },
      {
        "Effect" : "Allow",
        "Action" : [
          "ec2:StartInstances",
          "ec2:StopInstances"
        ],
        "Resource" : "*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "lambda_policy_attachment" {
  policy_arn = aws_iam_policy.lambda_policy.arn
  role       = aws_iam_role.lambda_role.name
}

resource "aws_iam_role" "ec2_instance_role" {
  name = "orders-ec2-instance-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })
}

resource "aws_iam_policy" "ec2_instance_policy" {
  name = "orders-ec2-instance-policy"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "SQSAccess"
        Effect = "Allow"
        Action = [
          "sqs:SendMessage",
          "sqs:ReceiveMessage",
          "sqs:DeleteMessage",
          "sqs:GetQueueAttributes",
          "sqs:GetQueueUrl",
        ]
        Resource = [
          aws_sqs_queue.order_created.arn,
          aws_sqs_queue.order_dispatched.arn,
        ]
      },
      {
        Sid    = "S3Access"
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:DeleteObject",
          "s3:ListBucket",
        ]
        Resource = [
          aws_s3_bucket.orders.arn,
          "${aws_s3_bucket.orders.arn}/*",
        ]
      },
      {
        Sid    = "ECRAuth"
        Effect = "Allow"
        Action = ["ecr:GetAuthorizationToken"]
        Resource = "*"
      },
      {
        Sid    = "ECRAccess"
        Effect = "Allow"
        Action = [
          "ecr:GetDownloadUrlForLayer",
          "ecr:BatchGetImage",
          "ecr:BatchCheckLayerAvailability",
        ]
        Resource = aws_ecr_repository.orders.arn
      },
    ]
  })
}

resource "aws_iam_role_policy_attachment" "ec2_instance_policy_attach" {
  role       = aws_iam_role.ec2_instance_role.name
  policy_arn = aws_iam_policy.ec2_instance_policy.arn
}

resource "aws_iam_instance_profile" "ec2_instance_profile" {
  name = "orders-ec2-instance-profile"
  role = aws_iam_role.ec2_instance_role.name
}

###
# Dispatch Lambda Role
###

resource "aws_iam_role" "dispatch_lambda_role" {
  name = "orders-dispatch-lambda-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })
}

resource "aws_iam_policy" "dispatch_lambda_policy" {
  name = "orders-dispatch-lambda-policy"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "CloudWatchLogs"
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents",
        ]
        Resource = "arn:aws:logs:*:*:*"
      },
      {
        Sid    = "ConsumeOrderCreated"
        Effect = "Allow"
        Action = [
          "sqs:ReceiveMessage",
          "sqs:DeleteMessage",
          "sqs:GetQueueAttributes",
        ]
        Resource = aws_sqs_queue.order_created.arn
      },
      {
        Sid    = "PublishOrderDispatched"
        Effect = "Allow"
        Action = [
          "sqs:SendMessage",
          "sqs:GetQueueUrl",
        ]
        Resource = aws_sqs_queue.order_dispatched.arn
      },
    ]
  })
}

resource "aws_iam_role_policy_attachment" "dispatch_lambda_policy_attach" {
  role       = aws_iam_role.dispatch_lambda_role.name
  policy_arn = aws_iam_policy.dispatch_lambda_policy.arn
}
