terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }

    tls = {
      source  = "hashicorp/tls"
      version = "~> 4.0"
    }

    local = {
      source  = "hashicorp/local"
      version = "~> 2.0"
    }
  }
}

# ---------------------------------
# AWS Provider
# ---------------------------------
provider "aws" {
  region  = var.aws_region
  profile = var.aws_profile
}

# ---------------------------------
# SSH Key Generation
# ---------------------------------
resource "tls_private_key" "ssh_key" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "local_file" "private_key" {
  content         = tls_private_key.ssh_key.private_key_pem
  filename        = "./generated-key.pem"
  file_permission = "0400"
}

resource "aws_key_pair" "generated_key" {
  key_name   = "assignment-generated-key"
  public_key = tls_private_key.ssh_key.public_key_openssh
}

# ---------------------------------
# VPC
# ---------------------------------
resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "assignment-vpc"
  }
}

# ---------------------------------
# Internet Gateway
# ---------------------------------
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "assignment-igw"
  }
}

# ---------------------------------
# Public Subnet
# ---------------------------------
resource "aws_subnet" "public_subnet" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.public_subnet_cidr
  map_public_ip_on_launch = true

  tags = {
    Name = "public-subnet"
  }
}

# ---------------------------------
# Private Subnet
# ---------------------------------
resource "aws_subnet" "private_subnet" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.private_subnet_cidr
  map_public_ip_on_launch = false

  tags = {
    Name = "private-subnet"
  }
}

# ---------------------------------
# Public Route Table
# ---------------------------------
resource "aws_route_table" "public_rt" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = {
    Name = "public-route-table"
  }
}

resource "aws_route_table_association" "public_assoc" {
  subnet_id      = aws_subnet.public_subnet.id
  route_table_id = aws_route_table.public_rt.id
}

# ---------------------------------
# Private Route Table
# No Internet Access
# ---------------------------------
resource "aws_route_table" "private_rt" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "private-route-table"
  }
}

resource "aws_route_table_association" "private_assoc" {
  subnet_id      = aws_subnet.private_subnet.id
  route_table_id = aws_route_table.private_rt.id
}

# ---------------------------------
# Public Security Group
# SSH + HTTP Allowed
# ---------------------------------
resource "aws_security_group" "public_sg" {
  name        = "public-security-group"
  description = "Allow SSH and HTTP"
  vpc_id      = aws_vpc.main.id

  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "HTTP"
    from_port   = 80
    to_port     = 80
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
    Name = "public-sg"
  }
}

# ---------------------------------
# Private Security Group
# SSH only from Public SG
# ---------------------------------
resource "aws_security_group" "private_sg" {
  name        = "private-security-group"
  description = "Allow SSH only from public security group"
  vpc_id      = aws_vpc.main.id

  ingress {
    description     = "SSH from Bastion/Public"
    from_port       = 22
    to_port         = 22
    protocol        = "tcp"
    security_groups = [aws_security_group.public_sg.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "private-sg"
  }
}

# ---------------------------------
# Latest Ubuntu Linux AMI
# ---------------------------------
data "aws_ami" "ubuntu_linux" {
  most_recent = true
  owners      = ["099720109477"] # Canonical

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

# ---------------------------------
# Public EC2 Instance
# ---------------------------------
resource "aws_instance" "public_ec2" {
  ami                         = data.aws_ami.ubuntu_linux.id
  instance_type               = "t3.micro"
  subnet_id                   = aws_subnet.public_subnet.id
  vpc_security_group_ids      = [aws_security_group.public_sg.id]
  associate_public_ip_address = true
  key_name                    = aws_key_pair.generated_key.key_name

  tags = {
    Name = "public-ec2"
  }
}

# ---------------------------------
# Bastion Host
# ---------------------------------
resource "aws_instance" "bastion_host" {
  ami                         = data.aws_ami.ubuntu_linux.id
  instance_type               = "t3.micro"
  subnet_id                   = aws_subnet.public_subnet.id
  vpc_security_group_ids      = [aws_security_group.public_sg.id]
  associate_public_ip_address = true
  key_name                    = aws_key_pair.generated_key.key_name

  tags = {
    Name = "bastion-host"
  }
}

# ---------------------------------
# Private EC2 Instance
# ---------------------------------
resource "aws_instance" "private_ec2" {
  ami                         = data.aws_ami.ubuntu_linux.id
  instance_type               = "t3.micro"
  subnet_id                   = aws_subnet.private_subnet.id
  vpc_security_group_ids      = [aws_security_group.private_sg.id]
  associate_public_ip_address = false
  key_name                    = aws_key_pair.generated_key.key_name

  tags = {
    Name = "private-ec2"
  }
}

