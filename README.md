# Infrastructure as code

THIS PROJECT IS WORK IN PROGRESS

This repository contains scripts for creating a production grade
cloud based infrastructure which can be used to run micro services.

The scripts are based on Terraform and Packer and they target AWS.

The infrastructure provides key components such like:

- Logstash, Elasticsearch and Kibana for collecting and analysing logs

- ZooKeeper, Cassandra and Kafka for creating reactive services with CQRS and event sourcing

- Jenkins, SonarQube and Artifactory for creating a continuous delivery pipeline

- Consul for monitoring

- Kubernetes for orchestrating Docker containers

## How to create the infrastructure

The provided scripts aim to simplify a process which involves many steps.

  A basic understanding of AWS, Terraform and Packer is required

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

  Please be aware of costs of running EC2 instances on AWS

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

  Please be aware of costs of creating volumes in AWS

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

  Please be aware of costs of running EC2 instances on AWS

Create stack using the script:

  sh create_stack.sh

Destroy stack using the script:

  sh destroy_stack.sh

## How to use the infrastructure

TBD
