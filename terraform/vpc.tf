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

resource "aws_route_table_association" "associate_igw" {
  gateway_id     = aws_internet_gateway.csye6225_igw.id
  route_table_id = aws_route_table.csye6225_public_rt.id
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
