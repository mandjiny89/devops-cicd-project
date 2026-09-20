# AWS DevOps CI/CD Project

An end-to-end AWS DevOps project that provisions infrastructure, builds and deploys a containerised FastAPI application, configures EC2 instances, validates the deployment, and provides AWS-native monitoring and alerting.

## Technologies Used

- AWS
- Terraform
- GitHub Actions
- Docker
- Amazon ECR
- EC2
- Auto Scaling Group
- Application Load Balancer
- Ansible
- CloudWatch
- SNS
- Python FastAPI

---

# Architecture

```text
Developer
    │
    │ Git Push
    ▼
GitHub Repository
    │
    │ Manual GitHub Actions Workflow
    ▼
GitHub Actions
    │
    ├── Python linting
    ├── Unit tests
    ├── Docker build validation
    │
    ├── AWS Authentication (OIDC)
    │
    └── Terraform
            │
            ├── VPC
            ├── Public / Private Subnets
            ├── Security Groups
            ├── Application Load Balancer
            ├── Target Group
            ├── Auto Scaling Group
            ├── EC2
            ├── ECR
            ├── CloudWatch
            └── SNS

Application Deployment
    │
    ├── Docker Image Build
    │
    ▼
Amazon ECR
    │
    ▼
EC2 Auto Scaling Group
    │
    │ Ansible
    ▼
FastAPI Docker Container
    │
    ▼
Application Load Balancer
    │
    ▼
/health


Monitoring
    │
    ├── CloudWatch Dashboard
    │
    └── CloudWatch Alarms
             │
             ▼
            SNS
             │
             ▼
           Email
```

---

# Repository Structure

```text
.
├── .github/
│   └── workflows/
│       └── cicd.yml
│
├── app/
│   ├── Dockerfile
│   ├── main.py
│   ├── requirements.txt
│   ├── requirements-dev.txt
│   └── tests/
│
├── ansible/
│   ├── ansible.cfg
│   ├── inventory/
│   │   └── aws_ec2.yml
│   ├── playbooks/
│   │   └── deploy.yml
│   └── roles/
│       └── app/
│
├── terraform/
│   ├── environments/
│   │   └── dev/
│   │       ├── backend.tf
│   │       ├── main.tf
│   │       ├── outputs.tf
│   │       ├── providers.tf
│   │       ├── variables.tf
│   │       └── versions.tf
│   │
│   └── modules/
│       ├── alb/
│       ├── asg/
│       ├── ecr/
│       ├── monitoring/
│       ├── security/
│       └── vpc/
│
└── README.md
```

---

# What This Repository Does

This repository manages the deployment of a containerised FastAPI application into AWS.

The project covers:

- Infrastructure as Code with Terraform
- CI/CD with GitHub Actions
- GitHub-to-AWS authentication using OIDC
- Docker image creation
- Amazon ECR image storage
- EC2 Auto Scaling
- Application Load Balancing
- Ansible configuration management
- Automated application health validation
- CloudWatch monitoring
- CloudWatch alarms
- SNS email notifications

The AWS environment currently runs in:

```text
eu-west-2
```

---

# Infrastructure

Terraform provisions the AWS infrastructure using reusable modules.

The environment includes:

```text
VPC
├── Public Subnet 1
├── Public Subnet 2
├── Private Subnet 1
├── Private Subnet 2
│
├── Security Groups
│
├── Application Load Balancer
│       │
│       └── Target Group
│
├── Auto Scaling Group
│       │
│       └── EC2 Instance(s)
│
├── Amazon ECR
│
├── CloudWatch
│       ├── Dashboard
│       └── Alarms
│
└── SNS
        └── Email Notification
```

Terraform state is stored remotely in Amazon S3. The backend bucket can be created and secured by selecting `bootstrap-backend` in the CI/CD workflow.

---

# Application

The application is built using Python FastAPI and packaged as a Docker container.

The application provides a health endpoint:

```text
/health
```

Example response:

```json
{
  "status": "healthy"
}
```

This endpoint is used to verify that the application has been deployed successfully.

---

# CI/CD Pipeline

The CI/CD pipeline is implemented using GitHub Actions.

The workflow is intentionally manually triggered.

Navigate to:

```text
GitHub
→ Actions
→ CI/CD
→ Run workflow
```

The workflow supports four actions:

```text
bootstrap-backend
plan
deploy
destroy
```

## First-Time AWS / GitHub Setup

The normal pipeline does not use long-lived AWS access keys. GitHub Actions authenticates to AWS using OpenID Connect (OIDC).

The one-time AWS resources required before the workflow can run are:

```text
GitHub OIDC provider:
arn:aws:iam::861019856428:oidc-provider/token.actions.githubusercontent.com

IAM role:
arn:aws:iam::861019856428:role/devops-cicd-github-actions-role

AWS region:
eu-west-2
```

For this repository, GitHub's immutable OIDC subject is:

### Find the GitHub Repository ID

GitHub's OIDC subject for newer repositories can include the immutable
GitHub owner ID and repository ID.

Retrieve the repository information using:

```bash
curl -s https://api.github.com/repos/mandjiny89/devops-cicd-project | grep '"id"'

```text
repo:mandjiny89@35368639/devops-cicd-project@1364155953:ref:refs/heads/main
```


The IAM role trust relationship is:

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Federated": "arn:aws:iam::861019856428:oidc-provider/token.actions.githubusercontent.com"
      },
      "Action": "sts:AssumeRoleWithWebIdentity",
      "Condition": {
        "StringEquals": {
          "token.actions.githubusercontent.com:aud": "sts.amazonaws.com",
          "token.actions.githubusercontent.com:sub": "repo:mandjiny89@35368639/devops-cicd-project@1364155953:ref:refs/heads/main"
        }
      }
    }
  ]
}
```

This OIDC provider and IAM role are bootstrap prerequisites because GitHub must already be able to authenticate to AWS before it can create AWS resources.

### Required GitHub Secrets

The current deployment also expects:

```text
DEVOPS_CICD_DEV_PUBLIC_KEY
DEVOPSCICDDEVPRIVATEKEY
DEVOPS_ALERT_EMAIL
```

AWS access-key and secret-access-key secrets are not required.

## Bootstrap Terraform Backend

The S3 backend is now automated through the same `CI/CD` workflow.

For a new setup, navigate to:

```text
GitHub
→ Actions
→ CI/CD
→ Run workflow
→ action: bootstrap-backend
```

The bootstrap action calculates the deterministic bucket name:

```text
devops-cicd-project-tfstate-dev-861019856428-eu-west-2
```

It then creates the bucket if it does not already exist and enforces:

```text
S3 versioning
AES-256 server-side encryption
Block Public Access
Bucket owner enforced
```

The operation is idempotent, so it is safe to run again. The backend bucket is deliberately kept outside the normal Terraform-managed infrastructure so a `destroy` operation does not destroy the state storage itself.

Terraform uses native S3 state locking through:

```hcl
use_lockfile = true
```

No DynamoDB lock table is required.

The normal first-time deployment order is:

```text
1. Configure the GitHub OIDC provider / IAM role in AWS
2. Add the required GitHub secrets
3. Run CI/CD → bootstrap-backend
4. Run CI/CD → plan
5. Run CI/CD → deploy
```

---

## Plan

The `plan` action validates the application and infrastructure without making changes to AWS.

```text
Checkout repository
        ↓
Install Python dependencies
        ↓
Run Ruff linting
        ↓
Run Python tests
        ↓
Validate Docker build
        ↓
Authenticate to AWS using OIDC
        ↓
Terraform Init
        ↓
Terraform Format Check
        ↓
Terraform Validate
        ↓
Terraform Plan
```

The Terraform plan can then be reviewed before deployment.

---

## Deploy

The `deploy` action performs the complete deployment.

```text
CI Validation
      ↓
AWS OIDC Authentication
      ↓
Terraform Init
      ↓
Terraform Validate
      ↓
Terraform Plan
      ↓
Terraform Apply
      ↓
Build Docker Image
      ↓
Push Image to Amazon ECR
      ↓
Wait for Auto Scaling instances
      ↓
Discover EC2 instances
      ↓
Ansible Deployment
      ↓
Start Docker Container
      ↓
Application Health Check
      ↓
ALB Health Check
```

The deployment succeeds only after the application health endpoint responds successfully.

---

## Destroy

The `destroy` action removes the Terraform-managed development infrastructure.

To protect against accidental destruction, the workflow requires:

```text
Action: destroy
Confirmation: DESTROY
```

Terraform creates a destroy plan before applying it.

The development ECR repository uses:

```hcl
force_delete = true
```

allowing Terraform to remove the repository even when development images exist.

---

# GitHub OIDC Authentication

GitHub Actions authenticates to AWS using OpenID Connect (OIDC).

The workflow assumes the AWS IAM role:

```text
devops-cicd-github-actions-role
```

This avoids storing permanent AWS access keys in GitHub.

```text
GitHub Actions
      │
      │ OIDC Token
      ▼
AWS IAM
      │
      │ Assume Role
      ▼
devops-cicd-github-actions-role
      │
      ▼
AWS Resources
```

---

# Docker and Amazon ECR

The pipeline builds the FastAPI application into a Docker image.

```text
Application Code
      ↓
Docker Build
      ↓
Docker Image
      ↓
Amazon ECR
      ↓
EC2
```

The EC2 instance uses its IAM role to authenticate to ECR and pull the application image.

No AWS access keys are stored on the EC2 instance.

---

# Auto Scaling Group

The application instances are managed by an AWS Auto Scaling Group.

Terraform manages:

- Launch Template
- Minimum capacity
- Desired capacity
- Maximum capacity
- Target Group attachment
- Instance replacement

The instances are treated as disposable infrastructure rather than permanent servers.

---

# Application Load Balancer

An Application Load Balancer provides access to the application.

```text
Client
   ↓
Application Load Balancer
   ↓
Target Group
   ↓
EC2
   ↓
Docker
   ↓
FastAPI
```

The ALB performs health checks against the application.

---

# Ansible Deployment

Ansible handles configuration and application deployment after the infrastructure has been provisioned.

AWS dynamic inventory is used to discover the EC2 instances.

The deployment performs:

```text
Discover EC2
     ↓
Connect to instance
     ↓
Configure Docker
     ↓
Authenticate to ECR
     ↓
Pull application image
     ↓
Remove previous container
     ↓
Start new container
     ↓
Check /health
```

The deployment fails if the application health check fails.

---

# CloudWatch Monitoring

AWS CloudWatch provides monitoring for the deployed environment.

Terraform creates the dashboard:

```text
devops-cicd-project-dev-dashboard
```

It can be viewed from:

```text
AWS Console
→ CloudWatch
→ Dashboards
→ devops-cicd-project-dev-dashboard
```

The dashboard is available inside the AWS account and is not a public website.

## Dashboard Metrics

The dashboard currently displays:

- ALB Request Count
- ALB Target Response Time
- ALB 5xx Errors
- Healthy Targets
- Unhealthy Targets
- Auto Scaling Group CPU Utilisation
- HTTP 2xx responses
- HTTP 4xx responses
- HTTP 5xx responses

This provides a single location for checking the health and behaviour of the environment.

---

# CloudWatch Alarms

Terraform creates three CloudWatch alarms.

## ALB 5xx Alarm

Monitors:

```text
HTTPCode_ELB_5XX_Count
```

The alarm triggers when the configured 5xx threshold is reached.

## Unhealthy Target Alarm

Monitors:

```text
UnHealthyHostCount
```

The alarm triggers when one or more ALB targets become unhealthy for the configured evaluation period.

## High CPU Alarm

Monitors:

```text
CPUUtilization
```

for instances belonging to the Auto Scaling Group.

The configured threshold is:

```text
80%
```

---

# SNS Notifications

CloudWatch alarms publish notifications to:

```text
devops-cicd-project-dev-alerts
```

The SNS topic sends notifications to the configured email address.

```text
CloudWatch Alarm
       ↓
      SNS
       ↓
     Email
```

---

# Manual Setup Required

The following steps must be completed manually before the pipeline can operate.

## 1. Terraform Backend

The S3 bucket used for Terraform remote state must be created before running Terraform.

The backend configuration is defined in:

```text
terraform/environments/dev/backend.tf
```

The Terraform backend is bootstrap infrastructure and is not created by the Terraform configuration that depends on it.

---

## 2. AWS GitHub OIDC Configuration

AWS must have a GitHub OIDC provider configured.

The IAM role used by this project is:

```text
devops-cicd-github-actions-role
```

The role's trust policy must allow the required GitHub repository to assume the role.

The IAM role must also have the AWS permissions required by the Terraform and deployment operations.

---

## 3. SSH Key Pair

An SSH key pair is required for the current Ansible deployment process.

The public key is provided to Terraform and installed on the EC2 instances.

The corresponding private key is provided securely to GitHub Actions for Ansible.

The private key must never be committed to Git.

---

## 4. GitHub Repository Secrets

The following GitHub Actions secrets must be configured manually:

```text
DEVOPS_CICD_DEV_PUBLIC_KEY
DEVOPSCICDDEVPRIVATEKEY
DEVOPS_ALERT_EMAIL
```

### DEVOPS_CICD_DEV_PUBLIC_KEY

SSH public key supplied to Terraform.

### DEVOPSCICDDEVPRIVATEKEY

SSH private key used by Ansible during deployment.

### DEVOPS_ALERT_EMAIL

Email address used by the SNS monitoring subscription.

The workflow passes the required Terraform variables using:

```text
TF_VAR_ssh_public_key
TF_VAR_alert_email
```

---

## 5. SNS Subscription Confirmation

After the SNS email subscription is created, AWS sends a confirmation email.

The recipient must manually select:

```text
Confirm subscription
```

The subscription will not receive CloudWatch alarm notifications until it has been confirmed.

Check the spam/junk folder if the AWS confirmation email does not appear in the inbox.

---

# GitHub Runner SSH Access

GitHub-hosted runners use changing public IP addresses.

During the deployment, the workflow detects the current GitHub runner's public IP address and passes it to Terraform.

Terraform temporarily allows SSH from:

```text
GitHub Runner Public IP/32
```

to the application EC2 security group.

Because GitHub runner addresses change between workflow executions, Terraform plans may show changes similar to:

```text
app_ssh_from_github
```

This is expected behaviour.

---

# Deployment Verification

The pipeline verifies the application after deployment.

Ansible first checks the application health endpoint directly on the EC2 instance.

The GitHub Actions pipeline subsequently checks the application through the Application Load Balancer.

A successful deployment returns:

```json
{
  "status": "healthy"
}
```

This validates the complete path:

```text
GitHub Actions
      ↓
Terraform
      ↓
AWS Infrastructure
      ↓
ECR
      ↓
Ansible
      ↓
EC2
      ↓
Docker
      ↓
FastAPI
      ↓
ALB
      ↓
Health Check
```

---

# Completed Scope

The repository currently demonstrates:

- FastAPI application
- Python testing and linting
- Docker containerisation
- GitHub Actions CI/CD
- Manual Plan / Deploy / Destroy workflows
- GitHub OIDC authentication to AWS
- Terraform remote state
- Modular Terraform infrastructure
- AWS VPC and networking
- Security Groups
- Application Load Balancer
- EC2 Launch Template
- Auto Scaling Group
- Amazon ECR
- Ansible dynamic inventory
- Automated application deployment
- Application health validation
- CloudWatch monitoring dashboard
- CloudWatch alarms
- SNS email notifications

This repository is intentionally focused on the AWS CI/CD platform and AWS-native monitoring.

Prometheus, Grafana and other observability technologies are outside the scope of this repository and can be implemented as a separate project.
