data "aws_ssm_parameter" "al2023_ami" {
  name = "/aws/service/ami-amazon-linux-latest/al2023-ami-kernel-default-x86_64"
}

locals {
  ssh_key_hash = substr(sha256(var.ssh_public_key), 0, 12)
}

resource "aws_key_pair" "deploy" {
  key_name   = "${var.project_name}-${var.environment}-${local.ssh_key_hash}"
  public_key = var.ssh_public_key
}

resource "aws_iam_role" "ec2" {
  name = "${var.project_name}-${var.environment}-ec2-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Service = "ec2.amazonaws.com"
      }
      Action = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy_attachment" "ssm" {
  role       = aws_iam_role.ec2.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_role_policy_attachment" "ecr_read_only" {
  role       = aws_iam_role.ec2.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
}

resource "aws_iam_instance_profile" "ec2" {
  name = "${var.project_name}-${var.environment}-ec2-profile"
  role = aws_iam_role.ec2.name
}

resource "aws_launch_template" "app" {
  name_prefix   = "${var.project_name}-${var.environment}-"
  image_id      = data.aws_ssm_parameter.al2023_ami.value
  instance_type = var.instance_type
  key_name      = aws_key_pair.deploy.key_name

  vpc_security_group_ids = [var.app_security_group_id]

  iam_instance_profile {
    name = aws_iam_instance_profile.ec2.name
  }

  user_data = base64encode(<<-EOF
    #!/bin/bash
    set -euxo pipefail

    # Every ASG instance must be able to bootstrap itself. Ansible still
    # performs normal CI/CD deployments, but replacement/scaled instances
    # can recover the last verified dev release without a GitHub workflow.
    dnf update -y
    dnf install -y python3 docker
    systemctl enable --now docker

    ECR_REPOSITORY="${var.ecr_repository_url}"
    ECR_REGISTRY="$${ECR_REPOSITORY%/*}"
    APP_IMAGE="$${ECR_REPOSITORY}:dev"

    # The dev tag is promoted only after the CI/CD deployment passes the ALB
    # health check. On a brand-new environment it may not exist immediately,
    # so retry while the first deployment completes.
    for attempt in $(seq 1 60); do
      aws ecr get-login-password --region "${var.aws_region}" | \
        docker login --username AWS --password-stdin "$${ECR_REGISTRY}"

      if docker pull "$${APP_IMAGE}"; then
        docker rm -f devops-app || true
        docker run -d \
          --name devops-app \
          --restart unless-stopped \
          -p 80:8000 \
          -e APP_ENV="${var.environment}" \
          "$${APP_IMAGE}"
        exit 0
      fi

      echo "Current dev image is not available yet; retrying in 15 seconds."
      sleep 15
    done

    echo "Unable to pull $${APP_IMAGE} after 15 minutes."
    exit 1
  EOF
  )

  tag_specifications {
    resource_type = "instance"

    tags = {
      Name        = "${var.project_name}-${var.environment}-app"
      Project     = var.project_name
      Environment = var.environment
      Role        = "app"
      ManagedBy   = "Terraform"
    }
  }

  update_default_version = true
}

resource "aws_autoscaling_group" "app" {
  name                = "${var.project_name}-${var.environment}-asg"
  min_size            = var.min_size
  desired_capacity    = var.desired_capacity
  max_size            = var.max_size
  vpc_zone_identifier = var.public_subnet_ids
  target_group_arns   = [var.target_group_arn]

  health_check_type         = "ELB"
  health_check_grace_period = 600

  launch_template {
    id      = aws_launch_template.app.id
    version = "$Latest"
  }

  instance_refresh {
    strategy = "Rolling"

    preferences {
      min_healthy_percentage = 50
      instance_warmup        = 120
    }
  }
}
