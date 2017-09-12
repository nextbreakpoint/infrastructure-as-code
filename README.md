# Infrastructure as code

THIS PROJECT IS WORK IN PROGRESS

This repository contains scripts for creating a production grade
cloud based infrastructure which can be used to run micro services.

The scripts are based on Terraform and Packer and they target AWS.

The infrastructure provides key components such like:

- Logstash, Elasticsearch and Kibana for collecting and analysing logs

- ZooKeeper, Cassandra and Kafka for creating reactive services with CQRS and event sourcing

- Jenkins, SonarQube and Artifactory for creating a continuous delivery pipeline

- Consul for monitoring servers and

- Kubernetes for orchestrating Docker containers

## How to create the infrastructure

The scripts provided in this repository aim to simplify a process which involves many steps and it requires a basic understanding of AWS platform and tools such like Terraform and Packer.

### Prepare environment

The user must have a valid AWS account. Credentials must be configured according to AWS CLI documentation.

Before you start, check you have valid credentials in file ~/.aws/credentials and remember to export your active profile:

    export AWS_PROFILE=default

Prepare your environment installing Terraform and Packer.

Install the command line tool jq required to manipulate json.

Create a file terraform.tfvars like this:

    # AWS Account
    account_id="???"

    # Region
    aws_region="eu-west-1"

    # SSH key
    key_name="deployer_key"
    key_path="../../deployer_key.pem"

    # Hosted zones
    public_hosted_zone_name="yourdomain.com"
    public_hosted_zone_id="???"
    hosted_zone_name="internal"

    # VPC and subnets
    aws_bastion_vpc_cidr="172.33.0.0/16"
    aws_bastion_subnet_cidr_a="172.33.0.0/24"
    aws_bastion_subnet_cidr_b="172.33.1.0/24"

    aws_network_vpc_cidr="172.32.0.0/16"
    aws_network_public_subnet_cidr_a="172.32.0.0/24"
    aws_network_public_subnet_cidr_b="172.32.2.0/24"
    aws_network_public_subnet_cidr_c="172.32.4.0/24"
    aws_network_private_subnet_cidr_a="172.32.1.0/24"
    aws_network_private_subnet_cidr_b="172.32.3.0/24"
    aws_network_private_subnet_cidr_c="172.32.5.0/24"

    aws_network_dev_public_subnet_cidr_a="172.32.6.0/24"
    aws_network_dev_private_subnet_cidr_a="172.32.7.0/24"

    # Base AMI version
    base_version="1.0"

    # Software versions
    jenkins_version="2.78"
    sonarqube_version="6.5"
    artifactory_version="5.4.6"
    mysqlconnector_version="5.1.44"
    elasticsearch_version="5.5.2"
    filebeat_version="5.5.2"
    logstash_version="5.5.2"
    kibana_version="5.5.2"
    topbeat_version="1.3.1"
    consul_version="0.9.3"
    kafka_version="0.11.0.0"
    scala_version="2.12"
    kubernetes_version="1.7.5"
    cassandra_version="311"

    # Other
    es_cluster="logs"
    es_environment="logs"

Create a file packer_vars.json like this:

    {
      "aws_region": "eu-west-1",
      "key_name": "deployer_key",
      "key_path": "../../deployer_key.pem",
      "bastion_host": "bastion.yourdomain.com",
      "base_version": "1.0",
      "jenkins_version": "2.78",
      "sonarqube_version": "6.5",
      "artifactory_version": "5.4.6",
      "mysqlconnector_version": "5.1.44",
      "elasticsearch_version": "5.5.2",
      "filebeat_version": "5.5.2",
      "logstash_version": "5.5.2",
      "kibana_version": "5.5.2",
      "topbeat_version": "1.3.1",
      "consul_version": "0.9.3",
      "kafka_version": "0.11.0.0",
      "scala_version": "2.12",
      "kubernetes_version": "1.7.5",
      "cassandra_version": "311"
    }

The domain yourdomain.com must be a valid domain hosted in a Route53 public zone.

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
ESB volumes need to be initialized with at least one partition before
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

Use the AWS console to deregister the AMIs.

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

TBD
