# Infrastructure as code

THIS PROJECT IS WORK IN PROGRESS

This repository contains scripts for creating a production-ready cloud-based infrastructure for running micro-services.

The scripts use several tools including Docker, Terraform and Packer, and they target AWS.

The generated infrastructure provides the following key components:

- Logstash, Elasticsearch and Kibana for collecting and visualising logs

- Jenkins, SonarQube and Artifactory for creating a delivery pipeline

- ECS for orchestrating Docker containers

- Consul for services discovery

- OpenVPN for connecting to private servers.

The scripts provided in this repository aim to automate a very complex process which involves several components and requires many steps.
The ultimate goal is to be able to rapidly and reliably create a scalable and secure infrastructure for running micro-services.

### Configure your environment

Before you start, you need to configure your environment.

Prepare your environment installing Docker CE. Follow instructions on page https://docs.docker.com/engine/installation.

You must have a valid AWS account. You can create a new account here https://aws.amazon.com.

    Configure your credentials according to AWS documentation

Check you have valid AWS credentials in file ~/.aws/credentials:

    [default]
    aws_access_key_id = "your_access_key_id"
    aws_secret_access_key = "your_secret_access_key"

Create a file config.tfvars in folder config. The file should look like:

    # AWS Account
    account_id="your_account_id"

    # Public Hosted Zone
    public_hosted_zone_name="yourdomain.com"
    public_hosted_zone_id="your_public_zone_id"

    # Private Hosted Zone
    hosted_zone_name="yourprivatedomain.com"

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

Create a file config_vars.json in folder config. The file should look like:

    {
      "account_id": "your_account_id",
      "bastion_host": "bastion.yourdomain.com"
    }

The domain yourdomain.com must be a valid domain hosted in a Route53 public zone and it must support HTTPS.

    Create a new public zone and register a new domain if you don't have one already

The domain yourprivatedomain.com can be the same as yourdomain.com or a different one.
A new private zone will be created and used to register all internal servers.

Create or copy a valid HTTPS certificate and private key in certificates folder:

    certificates/fullchain.pem
    certificates/privatekey.pem

The certificate must be a wildcard certificate or it must have issued for this list of domains:

    consul.yourprivatedomain.com
    kibana.yourprivatedomain.com
    jenkins.yourprivatedomain.com
    sonarqube.yourprivatedomain.com
    artifactory.yourprivatedomain.com

The certificate and private key will be used to provision a private ELB to access internal servers.

You can use a self-signed certificates if you wish, but your browser will warn you when you try to access the above domains.

### Create Docker image

Execute script run_build.sh to create the Docker image required to build the infrastructure:

    sh run_build.sh

The image will contain the required tools, including AWS CLI, Terraform, Packer, and others.

### Configure Terraform backend

Terraform requires a S3 Bucket to store the remote state.

Create a S3 bucket with the command:

    ./run_script.sh absolute_path_of_aws_folder create_bucket your_bucket_name eu-west-1

Please note that the bucket name must be unique among all S3 buckets.

Once the bucket has been created, execute the command:

    ./run_script.sh absolute_path_of_aws_folder configure_terraform your_bucket_name eu-west-1

The script will set the bucket name and region in all remote_state.tf files.

  The AWS folder is typically under your home folder and it is called .aws.

### Generate secrets

Certificates and keystores are required to create a secure infrastructure.

Create the secrets with the command:

    ./run_script.sh absolute_path_of_aws_folder generate_secrets

### Generate SSH keys

SSH keys are required to access servers running in EC2 machines.

Create the SSH keys with the command:

    ./run_script.sh absolute_path_of_aws_folder generate_keys

### Configure Consul

Create configuration variables for Consul with the command:

    ./run_script.sh absolute_path_of_aws_folder configure_consul

### Create VPC and subnets

Create VPCs and subnets with command:

    ./run_script.sh absolute_path_of_aws_folder create_vpc

### Build images

Server machines are provisioned using some custom AMI.

Create the images with the command:

    ./run_script.sh absolute_path_of_aws_folder build_images

### Create infrastructure

Create the infrastructure with command:

  ./run_script.sh absolute_path_of_aws_folder create_all

Or create the infrastructure in three steps:

  ./run_script.sh absolute_path_of_aws_folder create_keys
  ./run_script.sh absolute_path_of_aws_folder create_network
  ./run_script.sh absolute_path_of_aws_folder create_stack

### Destroy infrastructure

Destroy the infrastructure with command:

./run_script.sh absolute_path_of_aws_folder destroy_all

Or destroy the infrastructure in three steps:

  ./run_script.sh absolute_path_of_aws_folder destroy_stack
  ./run_script.sh absolute_path_of_aws_folder destroy_network
  ./run_script.sh absolute_path_of_aws_folder destroy_keys

### Configure OpenVPN

Login via SSH to OpenVPN server using hostname openvpn.yourdomain.com:

    ssh -i deployer_key.pem openvpnas@openvpn.yourdomain.com

The OpenVPN server will ask you to answer a few questions. The output should look like:

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
    Perform sa init...
    Wiping any previous userdb...
    Creating default profile...
    Modifying default profile...
    Adding new user to userdb...
    Modifying new user as superuser in userdb...
    Getting hostname...
    Hostname: 34.250.152.43
    Preparing web certificates...
    Getting web user account...
    Adding web group account...
    Adding web group...
    Adjusting license directory ownership...
    Initializing confdb...
    Generating init scripts...
    Generating PAM config...
    Generating init scripts auto command...
    Starting openvpnas...

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

After initialising the OpenVPN server, you have to reset the openvpn user password:

    sudo passwd openvpn

Finally you can access the admin panel at https://openvpn.yourdomain.com:943/admin to change the configuration if required.

In order to establish a VPN connection, download the locked profile on https://openvpn.yourdomain.com:943,
configure your OpenVPN client and then connect your client to OpenVPN server.
You will be able to access any machine in public or private subnets.

## How to use the infrastructure

Use OpenVPN to create a connection:

    https://openvpn.yourdomain.com:943

Use Consul UI to check the state of your services:

    https://consul.yourprivatedomain.com

Use Kibana to analyse the log files of yours servers:

    https://kibana.yourprivatedomain.com

Create your build pipelines using Jenkins:

    https://jenkins.yourprivatedomain.com

Integrate your build pipeline with SonarQube to analyse your code:

    https://sonarqube.yourprivatedomain.com

Integrate your build pipeline with Artifactory to manage your artifacts:

    https://artifactory.yourprivatedomain.com

Deploy your application in ECS or EC2. You can manually deploy your application or create scripts to run from Jenkins.
Your application might use Consul for service discovery. If your application is running in a Docker container managed
by ECS, the logs will be automatically collected and sent to Logstash. Alternatively you can ship your logs directly
to Logstash or use Filebeat to collect your logs.
