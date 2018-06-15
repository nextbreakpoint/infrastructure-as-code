# Infrastructure as code

This repository contains scripts for creating a production-grade infrastructure for running micro-services on the Cloud. The scripts implement a fast, reliable, automated process for creating a scalable and secure infrastructure on [AWS](https://aws.amazon.com).

The infrastructure includes the following components:

- [Logstash](https://www.elastic.co/products/logstash), [Elasticsearch](https://www.elastic.co/products/elasticsearch) and [Kibana](https://www.elastic.co/products/kibana) for collecting and analysing logs

- [Jenkins](https://jenkins-ci.org), [SonarQube](https://www.sonarqube.org) and [Artifactory](https://jfrog.com/artifactory/) for creating a delivery pipeline

- [ECS](https://aws.amazon.com/ecs/) for orchestrating Docker containers

- [Consul](https://www.consul.io) for discovering services and basic monitoring

- [OpenVPN](https://openvpn.net) for securing connection to private machines

The infrastructure includes several EC2 machines which are created within a private network and they are accessible via SSH, using a Bastion machine, or via VPN connection, using a OpenVPN.

The infrastructure is managed by using [Docker](https://www.docker.com), [Terraform](https://www.terraform.io) and [Packer](https://www.packer.io).

## Prepare workstation

Follow the [instructions](https://docs.docker.com/engine/installation) on Docker.com to install Docker CE version 17.09 or later. Docker is the only tool that you need to install on your workstation.

## Configure AWS credentials

Create a new [AWS account](https://aws.amazon.com) or use an existing one if you have the right permissions. Your account must have full administration permissions in order to create the infrastructure.

Create a new Access Key and save your credentials on your workstation. AWS credentials are typically stored at location ~/.aws/credentials.

The content of ~/.aws/credentials should look like:

    [default]
    aws_access_key_id = "your_access_key_id"
    aws_secret_access_key = "your_secret_access_key"

## Configure SSL certificates

Create and upload two SSL certificates using Certificate Manager in AWS console.

First certificate must be issued for domain:

    yourdomain.com

Second certificate must be issued for domain:

    internal.yourdomain.com

The certificates will be used to provision two ALBs, one internet facing and the other internal.

    You can use a self-signed certificates if you wish, but your browser will warn you when you try to access the domains above

## Build Docker image

Execute script run_build.sh to create the Docker image that you will use to build the infrastructure:

    ./run_build.sh

The image contain all the tools you need to manage the infrastructure, including AWS CLI, Terraform, Packer, and others.

## Configure S3 bucket

A S3 bucket is required for storing secrets and certificates used to provision the machines. The bucket is also used as backend for storing Terraform's remote state. Since the bucket contains secrets, access must be restricted. Consider enabling KMS encryption to increase security.

Create a S3 bucket with the command:

    ./run_script.sh create_bucket your_bucket_name eu-west-1

Please note that the bucket name must be globally unique.

Once the bucket has been created, execute the command:

    ./run_script.sh configure_terraform your_bucket_name eu-west-1

The script will set the bucket name and region in all remote_state.tf files.

## Configure Terraform and Packer

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

Create a file config_vars.json in config directory. The file should look like:

    {
      "account_id": "your_account_id",
      "bastion_host": "bastion.yourdomain.com"
    }

The domain yourdomain.com must be a valid domain hosted in a Route53 public zone.

    Register a new domain with AWS if you don't have one already and create a new public zone

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

EC2 machines are provisioned using custom AMI.

Create the images with the command:

    ./run_script.sh build_images

This command might take quite a while. Once the images have been created, you don't need to recreate them unless something has changed in the provisioning scripts. Reusing the same images considerably reduces the time required to create the infrastructure.
If you destroyed the infrastructure but you didn't delete the AMIs, then you can skip this step when you recreate the infrastructure.

## Create infrastructure

Create the infrastructure with command:

    ./run_script.sh create_all

Or create the infrastructure in several steps:

    ./run_script.sh create_secrets
    ./run_script.sh create_network
    ./run_script.sh create_lb
    ./run_script.sh create_stack
    ./run_script.sh create_elk
    ./run_script.sh create_pipeline

## Create OpenVPN server

Create OpenVPN server with command:

    ./run_script.sh create_openvpn

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

Install the configuration in your OpenVPN client. Connect your client.
OpenVPN server is configured to allow connections to any internal servers.

Login into OpenVPN server if you need to modify the server configuration:

    ssh -i deployer_key.pem ubuntu@openvpn.yourdomain.com

Edit file /etc/openvpn/server.conf and then restart the server:

    sudo service openvpn restart

Finally, you should create a new configuration for each client using the command:

    ./run_script new_client_ovpn name

The new client configuration is generated at location:

    secrets/openvpn/openvpn_name.ovpn

## Destroy infrastructure

Destroy the infrastructure with command:

    ./run_script.sh destroy_all

Or destroy the infrastructure in several steps:

    ./run_script.sh destroy_pipeline
    ./run_script.sh destroy_elk
    ./run_script.sh destroy_stack
    ./run_script.sh destroy_lb
    ./run_script.sh destroy_network
    ./run_script.sh destroy_secrets

## Services discovery

Use Consul UI to check the state of your services:

    https://consul.yourdomain.com

You might want to use Consul for services discovery in your applications as well.

## Centralised logging

Use Kibana to analyse log files and monitor servers:

    https://kibana.yourdomain.com

    NOTE: Default user is "elastic" with password "changeme"

If your applications are running in a Docker container managed by ECS, then log files are automatically collected and sent to Logstash. Alternatively you can ship your logs directly to Logstash using your logging framework or you can install Filebeat in your machine.

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

Deploy your applications to ECS or EC2, manually or using Jenkins CI.

## Disable access via Bastion

Bastion server can be stopped or destroyed if required. The server can be recreated when needed.

Stop the Bastion server from AWS console or destroy it with command:

    ./run_script.sh destroy_bastion

## Disable access via OpenVPN

OpenVPN server can be stopped or destroyed if required. The server can be recreated when needed.

Stop the OpenVPN server from AWS console or destroy it with command:

    ./run_script.sh destroy_openvpn
