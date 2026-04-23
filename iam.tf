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
