# resource "aws_instance" "webapp_server" {
#   ami           = var.ami_name
#   instance_type = "t2.small"
#   subnet_id     = aws_subnet.csye6225_subnet_0_private.id
#   vpc_security_group_ids = [
#     aws_security_group.application_security_group.id
#   ]


#   root_block_device {
#     volume_type           = "gp2"
#     volume_size           = var.volume_size
#     delete_on_termination = true
#   }

#   depends_on = [aws_db_instance.csye6225_webapp_db, aws_s3_bucket.webapp_bucket]

#   user_data = <<-EOF
#     #!/bin/bash
#     touch /opt/webapp/.env
#     DB_NAME="${aws_db_instance.csye6225_webapp_db.db_name}"
#     DB_USER="${aws_db_instance.csye6225_webapp_db.username}"
#     DB_PASSWORD="${aws_db_instance.csye6225_webapp_db.password}"
#     S3_NAME="${aws_s3_bucket.webapp_bucket.bucket}"
#     echo DB_CONNECTION_URL="postgres://${var.DB_USERNAME}:${var.DB_PASSWORD}@${aws_db_instance.csye6225_webapp_db.endpoint}/$DB_NAME" >> /opt/webapp/.env
#     echo SERVER_HOSTNAME="${var.SERVER_HOSTNAME}" >> /opt/webapp/.env
#     echo SERVER_PORT_NUMBER="${var.SERVER_PORT_NUMBER}" >> /opt/webapp/.env
#     echo S3_BUCKET_NAME=$S3_NAME >> /opt/webapp/.env

#     # Set permissions for the .env file
#     sudo chmod 600 /opt/webapp/.env
#     sudo chown -R csye6225:csye6225 /opt/webapp/.env
#     sudo rm -rf /opt/webapp/build 
#     cat <<EOT > /opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json
#     {
#     "metrics": {
#         "namespace": "CWAgent",
#         "metrics_collected": {
#         "statsd": 
#             {
#                 "service_address": ":8125",
#                 "metrics_collection_interval": 1,
#                 "metrics_aggregation_interval": 60
#             }
#         }
#     },
#     "logs": {
#         "logs_collected": {
#         "files": 
#             {
#                 "collect_list": [
#                     {
#                         "file_path": "/opt/webapp/webapp.log",
#                         "log_group_name": "/aws/ec2/webapp_csye6225",
#                         "log_stream_name": "webapp",
#                         "retention_in_days": 1
#                     }
#                 ]
#             }
#         }
#     }
#     }
#     EOT

#     sudo chown cwagent:cwagent /opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json
#     sudo chmod 644 /opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json
#     sudo chmod 644 /var/log/syslog
#     sudo systemctl daemon-reload
#     sudo systemctl restart amazon-cloudwatch-agent

#     systemctl restart csye6225.service

#   EOF

#   iam_instance_profile = aws_iam_instance_profile.ec2_profile.name
# }

resource "aws_security_group" "application_security_group" {
  name        = "application_security_group"
  description = "Security Group for web application EC2 instances"
  vpc_id      = aws_vpc.csye6225_vpc.id

  # Ingress rules
  ingress {
    description = "Allow Load Balancer requests"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "Allow server traffic"
    from_port   = 3000
    to_port     = 3000
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Egress rule - allows all outbound traffic
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

}

resource "aws_security_group" "database_security_group" {
  name        = "database_security_group"
  description = "Security Group for RDS Postgresql instnaces"
  vpc_id      = aws_vpc.csye6225_vpc.id

  # Ingress rules
  ingress {
    description     = "Allow Postgresql"
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    cidr_blocks     = ["0.0.0.0/0"]
    security_groups = [aws_security_group.application_security_group.id]
  }

  # Egress rule - allows all outbound traffic
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_db_parameter_group" "csye6225_db_parameter_group" {
  name        = "csye6225-db-pg"
  family      = "postgres16"
  description = "This is the database to use for webapp created for CSYE6225"

  parameter {
    name         = "rds.force_ssl"
    value        = "0"
    apply_method = "pending-reboot"
  }
}

resource "aws_db_subnet_group" "csye6225_db_subnet_group" {
  name       = "csye6225-db-subnet-group"
  subnet_ids = [aws_subnet.csye6225_subnet_0_private.id, aws_subnet.csye6225_subnet_1_private.id, aws_subnet.csye6225_subnet_2_private.id]
  tags = {
    Name = "csye6225-db-subnet-group"
  }
}


resource "aws_db_instance" "csye6225_webapp_db" {
  identifier             = "csye6225-webapp-db"
  engine                 = "postgres"
  instance_class         = "db.t4g.micro"
  db_name                = var.DB_NAME
  allocated_storage      = 20
  multi_az               = false
  username               = var.DB_USERNAME
  password               = var.DB_PASSWORD
  publicly_accessible    = false
  skip_final_snapshot    = true
  vpc_security_group_ids = [aws_security_group.database_security_group.id]
  db_subnet_group_name   = aws_db_subnet_group.csye6225_db_subnet_group.id
  parameter_group_name   = aws_db_parameter_group.csye6225_db_parameter_group.id
  depends_on             = [aws_vpc.csye6225_vpc, aws_subnet.csye6225_subnet_0_private]
}

resource "aws_security_group" "load_balancer_security_group" {
  name        = "load_balancer_security_group"
  description = "Security Group for Load Balancer that can access ec2 instances"
  vpc_id      = aws_vpc.csye6225_vpc.id

  # Ingress rules
  ingress {
    description     = "Allow on 80"
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    cidr_blocks     = ["0.0.0.0/0"]
    security_groups = [aws_security_group.application_security_group.id]
  }

  ingress {
    description     = "Allow on 443"
    from_port       = 443
    to_port         = 443
    protocol        = "tcp"
    cidr_blocks     = ["0.0.0.0/0"]
    security_groups = [aws_security_group.application_security_group.id]
  }


  # Egress rule - allows all outbound traffic
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_cloudwatch_metric_alarm" "high_cpu" {
  alarm_name          = "high-cpu-usage"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = 30
  statistic           = "Average"
  threshold           = 11.0
  alarm_description   = "This alarm triggers when CPU usage exceeds 5%"
  dimensions = {
    AutoScalingGroupName = aws_autoscaling_group.webapp_auto_scaler.name
  }

  alarm_actions = [aws_autoscaling_policy.webapp_scale_up.arn]
}

resource "aws_cloudwatch_metric_alarm" "low_cpu" {
  alarm_name          = "low-cpu-usage"
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = 1
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = 30
  statistic           = "Average"
  threshold           = 8.0
  alarm_description   = "This alarm triggers when CPU usage falls below 3%"
  dimensions = {
    AutoScalingGroupName = aws_autoscaling_group.webapp_auto_scaler.name
  }

  alarm_actions = [aws_autoscaling_policy.webapp_scale_down.arn]
}


resource "aws_autoscaling_policy" "webapp_scale_up" {
  name                   = "webapp-csye6225-scale-up-policy"
  autoscaling_group_name = aws_autoscaling_group.webapp_auto_scaler.name
  adjustment_type        = "ChangeInCapacity"
  cooldown               = 60
  scaling_adjustment     = 1
}

resource "aws_autoscaling_policy" "webapp_scale_down" {
  name                   = "webapp-csye6225-scale-down-policy"
  autoscaling_group_name = aws_autoscaling_group.webapp_auto_scaler.name
  adjustment_type        = "ChangeInCapacity"
  cooldown               = 50
  scaling_adjustment     = -1
}


resource "aws_autoscaling_group" "webapp_auto_scaler" {
  name = "autoscaler-csye6225-webapp"
  launch_template {
    id      = aws_launch_template.auto_scaler_launch_template_webapp.id
    version = "$Latest"
  }

  vpc_zone_identifier       = [aws_subnet.csye6225_subnet_0_public.id, aws_subnet.csye6225_subnet_1_public.id, aws_subnet.csye6225_subnet_2_public.id]
  health_check_type         = "EBS"
  health_check_grace_period = 500
  enabled_metrics           = ["GroupMinSize", "GroupMaxSize", "GroupDesiredCapacity", "GroupInServiceInstances", "GroupPendingInstances", "GroupStandbyInstances", "GroupTerminatingInstances"]
  max_size                  = 5
  min_size                  = 3
  desired_capacity          = 3

  target_group_arns = [aws_lb_target_group.webapp_lb_target_group.arn]
}


resource "aws_launch_template" "auto_scaler_launch_template_webapp" {
  name_prefix = "webapp-launch-template"
  description = "Launch template for Auto Scaling Group"

  image_id      = var.ami_name
  instance_type = "t2.small"


  user_data = base64encode(
    <<-EOF
    #!/bin/bash
    touch /opt/webapp/.env
    DB_NAME="${aws_db_instance.csye6225_webapp_db.db_name}"
    DB_USER="${aws_db_instance.csye6225_webapp_db.username}"
    DB_PASSWORD="${aws_db_instance.csye6225_webapp_db.password}"
    S3_NAME="${aws_s3_bucket.webapp_bucket.bucket}"
    echo DB_CONNECTION_URL="postgres://${var.DB_USERNAME}:${var.DB_PASSWORD}@${aws_db_instance.csye6225_webapp_db.endpoint}/$DB_NAME" >> /opt/webapp/.env
    echo SERVER_HOSTNAME="${var.SERVER_HOSTNAME}" >> /opt/webapp/.env
    echo SERVER_PORT_NUMBER="${var.SERVER_PORT_NUMBER}" >> /opt/webapp/.env
    echo S3_BUCKET_NAME=$S3_NAME >> /opt/webapp/.env

    # Set permissions for the .env file
    sudo chmod 600 /opt/webapp/.env
    sudo chown -R csye6225:csye6225 /opt/webapp/.env
    sudo rm -rf /opt/webapp/build 
    cat <<EOT > /opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json
    {
    "metrics": {
        "namespace": "CWAgent",
        "metrics_collected": {
        "statsd": 
            {
                "service_address": ":8125",
                "metrics_collection_interval": 1,
                "metrics_aggregation_interval": 60
            }
        }
    },
    "logs": {
        "logs_collected": {
        "files": 
            {
                "collect_list": [
                    {
                        "file_path": "/opt/webapp/webapp.log",
                        "log_group_name": "/aws/ec2/webapp_csye6225",
                        "log_stream_name": "webapp",
                        "retention_in_days": 1
                    }
                ]
            }
        }
    }
    }
    EOT

    sudo chown cwagent:cwagent /opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json
    sudo chmod 644 /opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json
    sudo chmod 644 /var/log/syslog
    sudo systemctl daemon-reload
    sudo systemctl restart amazon-cloudwatch-agent

    systemctl restart csye6225.service

  EOF
  )

  # vpc_security_group_ids = [aws_security_group.application_security_group.id]
  iam_instance_profile {
    name = aws_iam_instance_profile.ec2_profile.name
  }
  network_interfaces {
    associate_public_ip_address = true
    security_groups             = [aws_security_group.application_security_group.id]
  }

  key_name = "CSYE6225-07"
}


resource "aws_lb" "csye6225_webapp_load_balancer" {
  name                       = "csye6225-webapp-load-balancer"
  internal                   = false
  security_groups            = [aws_security_group.load_balancer_security_group.id]
  subnets                    = [aws_subnet.csye6225_subnet_0_public.id, aws_subnet.csye6225_subnet_1_public.id, aws_subnet.csye6225_subnet_2_public.id]
  enable_deletion_protection = false
  load_balancer_type         = "application"
  enable_http2               = true

}

resource "aws_lb_target_group" "webapp_lb_target_group" {
  name     = "webapp-lb-target-group"
  port     = 3000
  protocol = "HTTP"
  vpc_id   = aws_vpc.csye6225_vpc.id

  health_check {
    protocol            = "HTTP"
    path                = "/healthz"
    interval            = 10
    timeout             = 5
    healthy_threshold   = 5
    unhealthy_threshold = 2
  }
}

resource "aws_lb_listener" "webapp_api_listener" {
  load_balancer_arn = aws_lb.csye6225_webapp_load_balancer.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.webapp_lb_target_group.arn
  }
}
