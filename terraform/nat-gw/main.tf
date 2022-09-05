module "variables" {
  source = "./../variables"
}

provider "aws" {
  region = module.variables.region
}

resource "aws_vpc" "main" {
  cidr_block = "10.0.0.0/24"

  tags = {
    Name = "${module.variables.prefix}-vpc"
  }
}

module "public_subnet" {
  source     = "./../subnet"
  name       = "${module.variables.prefix}-public-subnet"
  vpc_id     = aws_vpc.main.id
  cidr_block = "10.0.0.0/25"
}

resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "${module.variables.prefix}-ig"
  }
}

resource "aws_route" "route_igw" {
  route_table_id         = module.public_subnet.route_table_id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.gw.id
}

module "private_subnet" {
  source     = "./../subnet"
  name       = "${module.variables.prefix}-private-subnet"
  vpc_id     = aws_vpc.main.id
  cidr_block = "10.0.0.128/25"
}

resource "aws_key_pair" "auth" {
  key_name   = "${module.variables.prefix}-key"
  public_key = file("../../key.pub")
}

module "aws_security_group" {
  source = "./../ssh_security_group"
  prefix = module.variables.prefix
  vpc_id = aws_vpc.main.id
}

resource "aws_instance" "public_instance" {
  ami           = module.variables.ami
  instance_type = module.variables.instance_type

  subnet_id                   = module.public_subnet.subnet_id
  key_name                    = aws_key_pair.auth.key_name
  associate_public_ip_address = true
  vpc_security_group_ids      = [module.aws_security_group.sg_id]

  tags = {
    Name = "${module.variables.prefix}-public-instance"
  }
}

resource "aws_eip" "nat" {
}

resource "aws_nat_gateway" "gw" {
  allocation_id = aws_eip.nat.id
  subnet_id     = module.public_subnet.subnet_id

  tags = {
    Name = "${module.variables.prefix}-nat-gw"
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
  ami           = module.variables.ami
  instance_type = module.variables.instance_type

  subnet_id              = module.private_subnet.subnet_id
  key_name               = aws_key_pair.auth.key_name
  vpc_security_group_ids = [module.aws_security_group.sg_id]

  tags = {
    Name = "${module.variables.prefix}-private-instance"
  }
}