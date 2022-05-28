include "root" {
  path = find_in_parent_folders()
}

terraform {
  extra_arguments "common_vars" {
    commands = get_terraform_commands_that_need_vars()

    arguments = [
    ]
  }

  extra_arguments "init_args" {
    commands = [
      "init"
    ]

    arguments = [
      "-reconfigure",
    ]
  }
}

generate "external" {
  path = "external.tf"
  if_exists = "overwrite_terragrunt"
  contents = <<EOF
data "terraform_remote_state" "vpc" {
  backend = "s3"
  config = {
    bucket = var.terraform_bucket_name
    region = var.aws_region
    key    = "vpcs/terraform.tfstate"
  }
}

data "terraform_remote_state" "subnets" {
  backend = "s3"
  config = {
    bucket = var.terraform_bucket_name
    region = var.aws_region
    key    = "subnets/terraform.tfstate"
  }
}
EOF
}

iam_role = "arn:aws:iam::${get_aws_account_id()}:role/Terraform-Manage-Servers"
