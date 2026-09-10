# Stage 1 - GitHub OIDC and Terraform Backend Validation

This stage runs Terraform only in GitHub Actions.

It deliberately creates no application infrastructure yet.

## What it validates

1. GitHub Actions can request an OIDC token.
2. AWS accepts the token and allows the workflow to assume:
   `arn:aws:iam::861019856428:role/devops-cicd-github-actions-role`
3. Terraform can initialise the S3 backend:
   `devops-cicd-project-tfstate-dev-861019856428-eu-west-2`
4. S3 native state locking works.
5. Terraform formatting and validation pass.
6. Terraform can produce a plan.

## Expected first result

Because this stage contains no AWS infrastructure resources, the plan should report no infrastructure changes.

## No local Terraform required

Do not run `terraform init`, `terraform plan`, or `terraform apply` locally.

Commit these files and push them to `main`. GitHub Actions will run the workflow automatically.
