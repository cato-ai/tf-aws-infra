resource "aws_instance" "webapp_server" {
  ami           = var.ami_name
  instance_type = "t2.small"
  subnet_id     = aws_subnet.csye6225_subnet_0_public.id
  vpc_security_group_ids = [
    aws_security_group.application_security_group.id
  ]
  root_block_device {
    volume_type           = "gp2"
    volume_size           = var.volume_size
    delete_on_termination = true
  }

  depends_on = [aws_db_instance.csye6225_webapp_db]

  user_data = <<-EOF
    #!/bin/bash
    touch /opt/webapp/.env
    DB_NAME="${aws_db_instance.csye6225_webapp_db.db_name}"
    DB_USER="${aws_db_instance.csye6225_webapp_db.username}"
    DB_PASSWORD="${aws_db_instance.csye6225_webapp_db.password}"
    echo DB_CONNECTION_URL="${aws_db_instance.csye6225_webapp_db.endpoint}" >> /opt/webapp/.env
    echo DB_NAME=$DB_NAME >> /opt/webapp/.env
    echo DB_USER=$DB_USER >> /opt/webapp/.env
    echo DB_PASSWORD=$DB_PASSWORD >> /opt/webapp/.env
    echo SERVER_HOSTNAME="${var.SERVER_HOSTNAME}" >> /opt/webapp/.env
    echo SERVER_PORT_NUMBER="${var.SERVER_PORT_NUMBER}" >> /opt/webapp/.env

    # Set permissions for the .env file
    chmod 600 /opt/webapp/.env
    sudo rm -rf /opt/webapp/build
    systemctl restart csye6225.service
  EOF
}

resource "aws_security_group" "application_security_group" {
  name        = "application_security_group"
  description = "Security Group for web application EC2 instances"
  vpc_id      = aws_vpc.csye6225_vpc.id

  # Ingress rules
  ingress {
    description = "Allow SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "Allow HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "Allow HTTPS"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Custom application port (example: 8080)
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