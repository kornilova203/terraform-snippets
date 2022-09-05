module "variables" {
  source = "./../variables"
}

provider "aws" {
  region = module.variables.region
}

resource "aws_key_pair" "auth" {
  key_name   = "${module.variables.prefix}-key"
  public_key = file("../../key.pub")
}

# VPC 1

resource "aws_vpc" "main1" {
  cidr_block = "10.0.0.0/24"

  tags = {
    Name = "${module.variables.prefix}-vpc1"
  }
}

module "subnet1" {
  source     = "./../subnet"
  name       = "${module.variables.prefix}-subnet1"
  vpc_id     = aws_vpc.main1.id
  cidr_block = "10.0.0.0/25"
}

resource "aws_internet_gateway" "gw1" {
  vpc_id = aws_vpc.main1.id

  tags = {
    Name = "${module.variables.prefix}-ig1"
  }
}

resource "aws_route" "route_igw1" {
  route_table_id         = module.subnet1.route_table_id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.gw1.id
}

module "aws_security_group1" {
  source = "./../ssh_security_group"
  prefix = module.variables.prefix
  vpc_id = aws_vpc.main1.id
}

resource "aws_instance" "public_instance1" {
  ami           = module.variables.ami
  instance_type = module.variables.instance_type

  subnet_id                   = module.subnet1.subnet_id
  key_name                    = aws_key_pair.auth.key_name
  associate_public_ip_address = true
  vpc_security_group_ids      = [module.aws_security_group1.sg_id]

  tags = {
    Name = "${module.variables.prefix}-public-instance1"
  }
}

# VPC 2

resource "aws_vpc" "main2" {
  cidr_block = "10.1.0.0/24"

  tags = {
    Name = "${module.variables.prefix}-vpc2"
  }
}

module "subnet2" {
  source     = "./../subnet"
  name       = "${module.variables.prefix}-subnet2"
  vpc_id     = aws_vpc.main2.id
  cidr_block = "10.1.0.0/25"
}

resource "aws_internet_gateway" "gw2" {
  vpc_id = aws_vpc.main2.id

  tags = {
    Name = "${module.variables.prefix}-ig2"
  }
}

resource "aws_route" "route_igw2" {
  route_table_id         = module.subnet2.route_table_id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.gw2.id
}

module "aws_security_group2" {
  source = "./../ssh_security_group"
  prefix = module.variables.prefix
  vpc_id = aws_vpc.main2.id
}

resource "aws_instance" "private_instance2" {
  ami           = module.variables.ami
  instance_type = module.variables.instance_type

  subnet_id              = module.subnet2.subnet_id
  key_name               = aws_key_pair.auth.key_name
  vpc_security_group_ids = [module.aws_security_group2.sg_id]

  tags = {
    Name = "${module.variables.prefix}-private-instance2"
  }
}

# Transit gateway

resource "aws_ec2_transit_gateway" "tgw" {
  description = "Connect public subnet in first VPC and private subnet in second VPC"

  tags = {
    Name = "${module.variables.prefix}-transit-gateway"
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
