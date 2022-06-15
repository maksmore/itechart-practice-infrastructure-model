output "database_address" {
  value = data.aws_db_instance.postgres.address
}

output "aws_region_current" {
  value = data.aws_region.current.name
}
