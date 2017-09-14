# Infrastructure as code

THIS PROJECT IS WORK IN PROGRESS

This repository contains scripts for creating a production-ready
cloud-based infrastructure which can be used to run micro services.

The scripts are based on Terraform and Packer and they target AWS.

The infrastructure provides key components such like:

- Logstash, Elasticsearch and Kibana for collecting and analysing logs

- ZooKeeper, Cassandra and Kafka for creating reactive services with CQRS and event sourcing

- Jenkins, SonarQube and Artifactory for creating a continuous delivery pipeline

- Consul for monitoring servers and services

- Kubernetes and ECS for orchestrating Docker containers

## How to create the infrastructure

The scripts provided in this repository aim to simplify a process which involves
many steps and it requires some understanding of AWS platform and tools such
like Terraform and Packer.

### Install tools and prepare environment

Before you start, you need to prepare your environment.

Prepare your environment installing Terraform and Packer.

Install the command line tool jq required to manipulate json.

Install the AWS command line tools. Follow instruction here https://aws.amazon.com/cli.

You must have a valid AWS account. You can create a new account here https://aws.amazon.com.

Configure your credentials according to AWS CLI documentation.

Check you have valid credentials in file ~/.aws/credentials:

    [default]
    aws_access_key_id = ???
    aws_secret_access_key = ???

Export your active profile:

    export AWS_PROFILE=default

Create a file config.tfvars like this:

    # AWS Account
    account_id="your_account"

    # SSH key
    key_name="deployer_key"
    key_path="../../deployer_key.pem"

    # Public Hosted Zone
    public_hosted_zone_name="yourdomain.com"
    public_hosted_zone_id="your_public_zone_id"

Create a file config_vars.json like this:

    {
      "key_name": "deployer_key",
      "key_path": "../../deployer_key.pem",
      "bastion_host": "bastion.yourdomain.com"
    }

The domain yourdomain.com must be a domain hosted in a Route53 public zone.
Create a new public zone and register a new domain if you don't have one already.

### Create S3 Bucket

Terraform requires a S3 Bucket to store remote state.

Create a bucket with command:

    aws s3api create-bucket --bucket nextbreakpoint-terraform-state --region eu-west-1 --create-bucket-configuration LocationConstraint=eu-west-1

The bucket needs to be created once. You can delete the bucket when you don't need it anymore.

### Generate deployer key

A keypair is required in order to access EC2 instances.

For simplicity we will use the same keypair for all the remaining steps.

Create a new keypair using the script:

    sh create_keys.sh

The deployer key can be destroyed when it is not used anymore.

Destroy the keypair using the script:

    sh destroy_keys.sh

### Create VPCs and subnets

VPCs and subnets are required to run EC2 instances, including the instances
used to build AMIs with Packer. Also a Bastion server is required in order to
access machines which don't have a public IP address for security reason.

A simple network configuration which is suitable for production have
one VPC with three public subnets in three different availability zones
and three private subnets in three different availability zones, and an
additional VPC with at least one public subnet for the Bastion server.
The public subnets must have an internet gateway, and the private subnets
must have a NAT box each to prevent uncontrolled access.

PLEASE BE AWARE OF COSTS OF RUNNING EC2 INSTANCES ON AWS

Create VPCs and subnets using the script:

    sh create_network.sh

VPCs and subnets can be destroyed when they are not used anymore.

Destroy VPCs and subnets using the script:

    sh destroy_network.sh

### Create ESB volumes

ESB volumes are required to store persistent data which can survive after
a restart of a EC2 instance or in case we need to recreate a EC2 instance.
ESB volumes need to be initialised with at least one partition before
they can be used. We use a temporary EC2 instance to mount the volumes
and create an empty partition.

PLEASE BE AWARE OF COSTS OF CREATING VOLUMES IN AWS

Create ESB volumes using the script:

    sh create_volumes.sh

Volumes can be destroyed any time when data are not required anymore

Destroy ESB volumes using the script:

    sh destroy_volumes.sh

### Build AMIs

Images are useful to simplify the provisioning of a EC2 instance and
also they accelerate the operations because the same image can be used
to create multiple EC2 instances.

Create AMIs using the script:

    sh build_images.sh

Images can be removed when they are not required anymore.

Remove all your images using the script:

  sh delete_images.sh

### Create stack

After we have created all base components and we have configured
the required VPCs and subnets with routing tables and security groups,
we can create the remaining components of our infrastructure.
Those components depends on AMIs and volumes we created in previous steps,
and they can be created and destroyed as many time as we want.

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

Integrate your build pipeline with SonarQube and analyse your code:

    sonarqube.yourdomain.com

Integrate your build pipeline with Artifactory and manage your artifacts:

    artifactory.yourdomain.com

Deploy your application in ECS or EC2. You can manually deploy your application or create your own scripts.
Your application might use ZooKeeper, Kafka, Cassandra clusters or it might use any other resource reachable
from a subnet.

ZooKeeper, Kafka and Cassandra are reachable using the private hostname:

    zookeeper.internal
    cassandra.internal
    kafka.internal

Ship your logs to Logstash. Logstash is reachable using the private hostname:

    logstash.internal

Monitor your services using Consul. Consul is reachable using the private hostname:

    consul.internal
