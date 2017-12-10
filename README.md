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
    aws_access_key_id = ???
    aws_secret_access_key = ???

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

Create a file config_vars.json like this:

    {
      "account_id": "your_account_id",
      "bastion_host": "bastion.yourdomain.com"
    }

The domain yourdomain.com must be a domain hosted in a Route53 public zone and must support HTTPS.

    Create a new public zone and register a new domain if you don't have one already

Create or copy a HTTPS certificate and server key at location:

    certificates/fullchain.pem
    certificates/serverkey.pem

Certificate must be valid for all domains:

    consul.yourprivatedomain.com
    kibana.yourprivatedomain.com
    jenkins.yourprivatedomain.com
    sonarqube.yourprivatedomain.com
    artifactory.yourprivatedomain.com

Those certificate and key will be used for the private ELB.

### Configure Terraform backend

Terraform requires a S3 Bucket to store the remote state.

Create a S3 bucket with the command:

    sh scripts/create_bucket.sh your_bucket_name eu-west-1

Please note that the bucket name must be unique among all S3 buckets.

Once the bucket has been created, execute the command:

    sh scripts/configure_bucket.sh your_bucket_name eu-west-1

The script will set the bucket name and region in all remote_state.tf files.

### Create Docker image

Execute script run_build.sh to create the Docker image required to build the infrastructure:

    sh run_build.sh

The image will contain the required tools, including AWS CLI, Terraform, Packer, and others.

### Create infrastructure

Execute script run_create.sh to create the infrastructure:

    sh run_create.sh /path_of_aws_folder

### Destroy infrastructure

Execute script run_destroy.sh to destroy the infrastructure:

    sh run_destroy.sh /path_of_aws_folder

### Configure OpenVPN

Login via SSH to OpenVPN server using hostname openvpn.yourdomain.com:

    ssh -i deployer_key.pem openvpnas@openvpn.yourdomain.com

The OpenVPN server will ask you to answer a few questions. The output should look like:

    ...

After initialising the OpenVPN server, you have to reset the openvpn user password:

    sudo passwd openvpn

Then you can access the admin panel at https://openvpn.yourdomain.com:943/admin to change the configuration if required.

Download the locked profile on https://openvpn.yourdomain.com:943 and configure your OpenVPN client.

From your client, you can now connect to the any machine in public or private subnets.

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
