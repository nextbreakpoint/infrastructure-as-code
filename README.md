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

The domain yourdomain.com must be a valid domain hosted in a Route53 public zone and it must support HTTPS.

    Create a new public zone and register a new domain if you don't have one already

The domain yourprivatedomain.com can be the same as yourdomain.com or a different one. A new private zone will be created to register all internal servers.

## Create or upload certificate

Access AWS Console and go to section Certificate Manager.

Create or upload a valid HTTPS certificate issued for domain:

    \*.yourprivatedomain.com

The certificate will be used to provision a private ELB to access internal servers.

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

    ./run_script.sh create_zones
    ./run_script.sh create_network
    ./run_script.sh create_openvpn
    ./run_script.sh create_stack
    ./run_script.sh create_elb

## Destroy infrastructure

Destroy the infrastructure with command:

    ./run_script.sh destroy_all

Or destroy the infrastructure in three steps:

    ./run_script.sh destroy_elb
    ./run_script.sh destroy_stack
    ./run_script.sh destroy_openvpn
    ./run_script.sh destroy_network
    ./run_script.sh destroy_zones

## Access machines using Bastion

Copy the deployer key to Bastion machine:

    scp -i deployer_key.pem deployer_key.pem ubuntu@bastion.yourdomain.com:~

Connect to bastion server using the command:

    ssh -i deployer_key.pem ubuntu@bastion.yourdomain.com

Connect to other machines using the command:

    ssh -i deployer_key.pem ubuntu@private_ip_address

## Access machines using OpenVPN

OpenVPN server must be configured in order to accept connections.

Login to OpenVPN server using the command:

    ssh -i deployer_key.pem openvpnas@openvpn.yourdomain.com

The server will ask you a few questions. The output should look like:

    Welcome to OpenVPN Access Server Appliance 2.1.9

    To run a command as administrator (user "root"), use "sudo <command>".
    See "man sudo_root" for details.

    [...]

    Please enter 'yes' to indicate your agreement [no]: yes

    Once you provide a few initial configuration settings,
    OpenVPN Access Server can be configured by accessing
    its Admin Web UI using your Web browser.

    Will this be the primary Access Server node?
    (enter 'no' to configure as a backup or standby node)
    > Press ENTER for default [yes]: yes

    Please specify the network interface and IP address to be
    used by the Admin Web UI:
    (1) all interfaces: 0.0.0.0
    (2) eth0: 172.32.0.214
    Please enter the option number from the list above (1-2).
    > Press Enter for default [2]: 2

    Please specify the port number for the Admin Web UI.
    > Press ENTER for default [943]:

    Please specify the TCP port number for the OpenVPN Daemon
    > Press ENTER for default [443]:

    Should client traffic be routed by default through the VPN?
    > Press ENTER for default [no]: yes

    Should client DNS traffic be routed by default through the VPN?
    > Press ENTER for default [no]: yes

    Use local authentication via internal DB?
    > Press ENTER for default [yes]: no

    Private subnets detected: ['172.32.0.0/16']

    Should private subnets be accessible to clients by default?
    > Press ENTER for EC2 default [yes]: yes

    To initially login to the Admin Web UI, you must use a
    username and password that successfully authenticates you
    with the host UNIX system (you can later modify the settings
    so that RADIUS or LDAP is used for authentication instead).

    You can login to the Admin Web UI as "openvpn" or specify
    a different user account to use for this purpose.

    Do you wish to login to the Admin UI as "openvpn"?
    > Press ENTER for default [yes]: yes

    > Please specify your OpenVPN-AS license key (or leave blank to specify later):

    Initializing OpenVPN...
    Adding new user login...
    useradd -s /sbin/nologin "openvpn"
    Writing as configuration file...

    [...]

    NOTE: Your system clock must be correct for OpenVPN Access Server
    to perform correctly.  Please ensure that your time and date
    are correct on this system.

    Initial Configuration Complete!

    You can now continue configuring OpenVPN Access Server by
    directing your Web browser to this URL:

    https://public_ip_address:943/admin
    Login as "openvpn" with the same password used to authenticate
    to this UNIX host.

    During normal operation, OpenVPN AS can be accessed via these URLs:
    Admin  UI: https://public_ip_address:943/admin
    Client UI: https://public_ip_address:943/

    See the Release Notes for this release at:
       http://www.openvpn.net/access-server/rn/openvpn_as_2_1_9.html

When initialisation is completed, you have to reset the user password:

    sudo passwd openvpn

Finally you can access the admin panel at https://openvpn.yourdomain.com:943/admin.

In order to establish a VPN connection, download the locked profile on https://openvpn.yourdomain.com:943, configure your OpenVPN client and then connect your client to OpenVPN server.

## Services discovery

Use Consul UI to check the state of your services:

    https://consul.yourprivatedomain.com

You might want to use Consul for services discovery in your applications as well.

## Centralised logging

Use Kibana to analyse the log files of yours servers:

    https://kibana.yourprivatedomain.com

If your applications are running in a Docker container managed by ECS, then log files are automatically collected and sent to Logstash. Alternatively you can ship your logs directly to Logstash using your logging framework or using Filebeat.

## Delivery pipelines

Create your delivery pipelines using Jenkins:

    https://jenkins.yourprivatedomain.com

Integrate your build pipeline with SonarQube to analyse your code:

    https://sonarqube.yourprivatedomain.com

Integrate your build pipeline with Artifactory to manage your artifacts:

    https://artifactory.yourprivatedomain.com

Deploy your application to ECS or EC2, manually or using Jenkins CI.

## Disable access from Bastion

Bastion server could be stopped or destroyed after creating the infrastructure. The server can be recreated when needed.

Stop the Bastion server from AWS console.

Remove the Bastion server with command:

    ./run_script.sh destroy_bastion

## Delete secrets is S3 bucket

Secrets stored in S3 could be deleted after creating the infrastructure.

Create a backup if you think you might need them later to configure other machines.
