# Terraform Bootstrap

This folder creates the one-time AWS IAM resources required for GitHub Actions to authenticate to AWS using OpenID Connect (OIDC).

## Resources created

- GitHub OIDC provider in AWS IAM
- IAM role: `devops-cicd-github-actions-role`
- Temporary `AdministratorAccess` attachment for the dev/lab build

The trust policy is restricted to:

- GitHub owner: `mandjiny89`
- Repository: `devops-cicd-project`
- Branch: `main`

## Prerequisites

Confirm the AWS CLI is authenticated to AWS account:

`861019856428`

Run:

```bash
aws sts get-caller-identity
```

## Initialise and validate

```bash
cd terraform/bootstrap

terraform init
terraform fmt -check
terraform validate
terraform plan
```

Review the plan before applying.

## Apply

After the plan has been reviewed:

```bash
terraform apply
```

## Expected output

Terraform should output an IAM role ARN similar to:

```text
arn:aws:iam::861019856428:role/devops-cicd-github-actions-role
```

We will use that ARN in the GitHub Actions workflow.

## Important

`AdministratorAccess` is being used temporarily for this development/portfolio environment to reduce friction while building the project.

Once the complete infrastructure works, replace it with a least-privilege IAM policy.

Do not commit:

- AWS access keys
- AWS secret keys
- GitHub tokens
- SSH private keys
- Terraform local state files
