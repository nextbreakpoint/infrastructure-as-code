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

iam_role = "arn:aws:iam::${get_aws_account_id()}:role/Terraform-Manage-Security"
