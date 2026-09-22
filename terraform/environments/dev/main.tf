data "aws_availability_zones" "available" {
  state = "available"
}

module "vpc" {
  source = "../../modules/vpc"

  project_name         = var.project_name
  environment          = var.environment
  vpc_cidr             = var.vpc_cidr
  availability_zones   = slice(data.aws_availability_zones.available.names, 0, 2)
  public_subnet_cidrs  = var.public_subnet_cidrs
  private_subnet_cidrs = var.private_subnet_cidrs
}

module "security" {
  source = "../../modules/security"

  project_name       = var.project_name
  environment        = var.environment
  vpc_id             = module.vpc.vpc_id
  github_runner_cidr = var.github_runner_cidr
}

module "alb" {
  source = "../../modules/alb"

  project_name          = var.project_name
  environment           = var.environment
  vpc_id                = module.vpc.vpc_id
  public_subnet_ids     = module.vpc.public_subnet_ids
  alb_security_group_id = module.security.alb_security_group_id
}

module "asg" {
  source = "../../modules/asg"

  project_name          = var.project_name
  environment           = var.environment
  public_subnet_ids     = module.vpc.public_subnet_ids
  app_security_group_id = module.security.app_security_group_id
  target_group_arn      = module.alb.target_group_arn
  instance_type         = var.instance_type
  min_size              = var.asg_min_size
  desired_capacity      = var.asg_desired_capacity
  max_size              = var.asg_max_size
  ssh_public_key        = var.ssh_public_key
  aws_region            = var.aws_region
  ecr_repository_url    = module.ecr.repository_url
}

module "ecr" {
  source = "../../modules/ecr"

  project_name = var.project_name
  environment  = var.environment
}

module "monitoring" {
  source = "../../modules/monitoring"

  project_name            = var.project_name
  environment             = var.environment
  alert_email             = var.alert_email
  alb_arn_suffix          = module.alb.alb_arn_suffix
  target_group_arn_suffix = module.alb.target_group_arn_suffix
  asg_name                = module.asg.asg_name
}