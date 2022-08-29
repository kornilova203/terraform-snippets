resource "aws_subnet" "subnet" {
  vpc_id     = var.vpc_id
  cidr_block = var.cidr_block

  tags = {
    Name = var.name
  }
}

resource "aws_route_table" "rt" {
  vpc_id = var.vpc_id

  tags = {
    Name = "${var.name}-route-table"
  }
}

resource "aws_route_table_association" "association" {
  subnet_id      = aws_subnet.subnet.id
  route_table_id = aws_route_table.rt.id
}
