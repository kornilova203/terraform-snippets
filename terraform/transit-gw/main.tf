provider "aws" {
  region = var.region
}

resource "aws_key_pair" "auth" {
  key_name   = "${var.prefix}-key"
  public_key = file("../../key.pub")
}

# VPC 1

resource "aws_vpc" "main1" {
  cidr_block = "10.0.0.0/24"

  tags = {
    Name = "${var.prefix}-vpc1"
  }
}

module "subnet1" {
  source     = "./../subnet"
  name       = "${var.prefix}-subnet1"
  vpc_id     = aws_vpc.main1.id
  cidr_block = "10.0.0.0/25"
}

resource "aws_internet_gateway" "gw1" {
  vpc_id = aws_vpc.main1.id

  tags = {
    Name = "${var.prefix}-ig1"
  }
}

resource "aws_route" "route_igw1" {
  route_table_id         = module.subnet1.route_table_id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.gw1.id
}

module "aws_security_group1" {
  source = "./../ssh_security_group"
  prefix = var.prefix
  vpc_id = aws_vpc.main1.id
}

resource "aws_instance" "public_instance1" {
  ami           = "ami-089950bc622d39ed8" # Amazon Linux 2 Kernel 5.10 AMI 2.0.20220719.0 x86_64 HVM gp2
  instance_type = "t2.micro"

  subnet_id                   = module.subnet1.subnet_id
  key_name                    = aws_key_pair.auth.key_name
  associate_public_ip_address = true
  vpc_security_group_ids      = [module.aws_security_group1.sg_id]

  tags = {
    Name = "${var.prefix}-public-instance1"
  }
}

# VPC 2

resource "aws_vpc" "main2" {
  cidr_block = "10.1.0.0/24"

  tags = {
    Name = "${var.prefix}-vpc2"
  }
}

module "subnet2" {
  source     = "./../subnet"
  name       = "${var.prefix}-subnet2"
  vpc_id     = aws_vpc.main2.id
  cidr_block = "10.1.0.0/25"
}

resource "aws_internet_gateway" "gw2" {
  vpc_id = aws_vpc.main2.id

  tags = {
    Name = "${var.prefix}-ig2"
  }
}

resource "aws_route" "route_igw2" {
  route_table_id         = module.subnet2.route_table_id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.gw2.id
}

module "aws_security_group2" {
  source = "./../ssh_security_group"
  prefix = var.prefix
  vpc_id = aws_vpc.main2.id
}

resource "aws_instance" "private_instance2" {
  ami           = "ami-089950bc622d39ed8" # Amazon Linux 2 Kernel 5.10 AMI 2.0.20220719.0 x86_64 HVM gp2
  instance_type = "t2.micro"

  subnet_id              = module.subnet2.subnet_id
  key_name               = aws_key_pair.auth.key_name
  vpc_security_group_ids = [module.aws_security_group2.sg_id]

  tags = {
    Name = "${var.prefix}-private-instance2"
  }
}

# Transit gateway

resource "aws_ec2_transit_gateway" "tgw" {
  description = "Connect public subnet in first VPC and private subnet in second VPC"

  tags = {
    Name = "${var.prefix}-transit-gateway"
  }
}

resource "aws_ec2_transit_gateway_vpc_attachment" "tgw_attachment1" {
  subnet_ids         = [module.subnet1.subnet_id]
  transit_gateway_id = aws_ec2_transit_gateway.tgw.id
  vpc_id             = aws_vpc.main1.id
}

resource "aws_route" "route_tgw1" {
  route_table_id         = module.subnet1.route_table_id
  destination_cidr_block = module.subnet2.subnet_cidr_block
  transit_gateway_id     = aws_ec2_transit_gateway.tgw.id
}

resource "aws_ec2_transit_gateway_vpc_attachment" "tgw_attachment2" {
  subnet_ids         = [module.subnet2.subnet_id]
  transit_gateway_id = aws_ec2_transit_gateway.tgw.id
  vpc_id             = aws_vpc.main2.id
}

resource "aws_route" "route_tgw2" {
  route_table_id         = module.subnet2.route_table_id
  destination_cidr_block = module.subnet1.subnet_cidr_block
  transit_gateway_id     = aws_ec2_transit_gateway.tgw.id
}
