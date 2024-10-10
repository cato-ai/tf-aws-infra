data "aws_availability_zones" "available" {
  state = "available"
}

resource "aws_subnet" "csye6225_subnet_0_public" {
  cidr_block              = cidrsubnet(var.vpc_ip, 8, 0)
  map_public_ip_on_launch = "true"
  vpc_id                  = aws_vpc.csye6225_vpc.id
  tags = {
    Name = "csye6225_subnet_0_public"
  }
  availability_zone = var.subnet_0_az
}

resource "aws_subnet" "csye6225_subnet_0_private" {
  cidr_block              = cidrsubnet(var.vpc_ip, 8, 1)
  map_public_ip_on_launch = "false"
  vpc_id                  = aws_vpc.csye6225_vpc.id
  tags = {
    Name = "csye6225_subnet_0_private"
  }
  availability_zone = var.subnet_0_az
}

resource "aws_subnet" "csye6225_subnet_1_public" {
  cidr_block              = cidrsubnet(var.vpc_ip, 8, 2)
  map_public_ip_on_launch = "true"
  vpc_id                  = aws_vpc.csye6225_vpc.id
  tags = {
    Name = "csye6225_subnet_1_public"
  }
  availability_zone = var.subnet_1_az

}

resource "aws_subnet" "csye6225_subnet_1_private" {
  cidr_block              = cidrsubnet(var.vpc_ip, 8, 3)
  map_public_ip_on_launch = "false"
  vpc_id                  = aws_vpc.csye6225_vpc.id
  tags = {
    Name = "csye6225_subnet_1_private"
  }
  availability_zone = var.subnet_1_az
}

resource "aws_subnet" "csye6225_subnet_2_public" {
  cidr_block              = cidrsubnet(var.vpc_ip, 8, 4)
  map_public_ip_on_launch = "true"
  vpc_id                  = aws_vpc.csye6225_vpc.id
  tags = {
    Name = "csye6225_subnet_2_public"
  }
  availability_zone = var.subnet_2_az
}

resource "aws_subnet" "csye6225_subnet_2_private" {
  cidr_block              = cidrsubnet(var.vpc_ip, 8, 5)
  map_public_ip_on_launch = "false"
  vpc_id                  = aws_vpc.csye6225_vpc.id
  tags = {
    Name = "csye6225_subnet_2_private"
  }
  availability_zone = var.subnet_2_az
}




