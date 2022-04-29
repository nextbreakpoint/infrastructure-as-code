##############################################################################
# Providers
##############################################################################

terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.0"
    }
  }
}

provider "aws" {
  region  = "${var.aws_region}"
}

##############################################################################
# Resources
##############################################################################

/*
resource "aws_security_group" "cluster" {
  name        = "${var.environment}-${var.colour}-cluster"
  description = "Worker security group"
  vpc_id      = "${data.terraform_remote_state.vpc.outputs.platform-vpc-id}"

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["${data.terraform_remote_state.vpc.outputs.platform-vpc-cidr}"]
  }

  ingress {
    from_port   = 53
    to_port     = 53
    protocol    = "tcp"
    cidr_blocks = ["${data.terraform_remote_state.vpc.outputs.platform-vpc-cidr}"]
  }

  ingress {
    from_port   = 53
    to_port     = 53
    protocol    = "udp"
    cidr_blocks = ["${data.terraform_remote_state.vpc.outputs.platform-vpc-cidr}"]
  }

  ingress {
    from_port   = 10250
    to_port     = 10250
    protocol    = "tcp"
    cidr_blocks = ["${data.terraform_remote_state.vpc.outputs.platform-vpc-cidr}"]
  }

  egress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 53
    to_port     = 53
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 53
    to_port     = 53
    protocol    = "udp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 1025
    to_port     = 65535
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Environment = "${var.environment}"
    Colour      = "${var.colour}"
  }
}
*/

resource "aws_security_group" "nodegroup_ssh" {
  name        = "${var.environment}-${var.colour}-nodegroup-ssh"
  description = "Nodegroup SSH security group"
  vpc_id      = "${data.terraform_remote_state.vpc.outputs.platform-vpc-id}"

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["${data.terraform_remote_state.vpc.outputs.platform-vpc-cidr}","${data.terraform_remote_state.vpc.outputs.openvpn-vpc-cidr}","${data.terraform_remote_state.vpc.outputs.bastion-vpc-cidr}"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = -1
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Environment = "${var.environment}"
    Colour      = "${var.colour}"
  }
}

resource "aws_iam_role" "cluster" {
  name = "${var.environment}-${var.colour}-cluster"

  assume_role_policy = jsonencode({
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "eks.amazonaws.com"
      }
    }]
    Version = "2012-10-17"
  })
}

resource "aws_iam_role_policy_attachment" "cluster_policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
  role       = aws_iam_role.cluster.name
}

resource "aws_iam_role_policy_attachment" "resource_controller_policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSVPCResourceController"
  role       = aws_iam_role.cluster.name
}

resource "aws_iam_role" "nodegroup" {
  name = "${var.environment}-${var.colour}-nodegroup"

  assume_role_policy = jsonencode({
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "ec2.amazonaws.com"
      }
    }]
    Version = "2012-10-17"
  })
}

resource "aws_iam_role_policy_attachment" "cni_policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
  role       = aws_iam_role.nodegroup.name
}

resource "aws_iam_role_policy_attachment" "worker_node_policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
  role       = aws_iam_role.nodegroup.name
}

resource "aws_iam_role_policy_attachment" "container_registry_policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
  role       = aws_iam_role.nodegroup.name
}

resource "aws_eks_cluster" "cluster" {
  name                      = "${var.environment}-${var.colour}-${var.cluster_name}"
  version                   = var.cluster_version

  role_arn                  = aws_iam_role.cluster.arn

  vpc_config {
    subnet_ids              = [
      data.terraform_remote_state.subnets.outputs.platform-public-subnet-a-id,
      data.terraform_remote_state.subnets.outputs.platform-public-subnet-b-id,
      data.terraform_remote_state.subnets.outputs.platform-public-subnet-c-id,
      data.terraform_remote_state.subnets.outputs.platform-private-subnet-a-id,
      data.terraform_remote_state.subnets.outputs.platform-private-subnet-b-id,
      data.terraform_remote_state.subnets.outputs.platform-private-subnet-c-id
    ]

    endpoint_private_access = true
    endpoint_public_access  = true
  }

  kubernetes_network_config {
    ip_family         = var.cluster_ip_family
    service_ipv4_cidr = var.cluster_service_ipv4_cidr
  }

  tags = {
    Environment = "${var.environment}"
    Colour      = "${var.colour}"
  }

  depends_on = [
    aws_iam_role.cluster,
    aws_iam_role_policy_attachment.cluster_policy,
    aws_iam_role_policy_attachment.resource_controller_policy
  ]
}

resource "aws_eks_node_group" "cluster" {
  node_group_name = "${var.environment}-${var.colour}-${var.cluster_name}"

  cluster_name    = aws_eks_cluster.cluster.name

  node_role_arn   = aws_iam_role.nodegroup.arn

  subnet_ids      = [
    data.terraform_remote_state.subnets.outputs.platform-private-subnet-a-id,
    data.terraform_remote_state.subnets.outputs.platform-private-subnet-b-id,
    data.terraform_remote_state.subnets.outputs.platform-private-subnet-c-id
  ]

  capacity_type = "ON_DEMAND"

  disk_size = 20

  instance_types = [
    "t3.medium"
  ]

  scaling_config {
    desired_size = 1
    max_size     = 2
    min_size     = 1
  }

  update_config {
    max_unavailable = 2
  }

  remote_access {
    ec2_ssh_key = "${var.environment}-${var.colour}-${var.key_name}"

    source_security_group_ids = [
      aws_security_group.nodegroup_ssh.id
    ]
  }

  tags = {
    Environment = "${var.environment}"
    Colour      = "${var.colour}"
  }

  depends_on = [
    aws_eks_cluster.cluster,
    aws_iam_role.nodegroup,
    aws_iam_role_policy_attachment.cni_policy,
    aws_iam_role_policy_attachment.worker_node_policy,
    aws_iam_role_policy_attachment.container_registry_policy
  ]
}
