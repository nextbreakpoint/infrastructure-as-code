# Infrastructure as code

This repository contains scripts for creating a production-ready cloud-based infrastructure for running micro-services. The provided scripts automate a very complex process which involves several components and they target [AWS](https://aws.amazon.com).

The ultimate goal is to rapidly and reliably create a scalable and secure infrastructure for running micro-services. To achieve this goal, the scripts use several tools, such as [Docker](https://www.docker.com), [Terraform](https://www.terraform.io) and [Packer](https://www.packer.io).

The generated infrastructure provides the following components:

- [Logstash](https://www.elastic.co/products/logstash), [Elasticsearch](https://www.elastic.co/products/elasticsearch) and [Kibana](https://www.elastic.co/products/kibana) for collecting and visualising logs

- [Jenkins](https://jenkins-ci.org), [SonarQube](https://www.sonarqube.org) and [Artifactory](https://jfrog.com/artifactory/) for creating a delivery pipeline

- [ECS](https://aws.amazon.com/ecs/) for orchestrating Docker containers

- [Consul](https://www.consul.io) for services discovery

- [OpenVPN](https://openvpn.net) for connecting to private servers

All servers are created within a private network. They can be accessed via the Bastion server (only SSH), or via a VPN client connected to the OpenVPN server (all ports).

## Install required tools

Follow the instructions on page https://docs.docker.com/engine/installation to install Docker CE version 17.09 or later.

## Configure AWS credentials

Create a new [AWS account](https://aws.amazon.com) or use an existing one if you have the required permissions. Your account must have full administration permissions in order to create the infrastructure.

Create a new Access Key and save your credentials locally. AWS credentials are typically stored at location ~/.aws/credentials, but you can use a different location.

The content of ~/.aws/credentials should look like:

    [default]
    aws_access_key_id = "your_access_key_id"
    aws_secret_access_key = "your_secret_access_key"

## Configure scripts

Create a file config.tfvars in config directory. The file should look like:

    # AWS Account
    account_id="your_account_id"

    # Public Hosted Zone
    hosted_zone_name="yourdomain.com"
    hosted_zone_id="your_public_zone_id"

    # Secrets bucket
    secrets_bucket_name="secrets_bucket_name"

    # Usernames and passwords
    mysql_root_password="your_password"
    mysql_sonarqube_password="your_password"
    mysql_artifactory_password="your_password"

    kibana_password="your_password"
    logstash_password="your_password"
    elasticsearch_password="your_password"

    # OpenVPN AMI (with license for 10 connected devices)
    openvpn_ami = "ami-1a8a6b63"

Create a file config_vars.json in config directory. The file should look like:

    {
      "account_id": "your_account_id",
      "bastion_host": "bastion.yourdomain.com"
    }

The domain yourdomain.com must be a valid domain hosted in a Route53 public zone.

    Register a new domain with AWS if you don't have one already and create a new public zone

## Create or upload certificate

Create or upload certificates using Certificate Manager in AWS console.

First certificate must be issued for domain:

    \*.yourdomain.com

Second certificate must be issued for domain:

    \*.internal.yourdomain.com

The certificates will be used to provision two ALBs, one internet facing and the other internal.

    You can use a self-signed certificates if you wish, but your browser will warn you when you try to access the above domains.

## Create Docker image

Execute script run_build.sh to create the Docker image required to build the infrastructure:

    ./run_build.sh

The image will contain the required tools, including AWS CLI, Terraform, Packer, and others.

## Configure Terraform backend

Terraform requires a S3 Bucket to store the remote state.

Create a S3 bucket with the command:

    ./run_script.sh create_bucket your_bucket_name eu-west-1

Please note that the bucket name must be unique among all S3 buckets.

Once the bucket has been created, execute the command:

    ./run_script.sh configure_terraform your_bucket_name eu-west-1

The script will set the bucket name and region in all remote_state.tf files.

## Generate secrets

Some certificates and keystores are required to create a secure infrastructure.

Create the secrets with the command:

    ./run_script.sh generate_secrets

## Generate SSH keys

SSH keys are required to access EC2 machines.

Generate the SSH keys with the command:

    ./run_script.sh generate_keys

## Configure Consul

Create a configuration for Consul with the command:

    ./run_script.sh configure_consul

## Create VPCs

Create VPCs with command:

    ./run_script.sh create_vpc

## Create SSH keys

Create SSH keys with command:

    ./run_script.sh create_keys

## Create Bastion server

Create Bastion server with command:

    ./run_script.sh create_bastion

## Build images with Packer

EC2 machines are provisioned using custom images.

Create the images with the command:

    ./run_script.sh build_images

## Create infrastructure

Create the infrastructure with command:

    ./run_script.sh create_all

Or create the infrastructure in several steps:

    ./run_script.sh create_secrets
    ./run_script.sh create_network
    ./run_script.sh create_lb
    ./run_script.sh create_openvpn
    ./run_script.sh create_stack
    ./run_script.sh create_elk
    ./run_script.sh create_pipeline

## Destroy infrastructure

Destroy the infrastructure with command:

    ./run_script.sh destroy_all

Or destroy the infrastructure in several steps:

    ./run_script.sh destroy_pipeline
    ./run_script.sh destroy_elk
    ./run_script.sh destroy_stack
    ./run_script.sh destroy_openvpn
    ./run_script.sh destroy_lb
    ./run_script.sh destroy_network
    ./run_script.sh destroy_secrets

## Access machines using Bastion

Copy the deployer key to Bastion machine:

    scp -i deployer_key.pem deployer_key.pem ec2-user@bastion.yourdomain.com:~

Connect to bastion server using the command:

    ssh -i deployer_key.pem ec2-user@bastion.yourdomain.com

Connect to other machines using the command:

    ssh -i deployer_key.pem ubuntu@private_ip_address

## Access machines using OpenVPN

A default client configuration is automatically generated at location:

    secrets/openvpn_client.ovpn

Install the configuration in your OpenVPN client to connect your client to the VPN.

OpenVPN server is configured to allow connections to any internal servers.

Login into OpenVPN server if you need to modify the server configuration:

    ssh -i deployer_key.pem ubuntu@openvpn.yourdomain.com

Edit file /etc/openvpn/server.conf and then restart the server:

    sudo service openvpn restart

Finally, you should create a new configuration for each client using the command:

    ./run_script new_client_ovpn name

The new client configuration is generated at location:

    openvpn/openvpn_name.ovpn

## Services discovery

Use Consul UI to check the state of your services:

    https://consul.yourdomain.com

You might want to use Consul for services discovery in your applications as well.

## Centralised logging

Use Kibana to analyse log files and monitor servers:

    https://kibana.yourdomain.com

    NOTE: Default user is "elastic" with password "changeme"

If your applications are running in a Docker container managed by ECS, then log files are automatically collected and sent to Logstash.
Alternatively you can ship your logs directly to Logstash using your logging framework or using Filebeat.

## Delivery pipelines

Create your delivery pipelines using Jenkins:

    https://jenkins.yourdomain.com

    NOTE: Security is disabled by default

Integrate your build pipeline with SonarQube to analyse your code:

    https://sonarqube.yourdomain.com

    NOTE: Default user is "admin" with password "admin"

Integrate your build pipeline with Artifactory to manage your artifacts:

    https://artifactory.yourdomain.com

    NOTE: Default user is "admin" with password "password"

Deploy your application to ECS or EC2, manually or using Jenkins CI.

## Disable access from Bastion

Bastion server could be stopped or destroyed after creating the infrastructure. The server can be recreated when needed.

Stop the Bastion server from AWS console.

Destroy the Bastion server with command:

    ./run_script.sh destroy_bastion
