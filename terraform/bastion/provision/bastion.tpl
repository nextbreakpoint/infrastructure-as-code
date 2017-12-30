#cloud-config
manage_etc_hosts: true
manage_resolv_conf: false
runcmd:
  - sudo yum install -y mysql
  - sudo curl -o terraform.zip https://releases.hashicorp.com/terraform/0.11.1/terraform_0.11.1_linux_amd64.zip
  - sudo unzip terraform.zip
  - sudo mv terraform /usr/bin
  - sudo rm terraform.zip
  - sudo terraform --version
