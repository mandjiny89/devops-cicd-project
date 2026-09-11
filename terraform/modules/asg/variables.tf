variable "project_name" { type = string }
variable "environment" { type = string }
variable "public_subnet_ids" { type = list(string) }
variable "app_security_group_id" { type = string }
variable "target_group_arn" { type = string }
variable "instance_type" { type = string }
variable "min_size" { type = number }
variable "desired_capacity" { type = number }
variable "max_size" { type = number }

variable "ssh_public_key" {
  type      = string
  sensitive = true
}
