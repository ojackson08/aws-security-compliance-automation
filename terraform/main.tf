provider "aws" {
  region = var.aws_region
}

# 1. Enable AWS GuardDuty
resource "aws_guardduty_detector" "primary" {
  enable = true
}

# 2. SNS Topic for Security Alerts
resource "aws_sns_topic" "security_alerts" {
  name = "security-alerts-topic"
}

resource "aws_sns_topic_subscription" "security_email" {
  topic_arn = aws_sns_topic.security_alerts.arn
  protocol  = "email"
  endpoint  = var.security_email
}

# 3. AWS Config Rule: S3 Public Read Prohibited
resource "aws_config_config_rule" "s3_public_read_prohibited" {
  name = "s3-public-read-prohibited"

  source {
    owner             = "AWS"
    source_identifier = "S3_BUCKET_PUBLIC_READ_PROHIBITED"
  }

  depends_on = [aws_config_configuration_recorder.main]
}

# AWS Config Recorder (Prerequisite for rules)
resource "aws_iam_role" "config_role" {
  name = "aws_config_role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "config.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "config_policy" {
  role       = aws_iam_role.config_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWS_ConfigRole"
}

resource "aws_s3_bucket" "config_bucket" {
  bucket_prefix = "aws-config-logs-"
  force_destroy = true
}

resource "aws_config_delivery_channel" "main" {
  name           = "default"
  s3_bucket_name = aws_s3_bucket.config_bucket.bucket
  depends_on     = [aws_config_configuration_recorder.main]
}

resource "aws_config_configuration_recorder" "main" {
  name     = "default"
  role_arn = aws_iam_role.config_role.arn
}

resource "aws_config_configuration_recorder_status" "main" {
  name       = aws_config_configuration_recorder.main.name
  is_enabled = true
  depends_on = [aws_config_delivery_channel.main]
}

# 4. Lambda Auto-Remediation Function
resource "aws_iam_role" "lambda_remediation_role" {
  name = "security_remediation_lambda_role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "lambda.amazonaws.com"
      }
    }]
  })
}

resource "aws_iam_role_policy" "lambda_remediation_policy" {
  name = "security_remediation_policy"
  role = aws_iam_role.lambda_remediation_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:PutBucketPublicAccessBlock",
          "s3:PutEncryptionConfiguration",
          "s3:GetBucketPublicAccessBlock",
          "s3:GetEncryptionConfiguration"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "sns:Publish"
        ]
        Resource = aws_sns_topic.security_alerts.arn
      },
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = "arn:aws:logs:*:*:*"
      }
    ]
  })
}

data "archive_file" "lambda_zip" {
  type        = "zip"
  source_dir  = "../lambda"
  output_path = "remediation_function.zip"
}

resource "aws_lambda_function" "s3_remediator" {
  filename         = data.archive_file.lambda_zip.output_path
  function_name    = "S3SecurityRemediator"
  role             = aws_iam_role.lambda_remediation_role.arn
  handler          = "remediate_s3.lambda_handler"
  source_code_hash = data.archive_file.lambda_zip.output_base64sha256
  runtime          = "python3.9"

  environment {
    variables = {
      SNS_TOPIC_ARN = aws_sns_topic.security_alerts.arn
    }
  }
}

# 5. EventBridge Rule to Trigger Lambda on Config Compliance Change
resource "aws_cloudwatch_event_rule" "config_compliance_change" {
  name        = "s3-non-compliant-rule"
  description = "Triggers when an S3 bucket becomes non-compliant"

  event_pattern = jsonencode({
    source = ["aws.config"]
    detail-type = ["Config Rules Compliance Change"]
    detail = {
      messageType = ["ComplianceChangeNotification"]
      configRuleName = [aws_config_config_rule.s3_public_read_prohibited.name]
      newEvaluationResult = {
        complianceType = ["NON_COMPLIANT"]
      }
    }
  })
}

resource "aws_cloudwatch_event_target" "trigger_remediation" {
  rule      = aws_cloudwatch_event_rule.config_compliance_change.name
  target_id = "RemediateS3Bucket"
  arn       = aws_lambda_function.s3_remediator.arn
}

resource "aws_lambda_permission" "allow_eventbridge" {
  statement_id  = "AllowExecutionFromEventBridge"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.s3_remediator.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.config_compliance_change.arn
}
