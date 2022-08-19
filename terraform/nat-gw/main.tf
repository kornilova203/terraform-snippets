provider "aws" {
  region = var.region
}

resource "aws_vpc" "main" {
  cidr_block = "10.0.0.0/24"

  tags = {
    Name = "${var.prefix}-vpc"
  }
}

module "public_subnet" {
  source     = "./subnet"
  name       = "${var.prefix}-public-subnet"
  vpc_id     = aws_vpc.main.id
  cidr_block = "10.0.0.0/25"
}

resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "${var.prefix}-ig"
  }
}

resource "aws_route" "route_igw" {
  route_table_id         = module.public_subnet.route_table_id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.gw.id
}

module "private_subnet" {
  source     = "./subnet"
  name       = "${var.prefix}-private-subnet"
  vpc_id     = aws_vpc.main.id
  cidr_block = "10.0.0.128/25"
}

resource "aws_key_pair" "auth" {
  key_name   = "${var.prefix}-key"
  public_key = file("../../key.pub")
}

resource "aws_security_group" "allow_ssh" {
  name        = "${var.prefix}-allow-ssh-sg"
  description = "Allow SSH inbound traffic"
  vpc_id      = aws_vpc.main.id

  ingress {
    description      = "SSH"
    from_port        = 22
    to_port          = 22
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }
}

resource "aws_instance" "public_instance" {
  ami           = "ami-089950bc622d39ed8" # Amazon Linux 2 Kernel 5.10 AMI 2.0.20220719.0 x86_64 HVM gp2
  instance_type = "t2.micro"

  subnet_id                   = module.public_subnet.subnet_id
  key_name                    = aws_key_pair.auth.key_name
  associate_public_ip_address = true
  vpc_security_group_ids      = [aws_security_group.allow_ssh.id]

  tags = {
    Name = "${var.prefix}-public-instance"
  }
}

resource "aws_eip" "nat" {
}

resource "aws_nat_gateway" "gw" {
  allocation_id = aws_eip.nat.id
  subnet_id     = module.public_subnet.subnet_id

  tags = {
    Name = "${var.prefix}-nat-gw"
  }

  # To ensure proper ordering, it is recommended to add an explicit dependency
  # on the Internet Gateway for the VPC.
  depends_on = [aws_internet_gateway.gw]
}

resource "aws_route" "route_nat_gw" {
  route_table_id         = module.private_subnet.route_table_id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_nat_gateway.gw.id
}

resource "aws_instance" "private_instance" {
  ami           = "ami-089950bc622d39ed8" # Amazon Linux 2 Kernel 5.10 AMI 2.0.20220719.0 x86_64 HVM gp2
  instance_type = "t2.micro"

  subnet_id                   = module.private_subnet.subnet_id
  key_name                    = aws_key_pair.auth.key_name
  vpc_security_group_ids      = [aws_security_group.allow_ssh.id]

  tags = {
    Name = "${var.prefix}-private-instance"
  }
}