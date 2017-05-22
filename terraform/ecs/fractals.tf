##############################################################################
# Provider
##############################################################################

provider "aws" {
  region = "${var.aws_region}"
  profile = "${var.aws_profile}"
  shared_credentials_file = "${var.aws_shared_credentials_file}"
}

##############################################################################
# Remote state
##############################################################################

data "terraform_remote_state" "vpc" {
    backend = "s3"
    config {
        bucket = "nextbreakpoint-terraform-state"
        region = "${var.aws_region}"
        key = "vpc.tfstate"
    }
}

data "terraform_remote_state" "network" {
    backend = "s3"
    config {
        bucket = "nextbreakpoint-terraform-state"
        region = "${var.aws_region}"
        key = "network.tfstate"
    }
}

##############################################################################
# ECS
##############################################################################

resource "aws_security_group" "cluster_server" {
  name = "cluster server"
  description = "cluster server security group"
  vpc_id = "${data.terraform_remote_state.vpc.network-vpc-id}"

  ingress {
    from_port = 22
    to_port = 22
    protocol = "tcp"
#    cidr_blocks = ["${var.aws_bastion_vpc_cidr}"]
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port = 8080
    to_port = 8080
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
#    cidr_blocks = ["${var.aws_network_vpc_cidr}"]
  }

  egress {
    from_port = 22
    to_port = 22
    protocol = "tcp"
    cidr_blocks = ["${var.aws_network_vpc_cidr}"]
  }

  egress {
    from_port = 80
    to_port = 80
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port = 443
    to_port = 443
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags {
    Name = "cluster server security group"
    Stream = "${var.stream_tag}"
  }
}

resource "aws_iam_instance_profile" "cluster_node_profile" {
    name = "cluster_node_profile"
    roles = ["${aws_iam_role.cluster_node_role.name}"]
}

resource "aws_iam_role" "cluster_node_role" {
  name = "cluster_node_role"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "ec2.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF
}

resource "aws_iam_role_policy" "cluster_node_role_policy" {
  name = "cluster_node_role_policy"
  role = "${aws_iam_role.cluster_node_role.id}"

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": [
        "ecs:DeregisterContainerInstance",
        "ecs:DiscoverPollEndpoint",
        "ecs:Poll",
        "ecs:RegisterContainerInstance",
        "ecs:StartTelemetrySession",
        "ecs:Submit*",
        "ecr:GetAuthorizationToken",
        "ecr:BatchCheckLayerAvailability",
        "ecr:GetDownloadUrlForLayer",
        "ecr:BatchGetImage",
        "logs:CreateLogStream",
        "logs:PutLogEvents"
      ],
      "Effect": "Allow",
      "Resource": "*"
    }
  ]
}
EOF
}

resource "aws_instance" "cluster_node_a" {
  depends_on = ["aws_ecs_cluster.fractals"]
  instance_type = "${var.aws_cluster_instance_type}"

  # Lookup the correct AMI based on the region we specified
  ami = "${lookup(var.cluster_amis, var.aws_region)}"

  subnet_id = "${data.terraform_remote_state.network.network-public-subnet-a-id}"
  associate_public_ip_address = "true"
  security_groups = ["${aws_security_group.cluster_server.id}"]
  key_name = "${var.key_name}"

  iam_instance_profile = "${aws_iam_instance_profile.cluster_node_profile.name}"

  connection {
    # The default username for our AMI
    user = "ec2-user"
    type = "ssh"
    # The path to your keyfile
    private_key = "${file(var.key_path)}"
    #bastion_user = "ec2-user"
    #bastion_host = "bastion.nextbreakpoint.com"
  }

  provisioner "remote-exec" {
    inline = "echo 'ECS_CLUSTER=fractals' > /tmp/ecs.config; sudo mv /tmp/ecs.config /etc/ecs/ecs.config"
  }

  tags {
    Name = "cluster_server_a"
    Stream = "${var.stream_tag}"
  }
}

resource "aws_instance" "cluster_node_b" {
  depends_on = ["aws_ecs_cluster.fractals"]
  instance_type = "${var.aws_cluster_instance_type}"

  # Lookup the correct AMI based on the region we specified
  ami = "${lookup(var.cluster_amis, var.aws_region)}"

  subnet_id = "${data.terraform_remote_state.network.network-public-subnet-b-id}"
  associate_public_ip_address = "true"
  security_groups = ["${aws_security_group.cluster_server.id}"]
  key_name = "${var.key_name}"

  iam_instance_profile = "${aws_iam_instance_profile.cluster_node_profile.name}"

  connection {
    # The default username for our AMI
    user = "ec2-user"
    type = "ssh"
    # The path to your keyfile
    private_key = "${file(var.key_path)}"
    #bastion_user = "ec2-user"
    #bastion_host = "bastion.nextbreakpoint.com"
  }

  provisioner "remote-exec" {
    inline = "echo 'ECS_CLUSTER=fractals' > /tmp/ecs.config; sudo mv /tmp/ecs.config /etc/ecs/ecs.config"
  }

  tags {
    Name = "cluster_server_b"
    Stream = "${var.stream_tag}"
  }
}

resource "aws_ecs_cluster" "fractals" {
  name = "fractals"
}

resource "aws_ecs_service" "fractals" {
  name            = "fractals"
  cluster         = "${aws_ecs_cluster.fractals.id}"
  task_definition = "${aws_ecs_task_definition.fractals.arn}"
  desired_count   = 4
  iam_role        = "${aws_iam_role.fractals_role.arn}"
  depends_on      = ["aws_iam_role_policy.fractals_role_policy"]

  placement_strategy {
    type  = "binpack"
    field = "cpu"
  }

  load_balancer {
    elb_name       = "${aws_elb.fractals.name}"
    container_name = "fractals-vertex-java-fat"
    container_port = 8080
  }

  placement_constraints {
    type       = "memberOf"
    expression = "attribute:ecs.availability-zone in [eu-west-1a, eu-west-1b]"
  }
}

resource "aws_ecs_task_definition" "fractals" {
  family                = "fractals"
  container_definitions = "${file("task-definitions/fractals.json")}"
  task_role_arn         = "${aws_iam_role.fractals_tasks_role.arn}"

  placement_constraints {
    type       = "memberOf"
    expression = "attribute:ecs.availability-zone in [eu-west-1a, eu-west-1b]"
  }
}

resource "aws_security_group" "fractals_elb" {
  name = "fractals elb"
  description = "ECS load balacer"
  vpc_id = "${data.terraform_remote_state.vpc.network-vpc-id}"

  ingress {
    from_port = 8080
    to_port = 8080
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port = 8080
    to_port = 8080
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags {
    Name = "ECS elb security group"
    stream = "${var.stream_tag}"
  }
}

resource "aws_elb" "fractals" {
  name               = "fractals-elb"
  security_groups = ["${aws_security_group.fractals_elb.id}"]
  subnets = ["${data.terraform_remote_state.network.network-public-subnet-a-id}","${data.terraform_remote_state.network.network-public-subnet-b-id}"]

  listener {
    instance_port     = 8080
    instance_protocol = "http"
    lb_port           = 8080
    lb_protocol       = "http"
  }

  health_check {
    healthy_threshold   = 2
    unhealthy_threshold = 2
    timeout             = 3
    target              = "HTTP:8080/fractals"
    interval            = 30
  }

  cross_zone_load_balancing   = true
  idle_timeout                = 400
  connection_draining         = true
  connection_draining_timeout = 400

  tags {
    Name = "fractals-elb"
  }
}

resource "aws_iam_role" "fractals_role" {
  name               = "Fractals"
  assume_role_policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "ecs.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
POLICY
}

resource "aws_iam_role_policy" "fractals_role_policy" {
  name = "FractalsPolicy"
  role = "${aws_iam_role.fractals_role.id}"

  policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "ec2:AuthorizeSecurityGroupIngress",
                "ec2:Describe*",
                "elasticloadbalancing:DeregisterInstancesFromLoadBalancer",
                "elasticloadbalancing:DeregisterTargets",
                "elasticloadbalancing:Describe*",
                "elasticloadbalancing:RegisterInstancesWithLoadBalancer",
                "elasticloadbalancing:RegisterTargets",
                "ecr:GetAuthorizationToken",
                "ecr:BatchCheckLayerAvailability",
                "ecr:GetDownloadUrlForLayer",
                "ecr:BatchGetImage"
            ],
            "Resource": "*"
        }
    ]
}
EOF
}

resource "aws_iam_role" "fractals_tasks_role" {
  name               = "FractalsTasks"
  assume_role_policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "ecs-tasks.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
POLICY
}

resource "aws_iam_role_policy" "fractals_tasks_role_policy" {
  name = "FractalsTasksPolicy"
  role = "${aws_iam_role.fractals_tasks_role.id}"

  policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "ecr:GetAuthorizationToken",
                "ecr:BatchCheckLayerAvailability",
                "ecr:GetDownloadUrlForLayer",
                "ecr:BatchGetImage"
            ],
            "Resource": "*"
        }
    ]
}
EOF
}
