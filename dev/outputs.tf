output "vpc_id" {
  value = module.vpc-dev.vpc_id
}

output "iam_instance_profile" {
  value = module.iam-dev.instance_profile
}

output "database_address" {
  value = module.ecs-dev.database_address
}
