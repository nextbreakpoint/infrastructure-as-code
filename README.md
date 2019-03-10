# Infrastructure as code

This repository contains scripts for creating a production-grade infrastructure for running micro-services on the Cloud. The scripts implement a simple and reliable process for creating a scalable and secure infrastructure on [AWS](https://aws.amazon.com). The infrastructure consumes the minimum resources required to run the essential services, but it can be scaled in order to manage a higher workload, adding more machines and upgrading the type of the machines.

The infrastructure includes the following components:

- [Logstash](https://www.elastic.co/products/logstash), [Elasticsearch](https://www.elastic.co/products/elasticsearch) and [Kibana](https://www.elastic.co/products/kibana) for collecting and analysing logs

- [Jenkins](https://jenkins-ci.org), [SonarQube](https://www.sonarqube.org) and [Artifactory](https://jfrog.com/artifactory/) for creating a delivery pipeline

- [Consul](https://www.consul.io) for discovering machines or services

- [Graphite](https://graphiteapp.org) and [Grafana](https://grafana.com) for collecting metrics and monitoring services

- [Cassandra](http://cassandra.apache.org), [Kafka](https://kafka.apache.org), [Zookeeper](https://zookeeper.apache.org) for creating scalable event-driven services

- [OpenVPN](https://openvpn.net) for creating a secure connection to private machines

The infrastructure is based on Docker containers running on a [Docker Swarm](https://docs.docker.com/engine/swarm/) cluster which includes several EC2 machines. Most of the machines are created within a private network and they are reachable via VPN connection, using OpenVPN, or via SSH, using a bastion machine. Some machines are created within a public network and they are reachable via ip address. The private machines can be reached using an internet-facing load balancer or a proxy server running in a public subnet.

The infrastructure is managed by using [Docker](https://www.docker.com), [Terraform](https://www.terraform.io) and [Packer](https://www.packer.io).

    BEWARE OF THE COST OF RUNNING THE INFRASTRUCTURE ON AWS. WE ARE NOT RESPONSIBLE FOR ANY CHARGES

## Prepare workstation

Follow the [instructions](https://docs.docker.com/engine/installation) on Docker.com to install Docker CE version 18.03 or later. Docker is the only tool that you need to install on your workstation.

## Configure AWS credentials

Create a new [AWS account](https://aws.amazon.com) or use an existing one if you can assign the required permissions to your user. In order to create the infrastructure, your must have full administration permissions (alternatively you can start with minimal permissions and add what is required as you go, but at the moment we don't provide the complete policy).

Create a new Access Key for your user and save the credentials on your workstation. AWS credentials are typically stored at location ~/.aws/credentials.

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

    You can use self-signed certificates, just remember that your browser will warn you when accessing resources on those domains

## Build Docker image

Create the Docker image that you will use to build the infrastructure:

    ./docker_build.sh

The image contains the tools you need to manage the infrastructure, including AWS CLI, Terraform, Packer, and others.

## Configure S3 buckets

Two S3 buckets are required for creating the infrastructure. The first bucket is required for storing secrets and certificates. The second bucket is required for storing Terraform's remote state. Since the buckets contains sensible data, the access must be restricted.

    Consider enabling KMS encryption on the bucket to increase security

Create a S3 bucket for secrets with command:

    ./docker_run.sh make_bucket your_secrets_bucket_name

Create a S3 bucket for Terraform with command:

    ./docker_run.sh make_bucket your_terraform_bucket_name

Once the buckets has been created, configure the Terraform's backend with command:

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
        "elasticsearch_password": "your_password",

        "cassandra_username": "cassandra",
        "cassandra_password": "cassandra"
    }

Change the variables to the correct values for your infrastructure. The account id must represent a valid AWS account and your AWS credentials must have the correct permissions on that account. The domain yourdomain.com must be a valid domain hosted in a Route53's public zone.

    Register a new domain with AWS if you don't have one already and create a new public zone

## Generate secrets

Create the secrets with command:

    ./docker_run.sh generate_secrets

Several certificates and passwords are required to create a secure infrastructure.

## Generate SSH keys

Generate the SSH keys with command:

    ./docker_run.sh generate_keys

SSH keys are required to access EC2 machines.

## Configure Consul

Create a configuration for Consul with command:

    ./docker_run.sh configure_consul

## Create VPCs

Create the VPCs with command:

    ./docker_run.sh module_create vpc

## Create SSH keys

Create the SSH keys with command:

    ./docker_run.sh module_create keys

## Create Bastion network

Create the Bastion network with command:

    ./docker_run.sh module_create bastion

## Build images with Packer

Create the AMI images with command:

    ./docker_run.sh build_images

Some EC2 machines are provisioned using custom AMI.

The script might take quite a while. Once the images have been created, you don't need to recreate them unless something has changed in the provisioning scripts. Reusing the same images, considerably reduces the time required to create the infrastructure.

    If you destroy the infrastructure but you don't delete the AMIs, then you can skip this step when you recreate the infrastructure

## Create the infrastructure

Create secrets with command:

    ./docker_run.sh module_create secrets

Create subnets and NAT machines with command:

    ./docker_run.sh module_create network

Create Swarm nodes with command:

    ./docker_run.sh module_create swarm

The Swarm cluster includes 3 manager nodes and 6 worker nodes:

    prod-green-swarm-manager-a.yourdomain.com
    prod-green-swarm-manager-b.yourdomain.com
    prod-green-swarm-manager-c.yourdomain.com
    prod-green-swarm-worker-int-a.yourdomain.com
    prod-green-swarm-worker-int-b.yourdomain.com
    prod-green-swarm-worker-int-c.yourdomain.com
    prod-green-swarm-worker-ext-a.yourdomain.com
    prod-green-swarm-worker-ext-b.yourdomain.com
    prod-green-swarm-worker-ext-c.yourdomain.com

The single letter at the end of the name represents the availability zone.    

## Create Bastion server (optional)

Create the Bastion server with command:

    ./docker_run.sh module_create bastion -var bastion=true

### Access machines using Bastion

Copy the deployer key to Bastion machine:

    scp -i prod-green-deployer.pem prod-green-deployer.pem ec2-user@prod-green-bastion.yourdomain.com:~

Connect to bastion server using the command:

    ssh -i prod-green-deployer.pem ec2-user@prod-green-bastion.yourdomain.com

Connect to any other machines using the command:

    ssh -i prod-green-deployer.pem ubuntu@private_ip_address

You can find the ip address of the machines on the AWS console.

## Create OpenVPN server

Create the OpenVPN server with command:

    ./docker_run.sh module_create openvpn

### Access machines using OpenVPN

A default client configuration is automatically generated at location:

    secrets/openvpn/prod/green/openvpn_client.ovpn

Install the configuration in your OpenVPN client and connect your client. OpenVPN server is configured to allow connections to any internal servers.

You should create a different configuration for each client using the command:

    ./docker_run.sh create_ovpn name

The client configuration is generated at location:

    secrets/openvpn/prod/green/openvpn_name.ovpn

If you need to modify the server configuration, login into OpenVPN server:

    ssh -i prod-green-deployer.pem ubuntu@prod-green-openvpn.yourdomain.com

Edit the file /etc/openvpn/server.conf and then restart the server:

    sudo service openvpn restart

## Create the Docker Swarm

Docker Swarm can be created when all the EC2 machines are ready.

Verify that you can ping the manager nodes:

    ping prod-green-swarm-manager-a.yourdomain.com
    ping prod-green-swarm-manager-b.yourdomain.com
    ping prod-green-swarm-manager-c.yourdomain.com

Verify that you can ping the private worker nodes:

    ping prod-green-swarm-worker-int-a.yourdomain.com
    ping prod-green-swarm-worker-int-b.yourdomain.com
    ping prod-green-swarm-worker-int-c.yourdomain.com

Verify that you can ping the public worker nodes:

    ping prod-green-swarm-worker-ext-a.yourdomain.com
    ping prod-green-swarm-worker-ext-b.yourdomain.com
    ping prod-green-swarm-worker-ext-c.yourdomain.com

If you can't ping the machines, check your VPN connection. You must be connected to access machines in private subnets.

Verify that you can login into the machines:

    ssh -i prod-green-deployer.pem ubuntu@prod-green-swarm-manager-a.yourdomain.com

Create the Swarm with command:

    ./swarm_join.sh

Configure the Swarm with command:

    ./swarm_configure.sh

Verify that the Swarm is working with command:

    ./swarm_run.sh cli "docker node ls"

It should print the list of the nodes, which should contain 6 nodes, 3 managers and 6 workers.

### Create networks

Create the overlay networks with command:

    ./swarm_run.sh create_networks

The overlay networks are used to allow communication between containers running on different machines.

### Create services

The services are deployed on the Swarm using Docker Stacks.

Deploy a stack with command:

    ./swarm_run.sh deploy_stack consul

It should create volumes and services on the worker nodes.

Verify that the services are running with command:

    ./swarm_run.sh cli "docker service ls"

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
    sonarqube (MySQL setup required)
    artifactory (MySQL setup required)

Please note that before deploying SonarQube or Artifactory, you must configure MySQL with command:

    ./swarm_run.sh setup_mysql

The connection to MySQL might fail if the database is not ready to accept connections. If the connection fails, retry the command after a minute.

### Services placement

The mapping between machines and services depends on the labels assigned to Swarm's nodes. The services are deployed according to the placement constraints in the YAML file which defines the stack of the service. The constraints are based on labels and roles of the nodes.

See documentation of [Docker Compose](https://docs.docker.com/compose/compose-file/) and [Docker Swarm](https://docs.docker.com/engine/reference/commandline/node_update/).

Please note that some services have ports exposed on the host machines, therefore are reachable from any other machine in the same VPC.

Please note that some ports are only accessible from the overlay network, and are used for internal communication between nodes of the cluster.

#### Manager A

Manager node in availability zone A

    Elasticsearch (routing only) | 9200 (tcp)
    Elasticsearch (routing only) | 9300 (tcp)
    Logstash | 5044 (tcp)
    Logstash | 9600 (tcp)
    Logstash | 12201 (tcp/udp)
    Jenkins | 8080 (tcp)
    SonarQube | 9000 (tcp)
    Artifactory | 8081 (tcp)
    MySQL | 3306 (tcp)

#### Manager B

Manager node in availability zone B

    Elasticsearch (routing only) | 9200 (tcp)
    Elasticsearch (routing only) | 9300 (tcp)
    Logstash | 5044 (tcp)
    Logstash | 9600 (tcp)
    Logstash | 12201 (tcp/udp)
    Graphite | 2080 (tcp)
    Grafana | 3000 (tcp)

#### Manager C

Manager node in availability zone C

    Elasticsearch (routing only) | 9200 (tcp)
    Elasticsearch (routing only) | 9300 (tcp)
    Logstash | 5044 (tcp)
    Logstash | 9600 (tcp)
    Logstash | 12201 (tcp/udp)
    Kibana | 5601 (tcp)

#### Worker Int A

Internal worker node in availability zone A

    Elasticsearch | 9200 (tcp)
    Elasticsearch | 9300 (tcp)
    Logstash | 5044 (tcp)
    Logstash | 9600 (tcp)
    Logstash | 12201 (tcp/udp)
    Consul | 8500 (tcp)
    Consul | 8600 (tcp/udp)
    Consul | 8300 (tcp)
    Consul | 8302  (tcp/udp)
    Zookeeper | 2181 (tcp)
    Zookeeper | 2888 (tcp)
    Zookeeper | 3888 (tcp)
    Kafka | 9092 (tcp)
    Cassandra | 9042 (tcp)

#### Worker Int B

Internal worker node in availability zone B

    Elasticsearch | 9200 (tcp)
    Elasticsearch | 9300 (tcp)
    Logstash | 5044 (tcp)
    Logstash | 9600 (tcp)
    Logstash | 12201 (tcp/udp)
    Consul | 8500 (tcp)
    Consul | 8600 (tcp/udp)
    Consul | 8300 (tcp)
    Consul | 8302  (tcp/udp)
    Zookeeper | 2181 (tcp)
    Zookeeper | 2888 (tcp)
    Zookeeper | 3888 (tcp)
    Kafka | 9092 (tcp)
    Cassandra | 9042 (tcp)

#### Worker Int C

Internal worker node in availability zone C

    Elasticsearch | 9200 (tcp)
    Elasticsearch | 9300 (tcp)
    Logstash | 5044 (tcp)
    Logstash | 9600 (tcp)
    Logstash | 12201 (tcp/udp)
    Consul | 8500 (tcp)
    Consul | 8600 (tcp/udp)
    Consul | 8300 (tcp)
    Consul | 8302  (tcp/udp)
    Zookeeper | 2181 (tcp)
    Zookeeper | 2888 (tcp)
    Zookeeper | 3888 (tcp)
    Kafka | 9092 (tcp)
    Cassandra | 9042 (tcp)

#### Worker Ext A

External worker node in availability zone A

    Nginx | 80 (tcp)
    Nginx | 443 (tcp)

#### Worker Ext B

External worker node in availability zone B

    Nginx | 80 (tcp)
    Nginx | 443 (tcp)

#### Worker Ext C

External worker node in availability zone C

    Nginx | 80 (tcp)
    Nginx | 443 (tcp)

### Remove services

Remove a service with command:

    ./swarm_run.sh remove_stack consul

The volumes associated with the service are not deleted when deleting a stack.

    The content of the volumes will still be available when recreating the stack

### Remove networks

Remove the overlay networks with command:

    ./swarm_run.sh remove_networks

## Create Load-Balancers, Target Groups and Route53 records (optional)

Create the load balancers with command:

    ./docker_run.sh module_create lb

Create target groups and Route53 records with command:

    ./docker_run.sh module_create targets

Target groups and DNS records can be used to route HTTP traffic to specific machines and ports.

You can test the routing with your browser for services with UI:

    https://prod-green-jenkins.yourdomain.com/
    https://prod-green-sonarqube.yourdomain.com/
    https://prod-green-artifactory.yourdomain.com/artifactory/webapp/#/home
    https://prod-green-kibana.yourdomain.com/
    https://prod-green-consul.yourdomain.com/
    https://prod-green-graphite.yourdomain.com/
    https://prod-green-grafana.yourdomain.com/
    https://prod-green-nginx.yourdomain.com/
    http://prod-green-nginx.yourdomain.com/

Use host and port in your client for connecting to backend services:

    prod-green-cassandra-a.yourdomain.com:9042
    prod-green-cassandra-b.yourdomain.com:9042
    prod-green-cassandra-c.yourdomain.com:9042

    prod-green-kafka-a.yourdomain.com:9092
    prod-green-kafka-b.yourdomain.com:9092
    prod-green-kafka-c.yourdomain.com:9092

    prod-green-zookeeper-a.yourdomain.com:2181
    prod-green-zookeeper-b.yourdomain.com:2181
    prod-green-zookeeper-c.yourdomain.com:2181

    prod-green-elasticsearch-a.yourdomain.com:9200
    prod-green-elasticsearch-b.yourdomain.com:9200
    prod-green-elasticsearch-c.yourdomain.com:9200

    prod-green-logstash-a.yourdomain.com:5044
    prod-green-logstash-b.yourdomain.com:5044
    prod-green-logstash-c.yourdomain.com:5044
    prod-green-logstash-a.yourdomain.com:12201
    prod-green-logstash-b.yourdomain.com:12201
    prod-green-logstash-c.yourdomain.com:12201

    prod-green-consul-a.yourdomain.com:9600
    prod-green-consul-b.yourdomain.com:9600
    prod-green-consul-c.yourdomain.com:9600

## Service discovery

You might want to use Consul for services discovery in your applications.

Deploy the agents to publish on Consul the services running on worker nodes:

    ./swarm_run.sh deploy_stack consul-workers

Use Consul UI to check the status of your services:

    https://prod-green-swarm-worker-int.yourdomain.com:8500

You can use Consul as DNS server and you can lookup for a service using a DNS query:

    dig @prod-green-swarm-worker-int.yourdomain.com -p 8600 consul.service.internal.consul
    dig @prod-green-swarm-worker-int.yourdomain.com -p 8600 logstash.service.internal.consul
    dig @prod-green-swarm-worker-int.yourdomain.com -p 8600 elasticsearch.service.internal.consul
    dig @prod-green-swarm-worker-int.yourdomain.com -p 8600 kafka.service.internal.consul
    dig @prod-green-swarm-worker-int.yourdomain.com -p 8600 zookeeper.service.internal.consul
    dig @prod-green-swarm-worker-int.yourdomain.com -p 8600 cassandra.service.internal.consul

## Collecting and analysing logs

All containers running on the Swarm are configured to send logs to Logstash, therefore the logs are available in Kibana.

Use Kibana to analyse logs and monitor services:

    https://prod-green-swarm-manager.yourdomain.com:5601

    NOTE: Default user is "elastic" with password "changeme"

The Docker daemon of the managers and workers is configured to use the GELF logging driver. Update the configuration and restart the Docker daemons if you have problem with this configuration and you cannot see the logs. Alternatively you can override the logging configuration when running a container or a service.

## Collecting metrics and monitoring

Use Graphite and Grafana to collect metrics and monitor services:

    http://prod-green-swarm-manager.yourdomain.com:3000
    http://prod-green-swarm-manager.yourdomain.com:2080

    NOTE: Default user is "admin" with password "admin"

Configure your applications to send metrics to Graphite:

    http://prod-green-swarm-manager.yourdomain.com:2003

Define a Graphite source and create dashboards in Grafana.

## Building reactive services

Use Zookeeper, Kafka, Cassandra, and Elasticsearch to build reactive services.

Zookeeper is configured to use SASL with MD5 passwords.

Kafka is configured with SSL connections between brokers and clients.

Cassandra doesn't enforce secure connections by default.

Elasticsearch is configured with SSL connections between nodes (X-Pack enabled with trial licence).

See the scripts test_kafka_consume.sh and test_kafka_produce.sh for a example of client configuration.

## Creating delivery pipelines

Create your delivery pipelines using Jenkins:

    https://prod-green-swarm-manager.yourdomain.com:8443
    http://prod-green-swarm-manager.yourdomain.com:8080

    NOTE: Security is disabled by default

Integrate your build pipeline with SonarQube to analyse your code:

    http://prod-green-swarm-manager.yourdomain.com:9000

    NOTE: Default user is "admin" with password "admin"

Integrate your build pipeline with Artifactory to manage your artifacts:

    http://prod-green-swarm-manager.yourdomain.com:8081

    NOTE: Default user is "admin" with password "password"

Deploy your applications to Docker Swarm or EC2, manually or using Jenkins CI.

## Disable access via Bastion

Bastion server can be stopped or destroyed if required. The server can be recreated when needed.

    Stop Bastion server from AWS console

## Disable access via OpenVPN

OpenVPN server can be stopped or destroyed if required. The server can be recreated when needed.

    Stop OpenVPN server from AWS console

## Destroy Load-Balancers, Target Groups and Route53 records

Destroy Target Groups and Route53 records with command:

    ./docker_run.sh module_destroy targets

Destroy Load-Balancers with command:

    ./docker_run.sh module_destroy lb

## Destroy the infrastructure

Destroy Swarm nodes with commands:

    ./docker_run.sh module_destroy swarm

Destroy subnets and NAT machines with commands:

    ./docker_run.sh module_destroy network

Destroy secrets with commands:

    ./docker_run.sh module_destroy secrets

## Destroy Bastion server

Destroy Bastion with command:

    ./docker_run.sh module_destroy bastion

## Destroy OpenVPN server

Destroy OpenVPN with command:

    ./docker_run.sh module_destroy openvpn

## Destroy network

Destroy the network with command:

    ./docker_run.sh module_destroy network

Please note that network can be destroyed only after destroying infrastructure, Bastion and OpenVPN.

## Destroy VPC

Destroy the VPC with command:

    ./docker_run.sh module_destroy vpc

Please note that network can be destroyed only after destroying all, including network.

## Destroy SSH keys

Destroy the SSH keys with command:

    ./docker_run.sh module_destroy keys

## Delete images

Delete the AMIs with command:

    ./docker_run.sh delete_images

## Reset Terraform state

Reset Terraform state with command:

    ./docker_run.sh reset_terraform

Be careful to don't reset the state before destroying all managed infrastructure.
