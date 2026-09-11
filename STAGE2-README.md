# Stage 2

This stage creates the first real AWS infrastructure:

- VPC
- 2 public subnets
- 2 private subnets
- Internet Gateway and route tables
- ALB and target group
- EC2 security groups
- Launch Template
- Auto Scaling Group: min 2 / desired 2 / max 4
- EC2 IAM role with SSM core permissions
- Amazon Linux 2023 instances
- Temporary Nginx bootstrap page
- Ansible AWS EC2 dynamic inventory

## Dev networking decision

The ASG currently launches in the public subnets so GitHub-hosted runners can reach the instances later with Ansible without paying for a NAT Gateway.

The application instances accept HTTP only from the ALB and SSH only from the current GitHub runner IP.

## Stage 2 validation

After pushing to main, verify:

1. Terraform Apply succeeds.
2. The ASG has two InService instances.
3. The ALB target group becomes healthy.
4. The ALB URL shows the bootstrap page.

Ansible is not executed yet. Stage 3 will add the FastAPI application, Docker and Ansible configuration/deployment.
