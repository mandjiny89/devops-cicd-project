output "vpc_id" {
  value = module.vpc.vpc_id
}

output "public_subnet_ids" {
  value = module.vpc.public_subnet_ids
}

output "private_subnet_ids" {
  value = module.vpc.private_subnet_ids
}

output "alb_dns_name" {
  value = module.alb.alb_dns_name
}

output "asg_name" {
  value = module.asg.asg_name
}

output "launch_template_id" {
  value = module.asg.launch_template_id
}
