output "subnet_id" {
  value = aws_subnet.subnet.id
}

output "subnet_cidr_block" {
  value = var.cidr_block
}

output "route_table_arn" {
  value = aws_route_table.rt.arn
}

output "route_table_id" {
  value = aws_route_table.rt.id
}

