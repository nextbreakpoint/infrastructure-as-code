# Generated by Terragrunt. Sig: nIlQXj57tbuaRZEa
data "terraform_remote_state" "vpc" {
  backend = "s3"
  config = {
    bucket = var.bucket_name
    region = var.aws_region
    key    = "vpcs/terraform.tfstate"
  }
}