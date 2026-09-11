# Stage 3: FastAPI + Docker + ECR + Ansible

Before copying this package, delete `.github/workflows/terraform-dev.yml`.
Stage 3 replaces it with `.github/workflows/cicd.yml`.

Copy the package over the existing repository; do not delete the existing Terraform
files not present in this package. Existing VPC/security/backend/provider/variables
files from Stage 2 remain in use.

Pipeline:
PR -> Ruff -> pytest -> Docker build
main -> CI -> OIDC -> Terraform -> ECR push -> dynamic inventory -> Ansible -> ALB health check

Endpoints:
- /
- /health
- /metrics
