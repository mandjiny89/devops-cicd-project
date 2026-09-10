# Infrastructure resources will be added in the next stage.
#
# This first GitHub Actions stage intentionally contains no AWS resources.
# Its purpose is to validate:
#   GitHub Actions -> GitHub OIDC -> AWS STS -> IAM role
#   Terraform -> S3 remote backend and state locking
