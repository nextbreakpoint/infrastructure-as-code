# Infrastructure as code

This repository contains scripts for creating a production-grade infrastructure for running micro-services on the Cloud. The scripts implement a quick and reliable process for creating a scalable and secure infrastructure on [AWS](https://aws.amazon.com).

The infrastructure includes the following components:

-   [Logstash](https://www.elastic.co/products/logstash), [Elasticsearch](https://www.elastic.co/products/elasticsearch) and [Kibana](https://www.elastic.co/products/kibana) for collecting and analysing logs

-   [Jenkins](https://jenkins-ci.org), [SonarQube](https://www.sonarqube.org) and [Artifactory](https://jfrog.com/artifactory/) for creating a delivery pipeline

-   [Docker Swarm](https://docker.com) for orchestrating Docker containers

-   [Consul](https://www.consul.io) for discovering machines or services

-   [Graphite](https://graphiteapp.org) and [Grafana](https://grafana.com) for collecting metrics and monitoring services

-   [Cassandra](http://cassandra.apache.org), [Kafka](https://kafka.apache.org), [Zookeeper](https://zookeeper.apache.org) for creating event-based scalable services

-   [OpenVPN](https://openvpn.net) for creating a secure connection to private machines

The infrastructure includes several EC2 machines which are created within a private network and they are accessible via SSH, using a bastion machine, or via VPN connection, using OpenVPN.

The infrastructure is managed by using [Docker](https://www.docker.com), [Terraform](https://www.terraform.io) and [Packer](https://www.packer.io).

## Prepare workstation

Follow the [instructions](https://docs.docker.com/engine/installation) on Docker.com to install Docker CE version 17.09 or later. Docker is the only tool that you need to install on your workstation.

## Configure AWS credentials

Create a new [AWS account](https://aws.amazon.com) or use an existing one if you have the right permissions. Your account must have full administration permissions in order to create the infrastructure (or you can start with minimal permissions and add what is required as you go, but at the moment we don't provide the complete policy).

Create a new Access Key and save your credentials on your workstation. AWS credentials are typically stored at location ~/.aws/credentials.

The content of ~/.aws/credentials should look like:

    [default]
    aws_access_key_id = "your_access_key_id"
    aws_secret_access_key = "your_secret_access_key"

## Configure SSL certificates

Create and upload two SSL certificates using [Certificate Manager](https://eu-west-1.console.aws.amazon.com/acm/home?region=eu-west-1) in AWS console.

First certificate must be issued for domain:

    yourdomain.com

Second certificate must be issued for domain:

    internal.yourdomain.com

The certificates will be used to provision two ALBs, one internet facing and the other internal.

    You can use self-signed certificates as well, just remember that your browser will warn you when accessing resources on those domains

## Build Docker image

Create the Docker image that you will use to build the infrastructure:

    ./docker_build.sh

The image contains the tools you need to manage the infrastructure, including AWS CLI, Terraform, Packer, and others.

## Configure S3 buckets

Two S3 buckets are required for creating the infrastructure. The first bucket is required for storing secrets and certificates. The second bucket is required for storing Terraform's remote state. Since the buckets contains sensible data, the access must be restricted.

    Consider enabling KMS encryption on the bucket to increase security

Create a S3 bucket for secrets with the command:

    ./docker_run.sh make_bucket your_secrets_bucket_name

Create a S3 bucket for Terraform with the command:

    ./docker_run.sh make_bucket your_terraform_bucket_name

Once the Terraform bucket has been created, configure the Terraform's backend with the command:

    ./docker_run.sh configure_terraform your_terraform_bucket_name

The script will set the bucket name and region in all remote_state.tf files.

## Configure Terraform and Packer

Create a file main.json in the config directory. Copy the content from the file template-main.json. The file should look like:

    {
        "account_id": "your_account_id",

        "environment": "prod",
        "colour": "green",

        "hosted_zone_name": "yourdomain.com",
        "hosted_zone_id": "your_public_zone_id",

        "bastion_host": "bastion.yourdomain.com",

        "secrets_bucket_name": "your_secrets_bucket_name",

        "consul_datacenter": "internal",

        "key_password": "your_key_password",
        "keystore_password": "your_keystore_password",
        "truststore_password": "your_truststore_password",
        "kafka_password": "your_password",
        "zookeeper_password": "your_password",
        "mysql_root_password": "your_password",
        "mysql_sonarqube_password": "your_password",
        "mysql_artifactory_password": "your_password",
        "kibana_password": "your_password",
        "logstash_password": "your_password",
        "elasticsearch_password": "your_password"
    }

Change the variables to the correct values for your infrastructure. The account id must be a valid AWS account id and your AWS credentials must have the correct permissions on that account. The domain yourdomain.com must be a valid domain hosted in a Route53 public zone.

    Register a new domain with AWS if you don't have one already and create a new public zone

## Generate secrets

Create the secrets with the command:

    ./docker_run.sh generate_secrets

Several certificates and passwords are required to create a secure infrastructure.

## Generate SSH keys

Generate the SSH keys with the command:

    ./docker_run.sh generate_keys

SSH keys are required to access EC2 machines.

## Configure Consul

Create a configuration for Consul with the command:

    ./docker_run.sh configure_consul

## Create VPCs

Create the VPCs with command:

    ./docker_run.sh create_vpc

## Create SSH keys

Create the SSH keys with command:

    ./docker_run.sh create_keys

## Create Bastion server

Create the Bastion server with command:

    ./docker_run.sh create_bastion

## Build images with Packer

Create the AMI images with command:

    ./docker_run.sh build_images

Some EC2 machines are provisioned using custom AMI.

This command might take quite a while. Once the images have been created, you don't need to recreate them unless something has changed in the provisioning scripts. Reusing the same images, considerably reduces the time required to create the infrastructure.

    If you destroyed the infrastructure, but you didn't delete the AMIs, then you can skip this step when you recreate the infrastructure.

## Create the infrastructure

Create the infrastructure with command:

    ./docker_run.sh create_all

Or create the infrastructure in several steps:

    ./docker_run.sh create_secrets
    ./docker_run.sh create_network
    ./docker_run.sh create_lb
    ./docker_run.sh create_swarm

## Create OpenVPN server

Create the OpenVPN server with command:

    ./docker_run.sh create_openvpn

## Access machines using Bastion

Copy the deployer key to Bastion machine:

    scp -i prod-green-deployer.pem prod-green-deployer.pem ec2-user@prod-green-bastion.yourdomain.com:~

Connect to bastion server using the command:

    ssh -i prod-green-deployer.pem ec2-user@prod-green-bastion.yourdomain.com

Connect to any other machines using the command:

    ssh -i prod-green-deployer.pem ubuntu@private_ip_address

You can find the ip address of the machines on the AWS console.

## Access machines using OpenVPN

A default client configuration is automatically generated at location:

    secrets/openvpn/production/green/openvpn_client.ovpn

Install the configuration in your OpenVPN client and connect your client. OpenVPN server is configured to allow connections to any internal servers.

You should create a different configuration for each client using the command:

    ./run_script new_client_ovpn name

The client configuration is generated at location:

    secrets/openvpn/production/green/openvpn_name.ovpn

If you need to modify the server configuration, login into OpenVPN server:

    ssh -i prod-green-deployer.pem ubuntu@prod-green-openvpn.yourdomain.com

Edit the file /etc/openvpn/server.conf and then restart the server:

    sudo service openvpn restart

## Create the Docker Swarm

Docker Swarm can be created when all the EC2 machines are ready.

Verify that you can ping the manager nodes:

    ping prod-green-swarm-manager-a.yourdomain.com
    ping prod-green-swarm-manager-a.yourdomain.com
    ping prod-green-swarm-manager-a.yourdomain.com

Verify that you can ping the worker nodes:

    ping prod-green-swarm-worker-a.yourdomain.com
    ping prod-green-swarm-worker-a.yourdomain.com
    ping prod-green-swarm-worker-a.yourdomain.com

Verify that you can login into the machines:

    ssh -i prod-green-deployer.pem ubuntu@prod-green-swarm-manager-a.yourdomain.com

Create the Swarm with the command:

    ./swarm_join.sh

Configure the Swarm with the command:

    ./swarm_configure.sh

Verify that the Swarm is working with the command:

    ./swarm_cmd.sh prod-green-swarm-manager.yourdomain.com "docker node ls"

It should print the list of the nodes, which should contain 6 nodes, 3 managers and 3 workers.

## Create networks

Create the overlay networks with the command:

    ./swarm_run.sh prod-green-swarm-manager.yourdomain.com create_network

The overlay networks are used to allow communication between containers running on different machines.

## Create services

The services are deployed on the Swarm using Docker Stacks.

Deploy a stack with the command:

    ./swarm_run.sh prod-green-swarm-manager.yourdomain.com deploy_stack consul

It should create volumes and services on the worker nodes.

Verify that the services are running with the command:

    ./swarm_cmd.sh prod-green-swarm-manager.yourdomain.com "docker service ls"

In a similar way, you can deploy any stack from this list:

    consul
    nginx
    zookeeper
    kafka
    cassandra
    elasticsearch
    logstash
    kibana
    graphite
    grafana
    jenkins
    mysql
    sonarqube
    artifactory

Please note that before deploying SonarQube or Artifactory, you must configure MySQL with the command:

    ./swarm_run.sh prod-green-swarm-manager.yourdomain.com setup_mysql

Some services have ports exposed on the host machine, therefore are reachable from any other machine in the same VPC. Some ports are only accessible from the overlay network, and are used for internal communication between nodes of the cluster.

This is the list of ports which are exposed on the host:

    TODO

## Remove services

Remove a service with the command:

    ./swarm_run.sh prod-green-swarm-manager.yourdomain.com remove_stack consul

The volumes associated with the service are not deleted when deleting a stack.

    The content of the volumes will still be available when recreating the stack

## Remove networks

Remove the overlay networks with the command:

    ./swarm_run.sh prod-green-swarm-manager.yourdomain.com remove_networks

## Destroy infrastructure

Destroy the infrastructure with command:

    ./docker_run.sh destroy_all

Or destroy the infrastructure in several steps:

    ./docker_run.sh destroy_swarm
    ./docker_run.sh destroy_lb
    ./docker_run.sh destroy_network
    ./docker_run.sh destroy_secrets

## Services discovery

Use Consul UI to check the state of your services:

    https://prod-green-swarm-worker.yourdomain.com:8500

You might want to use Consul for services discovery in your applications as well.

You can use Consul as DNS server, and you can lookup for a service using a DNS query:

    dig @prod-green-swarm-manager.yourdomain.com:8600 consul.service.internal

## Centralised logs

Use Kibana to analyse logs and monitor services:

    https://prod-green-swarm-manager.yourdomain.com:5601

    NOTE: Default user is "elastic" with password "changeme"

All containers running on the Swarm are configured to send the logs to Logstash, therefore the logs are available in Kibana.

## Metrics and monitoring

Use Graphite and Grafana to collect metrics and monitor services:

    https://prod-green-swarm-manager.yourdomain.com:3000
    https://prod-green-swarm-manager.yourdomain.com:2080

    NOTE: Default user is "admin" with password "admin"

Configure your applications to send metrics to Graphite and create your dashboards with Grafana.

## Delivery pipelines

Create your delivery pipelines using Jenkins:

    https://prod-green-swarm-manager.yourdomain.com:8080

    NOTE: Security is disabled by default

Integrate your build pipeline with SonarQube to analyse your code:

    https://prod-green-swarm-manager.yourdomain.com:9000

    NOTE: Default user is "admin" with password "admin"

Integrate your build pipeline with Artifactory to manage your artifacts:

    https://prod-green-swarm-manager.yourdomain.com:8081

    NOTE: Default user is "admin" with password "password"

Deploy your applications to Docker Swarm or EC2, manually or using Jenkins CI.

## Disable access via Bastion

Bastion server can be stopped or destroyed if required. The server can be recreated when needed.

Stop the Bastion server from AWS console or destroy it with command:

    ./docker_run.sh destroy_bastion

## Disable access via OpenVPN

OpenVPN server can be stopped or destroyed if required. The server can be recreated when needed.

Stop the OpenVPN server from AWS console or destroy it with command:

    ./docker_run.sh destroy_openvpn
