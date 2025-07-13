terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0" # Use latest version if possible
    }
  }
}

#Configuration for AWS provider
provider "aws" {
  region  = var.region # Use the default region or specify a region   # Use the default profile or specify a profile
}

#Create a VPC with 2 private and public subnets respectively
resource "aws_vpc" "main" {
  cidr_block = "192.0.0.0/16"
  tags = {
    Name = "Main"
  }
}

resource "aws_subnet" "private-us-east-1a" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = var.subnet_cidr_blocks.private-us-east-1a
  availability_zone = "${var.region}a"

  tags = {
    Name = "private-us-east-1a"
  }
}
resource "aws_subnet" "public-us-east-1a" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.subnet_cidr_blocks.public-us-east-1a
  availability_zone       = "${var.region}a"
  map_public_ip_on_launch = true

  tags = {
    Name = "public-us-east-1a"
  }
}
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name    = "Jenkins_IGW"
    Service = "Jenkins"

  }
}

resource "aws_eip" "nat" {
  domain = "vpc"

  tags = {
    Name = "nat"
  }
}

resource "aws_nat_gateway" "nat" {
  allocation_id = aws_eip.nat.id
  subnet_id     = aws_subnet.public-us-east-1a.id

  depends_on = [aws_internet_gateway.igw]
  tags = {
    Name = "nat"
  }
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id
  route {
    cidr_block                 = "0.0.0.0/0"
    gateway_id                 = aws_internet_gateway.igw.id
  }
  tags = {
    Name = "public"
  }
}

resource "aws_route_table" "private" {
  vpc_id = aws_vpc.main.id
  route {
    cidr_block                 = "0.0.0.0/0"
    nat_gateway_id             = aws_nat_gateway.nat.id
    
    
  }
  tags = {
    Name = "private"
  }
}

resource "aws_route_table_association" "private-us-east-1a" {
  subnet_id      = aws_subnet.private-us-east-1a.id
  route_table_id = aws_route_table.private.id
}

resource "aws_route_table_association" "public-us-east-1a" {
  subnet_id      = aws_subnet.public-us-east-1a.id
  route_table_id = aws_route_table.public.id
}

resource "aws_security_group" "jenkins_sg" {
  name        = "jenkins-sg"
  description = "Allow SSH into Jenkins Instance"
  vpc_id      = aws_vpc.main.id
  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.subnet_cidr_blocks["public-us-east-1a"]]
  }
  ingress {
    description = "Jenkins UI"
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = {
    Name = "jenkins-sg"
  }
}
resource "aws_instance" "jenkins" {
  ami           = "ami-0150ccaf51ab55a51" # Replace with a valid AMI ID for your region
  instance_type = "t2.medium"                 #Replace with your desired instance type
  subnet_id     = aws_subnet.public-us-east-1a.id
  key_name      = "Jenkins-Server" # Replace with your key pair name (mine was created manually in AWS)
  tags = {
    Name = "Jenkins Instance"
  }

  vpc_security_group_ids      = [aws_security_group.jenkins_sg.id]
  associate_public_ip_address = true

  # User data script to install Docker and run Jenkins
  # This script will be executed on instance creation
  # It updates the system, installs Docker, and runs Jenkins in a container
  # Make sure to adjust the script as needed for your specific requirements
  user_data = <<-EOF
    #!/bin/bash
    dnf update -y
    dnf install -y docker git curl unzip
    systemctl enable --now docker
    usermod -aG docker ec2-user

    docker run -d \
      --name jenkins \
      -p 8080:8080 \
      -v /var/run/docker.sock:/var/run/docker.sock \
      -v jenkins_home:/var/jenkins_home \
      --user root \
      jenkins/jenkins:lts
  EOF
}

resource "aws_s3_bucket" "frontend" {
  bucket_prefix = "jenkins-bucket-"
  force_destroy = true
  tags = {
    Name = "Jenkins Bucket"
  }
}

  

