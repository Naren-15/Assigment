terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.0"
    }
  }
}
# Configure the AWS Provider
provider "aws" {
  region = "ap-south-1"
}
# Creating a VPC
resource "aws_vpc" "myvpc" {
  cidr_block       = "10.0.0.0/16"
  instance_tenancy = "default"

  tags = {
    Name = "Assignment-VPC"
  }
}
# Subnets
resource "aws_subnet" "subpub" {
  vpc_id     = aws_vpc.myvpc.id
  cidr_block = "10.0.1.0/24"
  availability_zone = "ap-south-1a"

  tags = {
    Name = "SUBPUB"
  }
}
resource "aws_subnet" "subpvt" {
  vpc_id     = aws_vpc.myvpc.id
  cidr_block = "10.0.2.0/24"
  availability_zone = "ap-south-1b"

  tags = {
    Name = "SUBPVT"
  }
}
# InternetGateway
resource "aws_internet_gateway" "tigw" {
  vpc_id = aws_vpc.myvpc.id

  tags = {
    Name = "TIGW"
  }
}
# RouteTable
resource "aws_route_table" "rtpub" {
  vpc_id = aws_vpc.myvpc.id

  route {
    cidr_block = "0.0.0.0"
    gateway_id = aws_internet_gateway.tigw.id
  }
  tags = {
    Name = "RTPUB"
  }
}
resource "aws_route_table" "rtpvt" {
  vpc_id = aws_vpc.myvpc.id

  route {
    cidr_block = "0.0.0.0"
    gateway_id = aws_nat_gateway.tnat.id
  }
  tags = {
    Name = "RTPVT"
  }
}
# RouteTable-Association
resource "aws_route_table_association" "rtpubasc" {
  subnet_id      = aws_subnet.subpub.id
  route_table_id = aws_route_table.rtpub.id
}
resource "aws_route_table_association" "rtpvtasc" {
  subnet_id      = aws_subnet.subpvt.id
  route_table_id = aws_route_table.rtpvt.id
}
# Elastic-IP
resource "aws_eip" "teip" {
  vpc      = true
}
# NAT-Gateway
resource "aws_nat_gateway" "tnat" {
  allocation_id = aws_eip.teip.id
  subnet_id     = aws_subnet.subpub.id

  tags = {
    Name = "TNAT"
  }
}
# Security-Group
resource "aws_security_group" "pubsec" {
  name        = "allow_tls"
  description = "Allow TLS inbound traffic"
  vpc_id      = aws_vpc.myvpc.id

  ingress {
    description      = "All"
    from_port        = 0
    to_port          = 65535
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
  #  ipv6_cidr_blocks = [aws_vpc.main.ipv6_cidr_block]
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = {
    Name = "PUB-SEC"
  }
}
resource "aws_security_group" "pvtsec" {
  name        = "allow_tls"
  description = "Allow TLS inbound traffic"
  vpc_id      = aws_vpc.myvpc.id

  ingress {
    description      = "https"
    from_port        = 443
    to_port          = 443
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
  #  ipv6_cidr_blocks = [aws_vpc.main.ipv6_cidr_block]
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = {
    Name = "PVT-SEC"
  }
}

# Ec2-instance
resource "aws_instance" "web" {
  ami           = "ami-03d3eec31be6ef6f9"
  instance_type = "t2.micro"
  associate_public_ip_address = true
  vpc_security_group_ids = [aws_security_group.pubsec.id]
  subnet_id = aws_subnet.subpub.id

  tags = {
    Name = "webserver"
  }
}
resource "aws_instance" "app" {
  ami           = "ami-03d3eec31be6ef6f9"
  instance_type = "t2.micro"
  #associate_public_ip_address = true
  vpc_security_group_ids = [aws_security_group.pvtsec.id]
  subnet_id = aws_subnet.subpvt.id

  tags = {
    Name = "appserver"
  }
}