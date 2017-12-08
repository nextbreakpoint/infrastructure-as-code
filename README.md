# Infrastructure as code

THIS PROJECT IS WORK IN PROGRESS

This repository contains scripts for creating a production-ready cloud-based infrastructure for running micro services.

The scripts use several tools including Docker, Terraform and Packer, and they target AWS.

The generated infrastructure provides the following key components:

- Logstash, Elasticsearch and Kibana for collecting and visualising logs

- Jenkins, SonarQube and Artifactory for creating a delivery pipeline

- ECS for orchestrating Docker containers

- Consul for services discovery

The scripts provided in this repository aim to automate a very complex process which involves several components and requires many steps.
The ultimate goal is to be able to rapidly and reliably create a scalable and secure infrastructure for running micro services.

### Install tools and prepare environment

Before you start, you need to prepare your environment.

Prepare your environment installing Docker, Terraform and Packer.

Install the command line tool jq required to manipulate json.

Install the AWS command line tools. Follow instruction here https://aws.amazon.com/cli.

You must have a valid AWS account. You can create a new account here https://aws.amazon.com.

    Configure your credentials according to AWS CLI documentation

Check you have valid AWS credentials in file ~/.aws/credentials:

    [default]
    aws_access_key_id = ???
    aws_secret_access_key = ???

Export your active profile when you create a new terminal:

    export AWS_PROFILE=default

Create a file config.tfvars like this:

    # AWS Account
    account_id="your_account_id"

    # SSH key
    key_name="deployer_key"
    key_path="../../deployer_key.pem"

    # Public Hosted Zone
    public_hosted_zone_name="yourdomain.com"
    public_hosted_zone_id="your_public_zone_id"

    # Secrets bucket
    secrets_bucket_name="secrets_bucket_name"

    # Usernames and passwords
    mysql_root_password="your_password"
    mysql_sonarqube_password="your_password"
    mysql_artifactory_password="your_password"

    kibana_password="your_password"
    logstash_password="your_password"
    elasticsearch_password="your_password"

Create a file config_vars.json like this:

    {
      "account_id": "your_account_id",
      "key_name": "deployer_key",
      "key_path": "../../deployer_key.pem",
      "bastion_host": "bastion.yourdomain.com"
    }

The domain yourdomain.com must be a domain hosted in a Route53 public zone.

    Create a new public zone and register a new domain if you don't have one already

### Configure Terraform backend

Terraform requires a S3 Bucket to store the remote state.

Create a S3 bucket with the command:

    sh create_bucket.sh your_bucket_name eu-west-1

Please note that the bucket name must be unique among all S3 buckets.

Once the bucket has been created, execute the command:

    sh config_bucket.sh your_bucket_name eu-west-1

The script will set the bucket name and region in all remote_state.tf files.

### Generate SSH key

A keypair is required in order to access EC2 instances.

For simplicity we will use the same keypair for our tasks.

Create a new keypair using the script:

    sh create_keys.sh

The keypair can be destroyed when it is not used anymore.

Destroy the keypair using the script:

    sh destroy_keys.sh

### Generate certificates

Several certificates are required in order to secure HTTP connections between servers.

Create the certificates using the script:

    sh generate_certificates.sh

### Create VPCs and subnets

VPCs and subnets are required to run EC2 instances, including the instances used to build AMI images with Packer.
Also a Bastion server is required in order to access machines which don't have a public IP address.

The simplest network configuration which is suitable for production requires one VPC with three public subnets and three private subnets, in different availability zones.
Also the public subnets must have an internet gateway, and the private subnets must have a NAT box each to prevent uncontrolled access.
An additional VPC with one public subnet is required for the Bastion server.

    PLEASE BE AWARE OF COSTS OF RUNNING EC2 INSTANCES ON AWS

Create VPCs and subnets using the script:

    sh create_network.sh

VPCs and subnets can be destroyed when they are not used anymore.

Destroy VPCs and subnets using the script:

    sh destroy_network.sh

### Build AMI images

AMI images are useful to simplify the provisioning of EC2 instances.
Also they accelerate the operations because the same image can be used to provision multiple machines.

Create AMI images using the script:

    sh build_images.sh

Images can be removed when they are not required anymore.

Remove all your images using the script:

  sh delete_images.sh

### Create stack

After creating AMI images and configuring VPCs and subnets with routing tables and security groups, we can create
the remaining components of our infrastructure. Those components can be created and destroyed as many time as we want.

    PLEASE BE AWARE OF COSTS OF RUNNING EC2 INSTANCES ON AWS

Create stack using the script:

    sh create_stack.sh

Destroy stack using the script:

    sh destroy_stack.sh

## How to use the infrastructure

Congratulation, you managed to create the entire infrastructure!

Use Consul UI to check the state of your servers and services:

    consul.yourdomain.com

Use Kibana to analyse the log files of yours servers:

    kibana.yourdomain.com

Create your build pipelines using Jenkins:

    jenkins.yourdomain.com

Integrate your build pipeline with SonarQube to analyse your code:

    sonarqube.yourdomain.com

Integrate your build pipeline with Artifactory to manage your artifacts:

    artifactory.yourdomain.com

Deploy your application in ECS or EC2. You can manually deploy your application or create scripts to run from Jenkins.
Your application might use Consul for service discovery. If your application is running in a Docker container managed
by ECS, the logs will be automatically collected and sent to Logstash. Alternatively you can ship your logs directly
to Logstash or use Filebeat to collect your logs.
