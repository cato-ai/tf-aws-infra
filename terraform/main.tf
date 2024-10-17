resource "aws_instance" "webapp_server" {
  ami           = var.ami_name
  instance_type = "t2.small"
  subnet_id     = aws_subnet.csye6225_subnet_0_public.id
  vpc_security_group_ids = [
    aws_security_group.application_security_group.id
  ]
  root_block_device {
    volume_type = "gp2"
    volume_size = var.volume_size
    delete_on_termination = true
  }

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