provider "aws" {
  region = var.provider_region
}

# KMS Key for EC2
resource "aws_kms_key" "ec2_key" {
  description             = "KMS key for EC2 volumes"
  enable_key_rotation     = true
  rotation_period_in_days = 90
  deletion_window_in_days = 30
}

resource "aws_kms_alias" "ec2_alias" {
  name          = "alias/ec2-key"
  target_key_id = aws_kms_key.ec2_key.id
}

# KMS Key for RDS
resource "aws_kms_key" "rds_key" {
  description             = "KMS key for RDS instance"
  enable_key_rotation     = true
  rotation_period_in_days = 90
  deletion_window_in_days = 30
}

resource "aws_kms_alias" "rds_alias" {
  name          = "alias/rds-key"
  target_key_id = aws_kms_key.rds_key.id
}

# KMS Key for S3
resource "aws_kms_key" "s3_key" {
  description             = "KMS key for S3 buckets"
  enable_key_rotation     = true
  rotation_period_in_days = 90
  deletion_window_in_days = 30
  policy = jsonencode({
    Version = "2012-10-17",
    Id      = "key-policy-s3-kms",
    Statement = [
      {
        Sid    = "AllowRootAccount",
        Effect = "Allow",
        Principal = {
          AWS = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
        },
        Action   = "kms:*",
        Resource = "*"
      },
      {
        Sid    = "AllowEC2RoleToUseKey",
        Effect = "Allow",
        Principal = {
          AWS = aws_iam_role.ec2_role.arn
        },
        Action = [
          "kms:Decrypt",
          "kms:GenerateDataKey",
          "kms:Encrypt"
        ],
        Resource = "*"
      }
    ]
  })

}

resource "aws_kms_alias" "s3_alias" {
  name          = "alias/s3-key"
  target_key_id = aws_kms_key.s3_key.id
}


# KMS Key for Secrets Manager
resource "aws_kms_key" "secrets_key" {
  description             = "KMS key for Secrets Manager"
  enable_key_rotation     = true
  rotation_period_in_days = 90
  deletion_window_in_days = 30
  multi_region            = true
}

resource "aws_kms_key_policy" "ec2_key_policy" {
  key_id = aws_kms_key.ec2_key.key_id
  policy = jsonencode({
    Version = "2012-10-17"
    Id      = "key-policy"
    Statement = [
      {
        Sid    = "Enable IAM User Permissions"
        Effect = "Allow"
        Principal = {
          AWS = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
        }
        Action   = "kms:*"
        Resource = aws_kms_key.ec2_key.arn
      },
      {
        Sid    = "Allow use of the key"
        Effect = "Allow"
        Principal = {
          AWS = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/${aws_iam_role.ec2_role.name}"
        }
        Action = [
          "kms:Decrypt",
          "kms:GenerateDataKey",
          "kms:DescribeKey",
          "kms:CreateGrant"
        ]
        Resource = aws_kms_key.ec2_key.arn
      },
      {
        Sid    = "Allow attachment of persistent resources"
        Effect = "Allow"
        Principal = {
          AWS = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/aws-service-role/autoscaling.amazonaws.com/AWSServiceRoleForAutoScaling"
        }
        Action = [
          "kms:Encrypt",
          "kms:Decrypt",
          "kms:ReEncrypt*",
          "kms:GenerateDataKey*",
          "kms:DescribeKey",
          "kms:CreateGrant"
        ]
        Resource = aws_kms_key.ec2_key.arn
      }
    ]
  })

}

resource "aws_kms_alias" "secrets_alias" {
  name          = "alias/secrets-key"
  target_key_id = aws_kms_key.secrets_key.id
}

resource "random_pet" "aws_secrets_manager_prefix" {
  length = 3
}

# Secrets Manager Secret
resource "aws_secretsmanager_secret" "rds_creds_secret" {
  name        = "${random_pet.aws_secrets_manager_prefix.id}-database-credentials"
  description = "Credentials for RDS database"
  kms_key_id  = aws_kms_key.secrets_key.arn
}

resource "random_password" "password" {
  length           = 16
  special          = true
  override_special = "!#$%&*()-_=+[]{}<>:?"
}

# Secrets Manager Secret Value
resource "aws_secretsmanager_secret_version" "rds_secret_value" {
  secret_id = aws_secretsmanager_secret.rds_creds_secret.id
  secret_string = jsonencode({
    DB_NAME     = var.DB_NAME
    DB_PASSWORD = random_password.password.result
    DB_USER     = var.DB_USERNAME
    S3_NAME     = aws_s3_bucket.webapp_bucket.bucket
    DOMAIN      = var.hosted_zone_name
    API_KEY     = var.lambda_mailgun_api_key
  })
}
