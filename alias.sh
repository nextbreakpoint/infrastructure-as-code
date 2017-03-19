alias packer_create='packer build --var-file=../../secrets/packer_vars.json packer.json'
alias tf_apply='terraform apply -var-file=../../secrets/terraform.tfvars -var '\''aws_shared_credentials_file=/Users/andrea/.aws/credentials'\'''
alias tf_destroy='terraform destroy -var-file=../../secrets/terraform.tfvars -var '\''aws_shared_credentials_file=/Users/andrea/.aws/credentials'\'''
