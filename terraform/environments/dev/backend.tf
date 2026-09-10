terraform {
  backend "s3" {
    bucket       = "devops-cicd-project-tfstate-dev-861019856428-eu-west-2"
    key          = "dev/terraform.tfstate"
    region       = "eu-west-2"
    encrypt      = true
    use_lockfile = true
  }
}
