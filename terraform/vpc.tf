resource "aws_vpc" "csye6225_vpc" {
  cidr_block = var.vpc_ip
  tags = {
    Name = "csye6225_vpc"
  }
}

resource "aws_internet_gateway" "csye6225_igw" {
  vpc_id = aws_vpc.csye6225_vpc.id
}

resource "aws_route_table" "csye6225_public_rt" {
  vpc_id = aws_vpc.csye6225_vpc.id
}
resource "aws_route_table" "csye6225_private_rt" {
  vpc_id = aws_vpc.csye6225_vpc.id
}


resource "aws_route_table_association" "associate_public_0" {
  subnet_id      = aws_subnet.csye6225_subnet_0_public.id
  route_table_id = aws_route_table.csye6225_public_rt.id
}

resource "aws_route_table_association" "associate_public_1" {
  subnet_id      = aws_subnet.csye6225_subnet_1_public.id
  route_table_id = aws_route_table.csye6225_public_rt.id
}

resource "aws_route_table_association" "associate_public_2" {
  subnet_id      = aws_subnet.csye6225_subnet_2_public.id
  route_table_id = aws_route_table.csye6225_public_rt.id
}

resource "aws_route" "public_route_table_igw_associtaion" {
  route_table_id         = aws_route_table.csye6225_public_rt.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.csye6225_igw.id
}

resource "aws_route_table_association" "associate_private_0" {
  subnet_id      = aws_subnet.csye6225_subnet_0_private.id
  route_table_id = aws_route_table.csye6225_private_rt.id
}

resource "aws_route_table_association" "associate_private_1" {
  subnet_id      = aws_subnet.csye6225_subnet_1_private.id
  route_table_id = aws_route_table.csye6225_private_rt.id
}

resource "aws_route_table_association" "associate_private_2" {
  subnet_id      = aws_subnet.csye6225_subnet_2_private.id
  route_table_id = aws_route_table.csye6225_private_rt.id
}

resource "random_uuid" "bucket_uuid" {}

resource "aws_kms_key" "mykey" {
  description             = "This key is used to encrypt bucket objects"
  deletion_window_in_days = 10
}


# Create a private S3 bucket with a unique name
resource "aws_s3_bucket" "webapp_bucket" {
  bucket        = random_uuid.bucket_uuid.result
  force_destroy = true
  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        sse_algorithm     = "aws:kms"
        kms_master_key_id = aws_kms_key.s3_key.arn
      }
    }
  }

  tags = {
    Name        = "Private S3 Bucket"
    Environment = "Dev"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "example" {
  bucket = aws_s3_bucket.webapp_bucket.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}


resource "aws_s3_bucket_lifecycle_configuration" "lifecycle_policy" {
  bucket = aws_s3_bucket.webapp_bucket.bucket

  rule {
    id     = "transition-to-IA"
    status = "Enabled"

    filter {}

    transition {
      days          = 30
      storage_class = "STANDARD_IA"
    }
  }
}

resource "aws_route53_record" "webapp_a_record" {
  zone_id = var.hosted_zone
  name    = "${var.hosted_zone_name}.sampurna.xyz"
  type    = "A"
  alias {
    name                   = aws_lb.csye6225_webapp_load_balancer.dns_name
    zone_id                = aws_lb.csye6225_webapp_load_balancer.zone_id
    evaluate_target_health = true
  }
}

resource "aws_iam_policy" "ec2_s3_cloudwatch_route53_policy" {
  name        = "ec2_s3_cloudwatch_route53_policy"
  description = "Policy to allow necessary actions for EC2, S3, CloudWatch, and Route 53"

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        # S3 Permissions
        Effect = "Allow",
        Action = [
          "s3:CreateBucket",
          "s3:DeleteBucket",
          "s3:PutBucketEncryption",
          "s3:PutBucketPolicy",
          "s3:PutBucketLifecycleConfiguration",
          "s3:ListBucket",
          "s3:DeleteObject",
          "s3:PutObject",
          "s3:GetObject"
        ],
        Resource = [
          "${aws_s3_bucket.webapp_bucket.arn}",
          "${aws_s3_bucket.webapp_bucket.arn}/*"
        ]
      },
      {
        # Route 53 Permissions
        Effect = "Allow",
        Action = [
          "route53:ListHostedZones",
          "route53:ChangeResourceRecordSets",
          "route53:GetHostedZone",
          "route53:ListResourceRecordSets"
        ],
        Resource = "*"
      },
      {
        # CloudWatch Logs Permissions
        Effect = "Allow",
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents",
          "logs:DescribeLogGroups",
          "logs:DescribeLogStreams"
        ],
        Resource = "*"
      },
      {
        # CloudWatch Metrics Permissions
        Effect = "Allow",
        Action = [
          "cloudwatch:PutMetricData",
          "cloudwatch:GetMetricData",
          "cloudwatch:GetMetricStatistics",
          "cloudwatch:ListMetrics"
        ],
        Resource = "*"
      },
      {
        # EC2 Describe Permissions
        Effect = "Allow",
        Action = [
          "ec2:DescribeVolumes",
          "ec2:DescribeTags",
          "ec2:DescribeInstances"
        ],
        Resource = "*"
      },
      {
        # Additional permissions for Parameter Store (SSM) and RDS
        Effect = "Allow",
        Action = [
          "ssm:GetParameters",
          "rds:DescribeDBInstances",
          "rds:DescribeDBClusters",
          "kms:*",
          "ec2:*",
          "secretsmanager:GetResourcePolicy",
          "secretsmanager:GetSecretValue",
          "secretsmanager:DescribeSecret",
          "secretsmanager:ListSecretVersionIds"
        ],
        Resource = "*"
      },
      {
        Effect   = "Allow",
        Action   = "SNS:Publish",
        Resource = "${aws_sns_topic.user_verification_trigger.arn}"
      }

    ]
  })
}
resource "aws_iam_role" "ec2_role" {
  name               = "ec2_role"
  assume_role_policy = <<EOF
    {
      "Version": "2012-10-17",
      "Statement": [
        {
          "Effect": "Allow",
          "Principal": {
            "Service": "ec2.amazonaws.com"
          },
          "Action": "sts:AssumeRole"
        }
      ]
    }
EOF
}


data "aws_caller_identity" "current" {}


resource "aws_iam_policy" "service_linked_role_policy" {
  name        = "ServiceLinkedRolePolicy"
  description = "Allow service-linked role use of the customer managed key"
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        # Principal = {
        #   AWS = [
        #     "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/aws-service-role/autoscaling.amazonaws.com/AWSServiceRoleForAutoScaling"
        #   ]
        # }
        Action = [
          "kms:Encrypt",
          "kms:Decrypt",
          "kms:ReEncrypt*",
          "kms:GenerateDataKey*",
          "kms:DescribeKey"
        ]
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "attach_service_linked_role_policy" {
  role       = aws_iam_role.ec2_role.name
  policy_arn = aws_iam_policy.service_linked_role_policy.arn
}



# resource "aws_iam_policy" "sns_full_access" {
#   name        = "SNSFullAccessPolicy"
#   description = "Grant full access to SNS"
#   policy = <<EOF
#     {
#       "Version": "2012-10-17",
#       "Statement": [
#         {
#           "Effect": "Allow",
#           "Action": "SNS:Publish",
#           "Resource": "${aws_sns_topic.user_verification_trigger.arn}"
#         }
#       ]
#     }
# EOF
# }

# resource "aws_iam_role_policy_attachment" "attach_sns_policy" {
#   role       = aws_iam_role.ec2_role.name
#   policy_arn = aws_iam_policy.sns_full_access.arn
# }


resource "aws_iam_role_policy_attachment" "attach_combined_policy" {
  role       = aws_iam_role.ec2_role.name
  policy_arn = aws_iam_policy.ec2_s3_cloudwatch_route53_policy.arn
}

resource "aws_iam_role_policy_attachment" "kms_full_access" {
  role       = aws_iam_role.ec2_role.name
  policy_arn = "arn:aws:iam::aws:policy/AWSKeyManagementServicePowerUser"
}

resource "aws_iam_instance_profile" "ec2_profile" {
  name = "ec2_instance_profile"
  role = aws_iam_role.ec2_role.name # Attach the IAM role
}
