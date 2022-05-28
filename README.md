
# Infrastructure as code

This repository contains the resources for creating a minimal infrastructure for running micro-services on [Kubernetes](https://kubernetes.io).

    THIS PROJECT IS WORK IN PROGRESS

We provide a simple and reliable process for creating a scalable and secure infrastructure on [AWS](https://aws.amazon.com).
The infrastructure is configured to use the minimum amount of resources required to run the essential services,
but it can be scaled in order to manage a higher workload, and extended with additional components if needed.


## Requirements

You need an AWS account for creating the infrastructure. Create one on [AWS](https://aws.amazon.com) if you don't have one already.

    BEWARE OF THE COST OF RUNNING THE INFRASTRUCTURE ON AWS. WE ARE NOT RESPONSIBLE FOR ANY CHARGES

Once you have created your account, save the account id, you will need it soon.


## Setup

Install AWS CLI v2:

    curl "https://awscli.amazonaws.com/AWSCLIV2.pkg" -o "AWSCLIV2.pkg"
    sudo installer -pkg AWSCLIV2.pkg -target /

Install required tools:

    brew install jq
    brew install terragrunt
    brew install kubernetes-cli
    brew tap weaveworks/tap
    brew install weaveworks/tap/eksctl
    brew install aws-iam-authenticator

Install optional tools:

    brew install kubectx
    brew install tfenv
    tfenv install 1.2.1
    tfenv use 1.2.1


## Bootstrap

You will need a user which has the right permissions to configure the required resources before we can automate the process.
You could use your AWS root account, but we don't recommend it, because that user has high privileges. We recommend instead
that you manually create from the AWS web console a new user with only the required privileges.

Sign in to your AWS account:

  open https://${YOUR_AWS_ACCOUNT_ID}.signin.aws.amazon.com/console

Create a user "Superuser", attach the policy arn:aws:iam::aws:policy/IAMFullAccess, and create an access key (keep access key details secret).
We will use the user to create users and groups, and to create the fundamental roles and policies required for managing the infrastructure.

Create an AWS profile (you will need the access key details):

    ./add-profile.sh --profile=superuser \
      --region=${YOUR_AWS_REGION} \
      --access-key-id=${SUPERUSER_ACCESS_KEY_ID} \
      --secret-access-key=${SUPERUSER_SECRET_ACCESS_KEY} \

Create SSH keys (you will need them later to access the EC2 machines):

    ./make-keys.sh --path=keys --environment=prod --colour=green

Copy the keys to a safe place and share them only with people who you trust.

Create policy files:

    ./make-policies.sh --account=${YOUR_AWS_ACCOUNT_ID}

Create bootstrap role:

    aws --profile superuser iam create-role \
        --role-name Terraform-Manage-Bootstrap \
        --assume-role-policy-document file://policies/assume-role.json

Create bootstrap group:

    aws --profile superuser iam create-group --group-name Terraform-Bootstrap

Configure role policies:

    aws --profile superuser iam attach-role-policy \
        --role-name Terraform-Manage-Bootstrap \
        --policy-arn arn:aws:iam::aws:policy/IAMFullAccess

    aws --profile superuser iam attach-role-policy \
        --role-name Terraform-Manage-Bootstrap \
        --policy-arn arn:aws:iam::aws:policy/AmazonS3FullAccess

    aws --profile superuser iam attach-role-policy \
        --role-name Terraform-Manage-Bootstrap \
        --policy-arn arn:aws:iam::aws:policy/AmazonDynamoDBFullAccess

    aws --profile superuser iam attach-role-policy \
        --role-name Terraform-Manage-Bootstrap \
        --policy-arn arn:aws:iam::aws:policy/AWSCertificateManagerFullAccess

Configure group policies:

    aws --profile superuser iam put-group-policy \
        --group-name Terraform-Bootstrap \
        --policy-name Terraform-Manage-Bootstrap \
        --policy-document file://policies/assume-role-manage-boostrap.json

Create a user "BootstrapAdmin", assign a group, create an access key and AWS profile:

    ./create-user.sh --profile=superuser --user-profile=bootstrap-admin \
      --user-name=BootstrapAdmin --group-name=Terraform-Bootstrap --region=${YOUR_AWS_REGION}

Create a user "SecurityAdmin", assign a group, create an access key and AWS profile:

    ./create-user.sh --profile=superuser --user-profile=security-admin \
      --user-name=SecurityAdmin --group-name=Terraform-Security --region=${YOUR_AWS_REGION}

Create a user "NetworksAdmin", assign a group, create an access key and AWS profile:

    ./create-user.sh --profile=superuser --user-profile=networks-admin \
      --user-name=NetworksAdmin --group-name=Terraform-Networks --region=${YOUR_AWS_REGION}

Create a user "ServersAdmin", assign a group, create an access key and AWS profile:

    ./create-user.sh --profile=superuser --user-profile=servers-admin \
      --user-name=ServersAdmin --group-name=Terraform-Servers --region=${YOUR_AWS_REGION}

Create a user "ClustersAdmin", assign a group, create an access key and AWS profile:

    ./create-user.sh --profile=superuser --user-profile=clusters-admin \
      --user-name=ClustersAdmin --group-name=Terraform-Clusters --region=${YOUR_AWS_REGION}

Create a user "Packer", assign a group, create an access key and AWS profile:

    ./create-user.sh --profile=superuser --user-profile=packer \
      --user-name=Packer --group-name=Packer-Build --region=${YOUR_AWS_REGION}

Create a user "Developer", assign a group, create an access key and AWS profile:

    ./create-user.sh --profile=superuser --user-profile=developer \
      --user-name=Developer --group-name=Developers --region=${YOUR_AWS_REGION}

Ensure you have created two certificates (one for public servers and the other for private servers):

    aws --profile bootstrap-admin acm request-certificate --domain-name '*.${YOUR_ZONE_NAME}' --validation-method DNS    
    aws --profile bootstrap-admin acm request-certificate --domain-name '*.internal.${YOUR_ZONE_NAME}' --validation-method DNS    

Initialize Terraform state:

    ./terraform-state.sh --profile=bootstrap-admin --account=${YOUR_AWS_ACCOUNT_ID} --region=${YOUR_AWS_REGION} --bucket=${YOUR_TERRAFORM_BUCKET_NAME}

Configure Terragrunt script (see script for additional configuration parameters):

    ./terragrunt-configure.sh --region=${YOUR_AWS_REGION} \
      --terraform-bucket-name=${YOUR_TERRAFORM_BUCKET_NAME} --openvpn-bucket-name=${YOUR_OPENVPN_BUCKET_NAME} \
      --hosted-zone-id=${YOUR_ROUTE53_ZONE_ID} --hosted-zone-name=${YOUR_ROUTE53_ZONE_NAME} \
      --keys-path=${YOUR_KEYS_PATH} --environment=prod --colour=green

Create bootstrap resources:

    ./terragrunt-run.sh --profile=bootstrap-admin --account=${YOUR_AWS_ACCOUNT_ID} --region=${YOUR_AWS_REGION} --bucket=${YOUR_TERRAFORM_BUCKET_NAME} --module=bootstrap


## Security

We can now create the remaining groups, roles, and policies for managing the infrastructure.
We will run Terraform using a role that has the minimum required permissions for performing the task.

Create resources:

    ./terragrunt-run.sh --profile=security-admin --account=${YOUR_AWS_ACCOUNT_ID} --region=${YOUR_AWS_REGION} --bucket=${YOUR_TERRAFORM_BUCKET_NAME} --module=security


## Networks

We can now create the required VPCs, subnets, and routing tables for the infrastructure.
We will run Terraform using a role that has the minimum required permissions for performing the task.

Create resources:

    ./terragrunt-run.sh --profile=networks-admin --account=${YOUR_AWS_ACCOUNT_ID} --region=${YOUR_AWS_REGION} --bucket=${YOUR_TERRAFORM_BUCKET_NAME} --module=vpcs
    ./terragrunt-run.sh --profile=networks-admin --account=${YOUR_AWS_ACCOUNT_ID} --region=${YOUR_AWS_REGION} --bucket=${YOUR_TERRAFORM_BUCKET_NAME} --module=subnets


## Servers

We can now create the required servers to access the machines in the private networks.
We will run Terraform using a role that has the minimum required permissions for performing the task.

Build AMI images (you will need one of the SSH keys):

    PACKER_BUILD_SUBNET=$(./query-subnet.sh --profile=networks-admin --key="bastion-public-subnet-a-id" --region=${YOUR_AWS_REGION} --bucket=${YOUR_TERRAFORM_BUCKET_NAME})
    ./build-image.sh --profile=packer --account=${YOUR_AWS_ACCOUNT_ID} --region=${YOUR_AWS_REGION} --subnet=${PACKER_BUILD_SUBNET} --ssh-key=prod-green-packer --image=openvpn --version=1.0
    ./build-image.sh --profile=packer --account=${YOUR_AWS_ACCOUNT_ID} --region=${YOUR_AWS_REGION} --subnet=${PACKER_BUILD_SUBNET} --ssh-key=prod-green-packer --image=server --version=1.0

Create bucket for OpenVPN secrets:

    ./openvpn-init-secrets.sh --profile=bootstrap-admin --account=${YOUR_AWS_ACCOUNT_ID} --region=${YOUR_AWS_REGION} --bucket=${YOUR_OPENVPN_BUCKET_NAME}

Create resources:

    ./terragrunt-run.sh --profile=servers-admin --account=${YOUR_AWS_ACCOUNT_ID} --region=${YOUR_AWS_REGION} --bucket=${YOUR_TERRAFORM_BUCKET_NAME} --module=keys
    ./terragrunt-run.sh --profile=servers-admin --account=${YOUR_AWS_ACCOUNT_ID} --region=${YOUR_AWS_REGION} --bucket=${YOUR_TERRAFORM_BUCKET_NAME} --module=bastion
    ./terragrunt-run.sh --profile=servers-admin --account=${YOUR_AWS_ACCOUNT_ID} --region=${YOUR_AWS_REGION} --bucket=${YOUR_TERRAFORM_BUCKET_NAME} --module=openvpn
    ./terragrunt-run.sh --profile=servers-admin --account=${YOUR_AWS_ACCOUNT_ID} --region=${YOUR_AWS_REGION} --bucket=${YOUR_TERRAFORM_BUCKET_NAME} --module=servers

Download OpenVPN secrets (it might take some time for the server to create the secrets):

    ./openvpn-get-secrets.sh --profile=bootstrap-admin --account=${YOUR_AWS_ACCOUNT_ID} --region=${YOUR_AWS_REGION} --bucket=${YOUR_OPENVPN_BUCKET_NAME}

Use the client.pvpn file to configure OpenVPN Connect and access the EC2 machines.

After connecting to the VPN run the command:

    ssh -i keys/prod-green-server.pem ubuntu@<the_private_ip_address_or_hostname_of_ec2_machine>

You can access the bastion machine without VPN:

    ssh -i keys/prod-green-bastion.pem ubuntu@prod-green-bastion.${YOUR_ZONE_NAME}


## Clusters

We can now create the Kubernetes cluster and related resources, including load balancers.
We will run Terraform using a role that has the minimum required permissions for performing the task.

Create resources:

    ./terragrunt-run.sh --profile=clusters-admin --account=${YOUR_AWS_ACCOUNT_ID} --region=${YOUR_AWS_REGION} --bucket=${YOUR_TERRAFORM_BUCKET_NAME} --module=k8s
    ./terragrunt-run.sh --profile=clusters-admin --account=${YOUR_AWS_ACCOUNT_ID} --region=${YOUR_AWS_REGION} --bucket=${YOUR_TERRAFORM_BUCKET_NAME} --module=lbs

Get Kubernetes config:

    ./k8s-get-config.sh --profile=clusters-admin --account=${YOUR_AWS_ACCOUNT_ID} --region=${YOUR_AWS_REGION} --cluster=prod-green-k8s --role=Developers

Configure namespace:

    ./k8s-configure-namespace.sh --profile=clusters-admin --account=${YOUR_AWS_ACCOUNT_ID} --region=${YOUR_AWS_REGION} --cluster=prod-green-k8s --namespace=test

Configure role:

    ./k8s-configure-role.sh --profile=clusters-admin --account=${YOUR_AWS_ACCOUNT_ID} --region=${YOUR_AWS_REGION} --cluster=prod-green-k8s --namespace=test --role=Developers

Get Kubernetes config as user "Developer":

    ./k8s-get-config.sh --profile=developer --account=${YOUR_AWS_ACCOUNT_ID} --region=${YOUR_AWS_REGION} --cluster=prod-green-k8s --role=Developers

Access Kubernetes as user "Developer":

    AWS_PROFILE=developer kubectl -n test get pod


## Notes

Disable the access keys you don't use to increase security:

    USER_ACCESS_KEY_ID=$(aws --profile superuser iam list-access-keys --user-name BootstrapAdmin | jq -r ".AccessKeyMetadata[0].AccessKeyId")
    aws --profile superuser iam update-access-key --access-key-id ${USER_ACCESS_KEY_ID} --status Inactive --user-name BootstrapAdmin

Configure password policy:

    aws --profile superuser iam update-account-password-policy --minimum-password-length 8 \
      --require-numbers --require-uppercase-characters --require-lowercase-characters --require-symbols --max-password-age 30

Create a AWS console user and enable MFA:

    aws --profile superuser iam create-user --user-name SomeUser
    aws --profile superuser iam create-login-profile --user-name SomeUser --password-reset-required --password password
    aws --profile superuser iam create-virtual-mfa-device --virtual-mfa-device-name someuser-mfa-device --outfile QRCode.png --bootstrap-method QRCodePNG
    aws --profile superuser iam enable-mfa-device --user-name SomeUser --serial-number arn:aws:iam::${YOUR_AWS_ACCOUNT_ID}:mfa/someuser-mfa-device --authentication-code1 ${FIRST_CODE} --authentication-code2 ${SECOND_CODE}

Create an administrators group:

    aws --profile superuser iam create-group --group-name Administrators
    aws --profile superuser iam attach-group-policy --group-name Administrators --policy-arn arn:aws:iam::aws:policy/IAMFullAccess
    aws --profile superuser iam attach-group-policy --group-name Administrators --policy-arn arn:aws:iam::aws:policy/AmazonEC2ReadOnlyAccess
    aws --profile superuser iam attach-group-policy --group-name Administrators --policy-arn arn:aws:iam::aws:policy/AmazonVPCReadOnlyAccess
    aws --profile superuser iam attach-group-policy --group-name Administrators --policy-arn arn:aws:iam::aws:policy/AmazonS3ReadOnlyAccess
    aws --profile superuser iam attach-group-policy --group-name Administrators --policy-arn arn:aws:iam::aws:policy/IAMAccessAnalyzerReadOnlyAccess
    aws --profile superuser iam attach-group-policy --group-name Administrators --policy-arn arn:aws:iam::aws:policy/AWSCertificateManagerReadOnly
    aws --profile superuser iam attach-group-policy --group-name Administrators --policy-arn arn:aws:iam::aws:policy/AmazonRoute53ReadOnlyAccess
    aws --profile superuser iam attach-group-policy --group-name Administrators --policy-arn arn:aws:iam::aws:policy/AmazonDynamoDBReadOnlyAccess
    aws --profile superuser iam attach-group-policy --group-name Administrators --policy-arn arn:aws:iam::aws:policy/AWSBillingReadOnlyAccess
    aws --profile superuser iam attach-group-policy --group-name Administrators --policy-arn arn:aws:iam::${YOUR_AWS_ACCOUNT_ID}:policy/EKS-Console

Add an administrator user:

    aws --profile superuser iam add-user-to-group --user-name SomeUser --group-name Administrators

Allow a user to decode an authorization messages:

    aws --profile superuser iam attach-user-policy --user-name Superuser --policy-arn arn:aws:iam::${YOUR_AWS_ACCOUNT_ID}:policy/Decode-Authorization-Message

Decode authorization messages to debug permission issues:

    ./decode-message.sh --profile=bootstrap --account=${YOUR_AWS_ACCOUNT_ID} --message=${THE_ENCODED_MESSAGE}     

Remove access to the Kubernetes cluster for a role:

    eksctl delete iamidentitymapping --cluster prod-green-k8s --region=${YOUR_AWS_REGION} --arn arn:aws:iam::${YOUR_AWS_ACCOUNT_ID}:role/Test-Developers

Restrict access to OpenVPN bucket to increase security:

    cat <<EOF >policies/bucket-openvpn-deny-access.json
    {
      "Version": "2012-10-17",
      "Statement": [
        {
          "Effect": "Deny",
          "Principal": "*",
          "Action": "s3:*",
          "Resource": [
            "arn:aws:s3:::${YOUR_OPENVPN_BUCKET_NAME}",
            "arn:aws:s3:::${YOUR_OPENVPN_BUCKET_NAME}/*"
          ],
          "Condition": {
            "Bool": {
              "aws:SecureTransport": "false"
            }
          }
        },
        {
          "Effect": "Deny",
          "Principal": "*",
          "Action": "s3:*",
          "Resource": [
             "arn:aws:s3:::${YOUR_OPENVPN_BUCKET_NAME}",
             "arn:aws:s3:::${YOUR_OPENVPN_BUCKET_NAME}/*"
          ],
          "Condition": {
            "StringNotLike": {
              "aws:userId": [
                "$(aws --profile superuser iam get-role --role-name Terraform-Manage-Bootstrap | jq -r '.Role.RoleId'):*",
                "$(aws --profile superuser iam get-role --role-name Terraform-Manage-Servers | jq -r '.Role.RoleId'):*",
                "$(aws --profile superuser iam get-user --user-name Superuser | jq -r '.User.UserId')",
                "${YOUR_AWS_ACCOUNT_ID}"
              ]
            }
          }
        }
      ]
    }
    EOF

    export $(./assume-role.sh --profile=bootstrap-admin --account=${YOUR_AWS_ACCOUNT_ID} --role=Terraform-Manage-Bootstrap)
    aws s3api put-bucket-policy --bucket ${YOUR_OPENVPN_BUCKET_NAME} --policy file://policies/bucket-openvpn-deny-access.json
    aws s3api put-public-access-block --bucket ${YOUR_OPENVPN_BUCKET_NAME} --public-access-block-configuration "BlockPublicAcls=true,IgnorePublicAcls=true,BlockPublicPolicy=true,RestrictPublicBuckets=true"

Restrict access to Terraform bucket to increase security:

    cat <<EOF >policies/bucket-terraform-deny-access.json
    {
      "Version": "2012-10-17",
      "Statement": [
        {
          "Effect": "Deny",
          "Principal": "*",
          "Action": "s3:*",
          "Resource": [
            "arn:aws:s3:::${YOUR_TERRAFORM_BUCKET_NAME}",
            "arn:aws:s3:::${YOUR_TERRAFORM_BUCKET_NAME}/*"
          ],
          "Condition": {
            "Bool": {
              "aws:SecureTransport": "false"
            }
          }
        },
        {
          "Effect": "Deny",
          "Principal": "*",
          "Action": "s3:*",
          "Resource": [
             "arn:aws:s3:::${YOUR_TERRAFORM_BUCKET_NAME}",
             "arn:aws:s3:::${YOUR_TERRAFORM_BUCKET_NAME}/*"
          ],
          "Condition": {
            "StringNotLike": {
              "aws:userId": [
                "$(aws --profile superuser iam get-role --role-name Terraform-Manage-Bootstrap | jq -r '.Role.RoleId'):*",
                "$(aws --profile superuser iam get-role --role-name Terraform-Manage-Security | jq -r '.Role.RoleId'):*",
                "$(aws --profile superuser iam get-role --role-name Terraform-Manage-Networks | jq -r '.Role.RoleId'):*",
                "$(aws --profile superuser iam get-role --role-name Terraform-Manage-Servers | jq -r '.Role.RoleId'):*",
                "$(aws --profile superuser iam get-role --role-name Terraform-Manage-Clusters | jq -r '.Role.RoleId'):*",
                "$(aws --profile superuser iam get-user --user-name Superuser | jq -r '.User.UserId')",
                "${YOUR_AWS_ACCOUNT_ID}"
              ]
            }
          }
        }
      ]
    }
    EOF

    export $(./assume-role.sh --profile=bootstrap-admin --account=${YOUR_AWS_ACCOUNT_ID} --role=Terraform-Manage-Bootstrap)
    aws s3api put-bucket-policy --bucket ${YOUR_TERRAFORM_BUCKET_NAME} --policy file://policies/bucket-terraform-deny-access.json
    aws s3api put-public-access-block --bucket ${YOUR_TERRAFORM_BUCKET_NAME} --public-access-block-configuration "BlockPublicAcls=true,IgnorePublicAcls=true,BlockPublicPolicy=true,RestrictPublicBuckets=true"

See documentation for help:

- https://www.terraform.io/language
- https://terragrunt.gruntwork.io/docs/
- https://stedolan.github.io/jq/manual/v1.6/
- https://registry.terraform.io/providers/hashicorp/aws/latest/docs
- https://terragrunt.gruntwork.io/docs/getting-started/quick-start/
- https://awscli.amazonaws.com/v2/documentation/api/latest/reference/index.html
- https://docs.aws.amazon.com/IAM/latest/UserGuide/id_roles_create_for-user.html
- https://docs.aws.amazon.com/IAM/latest/UserGuide/id_roles_use_permissions-to-switch.html#roles-usingrole-createpolicy
- https://docs.aws.amazon.com/IAM/latest/UserGuide/id_credentials_passwords_account-policy.html
- https://aws.amazon.com/premiumsupport/knowledge-center/eks-iam-permissions-namespaces/
- https://aws.amazon.com/blogs/containers/de-mystifying-cluster-networking-for-amazon-eks-worker-nodes/
- https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html
- https://docs.aws.amazon.com/vpc/latest/userguide/vpc-policy-examples.html
- https://docs.aws.amazon.com/eks/latest/userguide/create-kubeconfig.html
- https://docs.aws.amazon.com/eks/latest/userguide/add-user-role.html
- https://docs.aws.amazon.com/eks/latest/userguide/dashboard-tutorial.html
- https://docs.aws.amazon.com/eks/latest/userguide/private-clusters.html
- https://docs.aws.amazon.com/eks/latest/userguide/autoscaling.html#cluster-autoscaler
- https://docs.aws.amazon.com/eks/latest/userguide/choosing-instance-type.html
- https://docs.aws.amazon.com/eks/latest/userguide/cni-iam-role.html
- https://docs.aws.amazon.com/eks/latest/userguide/update-stack.html
- https://docs.aws.amazon.com/eks/latest/userguide/create-node-role.html
- https://docs.aws.amazon.com/eks/latest/userguide/worker.html
- https://aws.github.io/aws-eks-best-practices/security/docs/iam/#restrict-access-to-the-instance-profile-assigned-to-the-worker-node
- https://cloud-images.ubuntu.com/aws-eks/amazon-eks-ubuntu-nodegroup.yaml
- https://github.com/awslabs/amazon-eks-ami/blob/master/amazon-eks-nodegroup.yaml
