##############################################################################
# Provider
##############################################################################

provider "aws" {
  region = "${var.aws_region}"
  profile = "${var.aws_profile}"
  version = "~> 0.1"
}

provider "terraform" {
  version = "~> 0.1"
}

provider "template" {
  version = "~> 0.1"
}

##############################################################################
# Web servers
##############################################################################

resource "aws_security_group" "web_server" {
  name = "web-server-security-group"
  description = "NGINX server security group"
  vpc_id = "${data.terraform_remote_state.vpc.network-vpc-id}"

  ingress {
    from_port = 80
    to_port = 80
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port = 443
    to_port = 443
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port = 22
    to_port = 22
    protocol = "tcp"
    cidr_blocks = ["${var.aws_bastion_vpc_cidr}"]
  }

  egress {
    from_port = 0
    to_port = 0
    protocol = "-1"
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
    Stream = "${var.stream_tag}"
  }
}

data "template_file" "web_server_user_data_a" {
  template = "${file("provision/nginx.tpl")}"

  vars {
    aws_region              = "${var.aws_region}"
    environment             = "${var.environment}"
    bucker_name             = "${var.webserver_bucker_name}"
    security_groups         = "${aws_security_group.web_server.id}"
    consul_log_file         = "${var.consul_log_file}"
    log_group_name          = "${var.log_group_name}"
    log_stream_name         = "${var.log_stream_name}"
    hosted_zone_name        = "${var.hosted_zone_name}"
    public_hosted_zone_name = "${var.public_hosted_zone_name}"
    logstash_host           = "logstash.${var.hosted_zone_name}"
  }
}

data "template_file" "web_server_user_data_b" {
  template = "${file("provision/nginx.tpl")}"

  vars {
    aws_region              = "${var.aws_region}"
    environment             = "${var.environment}"
    bucker_name             = "${var.webserver_bucker_name}"
    security_groups         = "${aws_security_group.web_server.id}"
    consul_log_file         = "${var.consul_log_file}"
    log_group_name          = "${var.log_group_name}"
    log_stream_name         = "${var.log_stream_name}"
    hosted_zone_name        = "${var.hosted_zone_name}"
    public_hosted_zone_name = "${var.public_hosted_zone_name}"
    logstash_host           = "logstash.${var.hosted_zone_name}"
  }
}

resource "aws_iam_instance_profile" "web_server_profile" {
    name = "web-server-profile"
    role = "${aws_iam_role.web_server_role.name}"
}

resource "aws_iam_role" "web_server_role" {
  name = "web-server-role"

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
    },
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "s3.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF
}

resource "aws_iam_role_policy" "web_server_role_policy" {
  name = "web-server-role-policy"
  role = "${aws_iam_role.web_server_role.id}"

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
        "Action": [
            "s3:GetObject"
        ],
        "Effect": "Allow",
        "Resource": "arn:aws:s3:::${aws_s3_bucket.web_server.id}/*"
    }
  ]
}
EOF
}

data "aws_ami" "web_server" {
  most_recent = true

  filter {
    name = "name"
    values = ["nginx-${var.base_version}-*"]
  }

  filter {
    name = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["${var.account_id}"]
}

/*
resource "aws_instance" "web_server_a" {
  instance_type = "${var.web_instance_type}"

  ami = "${data.aws_ami.web_server.id}"

  subnet_id = "${data.terraform_remote_state.vpc.network-private-subnet-a-id}"
  associate_public_ip_address = "true"
  security_groups = ["${aws_security_group.web_server.id}"]
  key_name = "${var.key_name}"

  iam_instance_profile = "${aws_iam_instance_profile.web_server_profile.id}"

  tags {
    Name = "web-server-a"
    Stream = "${var.stream_tag}"
  }

  connection {
    host = "${element(aws_instance.web_server_a.*.private_ip, 0)}"
    # The default username for our AMI
    user = "ubuntu"
    type = "ssh"
    # The path to your keyfile
    private_key = "${file(var.key_path)}"
    bastion_user = "ec2-user"
    bastion_host = "bastion.${var.public_hosted_zone_name}"
  }

  provisioner "remote-exec" {
    inline = "${data.template_file.web_server_user_data_a.rendered}"
  }
}

resource "aws_instance" "web_server_b" {
  instance_type = "${var.web_instance_type}"

  ami = "${data.aws_ami.web_server.id}"

  subnet_id = "${data.terraform_remote_state.vpc.network-private-subnet-b-id}"
  associate_public_ip_address = "true"
  security_groups = ["${aws_security_group.web_server.id}"]
  key_name = "${var.key_name}"

  iam_instance_profile = "${aws_iam_instance_profile.web_server_profile.id}"

  tags {
    Name = "web-server-b"
    Stream = "${var.stream_tag}"
  }

  connection {
    host = "${element(aws_instance.web_server_b.*.private_ip, 0)}"
    # The default username for our AMI
    user = "ubuntu"
    type = "ssh"
    # The path to your keyfile
    private_key = "${file(var.key_path)}"
    bastion_user = "ec2-user"
    bastion_host = "bastion.${var.public_hosted_zone_name}"
  }

  provisioner "remote-exec" {
    inline = "${data.template_file.web_server_user_data_b.rendered}"
  }
}
*/

resource "aws_launch_configuration" "web_server_launch_configuration_a" {
  name_prefix   = "web-server-"
  instance_type = "${var.web_instance_type}"

  image_id = "${data.aws_ami.web_server.id}"

  associate_public_ip_address = "false"
  security_groups = ["${aws_security_group.web_server.id}"]
  key_name = "${var.key_name}"

  iam_instance_profile = "${aws_iam_instance_profile.web_server_profile.name}"

  user_data = "${data.template_file.web_server_user_data_a.rendered}"

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_launch_configuration" "web_server_launch_configuration_b" {
  name_prefix   = "web-server-"
  instance_type = "${var.web_instance_type}"

  image_id = "${data.aws_ami.web_server.id}"

  associate_public_ip_address = "false"
  security_groups = ["${aws_security_group.web_server.id}"]
  key_name = "${var.key_name}"

  iam_instance_profile = "${aws_iam_instance_profile.web_server_profile.name}"

  user_data = "${data.template_file.web_server_user_data_b.rendered}"

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_autoscaling_group" "web_server_asg_a" {
  name                      = "web-server-asg-a"
  max_size                  = 4
  min_size                  = 0
  health_check_grace_period = 300
  health_check_type         = "ELB"
  desired_capacity          = 1
  force_delete              = true
  launch_configuration      = "${aws_launch_configuration.web_server_launch_configuration_a.name}"

  vpc_zone_identifier = [
    "${data.terraform_remote_state.vpc.network-private-subnet-a-id}"
  ]

  lifecycle {
    create_before_destroy = true
  }

  tag {
    key                 = "stream"
    value               = "${var.stream_tag}"
    propagate_at_launch = true
  }

  tag {
    key                 = "Name"
    value               = "web-server-a"
    propagate_at_launch = true
  }

  timeouts {
    delete = "15m"
  }
}

resource "aws_autoscaling_group" "web_server_asg_b" {
  name                      = "web-server-asg-b"
  max_size                  = 4
  min_size                  = 0
  health_check_grace_period = 300
  health_check_type         = "ELB"
  desired_capacity          = 1
  force_delete              = true
  launch_configuration      = "${aws_launch_configuration.web_server_launch_configuration_b.name}"

  vpc_zone_identifier = [
    "${data.terraform_remote_state.vpc.network-private-subnet-b-id}"
  ]

  lifecycle {
    create_before_destroy = true
  }

  tag {
    key                 = "stream"
    value               = "${var.stream_tag}"
    propagate_at_launch = true
  }

  tag {
    key                 = "Name"
    value               = "web-server-b"
    propagate_at_launch = true
  }

  timeouts {
    delete = "15m"
  }
}

resource "aws_security_group" "web_elb" {
  name = "web-server-elb-security-group"
  description = "NGINX load balacer security group"
  vpc_id = "${data.terraform_remote_state.vpc.network-vpc-id}"

  ingress {
    from_port = 80
    to_port = 80
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port = 443
    to_port = 443
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
    stream = "${var.stream_tag}"
  }
}

resource "aws_iam_server_certificate" "web_elb" {
  name_prefix      = "web-server-elb-certificate"
  certificate_body = "${file("${var.web_server_elb_certificate_path}")}"
  private_key      = "${file("${var.web_server_elb_private_key_path}")}"

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_elb" "web_elb" {
  name = "web-elb"
  security_groups = ["${aws_security_group.web_elb.id}"]
  subnets = ["${data.terraform_remote_state.vpc.network-public-subnet-a-id}","${data.terraform_remote_state.vpc.network-public-subnet-b-id}"]

  listener {
    instance_port = 80
    instance_protocol = "HTTP"
    lb_port = 80
    lb_protocol = "HTTP"
  }

  listener {
    instance_port       = 443
    instance_protocol   = "HTTPS"
    lb_port             = 443
    lb_protocol         = "HTTPS"
    ssl_certificate_id  = "${aws_iam_server_certificate.web_elb.arn}"
  }

  health_check {
    healthy_threshold = 2
    unhealthy_threshold = 3
    timeout = 10
    target = "TCP:80"
    interval = 30
  }

  cross_zone_load_balancing = true
  idle_timeout = 400
  connection_draining = true
  connection_draining_timeout = 400
  internal = false

  tags {
    stream = "${var.stream_tag}"
  }
}

resource "aws_autoscaling_attachment" "web_server_asg_a" {
  autoscaling_group_name = "${aws_autoscaling_group.web_server_asg_a.id}"
  elb = "${aws_elb.web_elb.id}"
}

resource "aws_autoscaling_attachment" "web_server_asg_b" {
  autoscaling_group_name = "${aws_autoscaling_group.web_server_asg_b.id}"
  elb = "${aws_elb.web_elb.id}"
}

##############################################################################
# Route 53
##############################################################################

resource "aws_route53_record" "web_server_elb" {
  zone_id = "${var.public_hosted_zone_id}"
  name = "nginx.${var.public_hosted_zone_name}"
  type = "A"

  alias {
    name = "${aws_elb.web_elb.dns_name}"
    zone_id = "${aws_elb.web_elb.zone_id}"
    evaluate_target_health = true
  }
}

resource "aws_route53_record" "web_server_dns" {
  zone_id = "${data.terraform_remote_state.vpc.hosted-zone-id}"
  name = "nginx.${var.hosted_zone_name}"
  type = "CNAME"
  ttl = "30"

  records = ["${aws_elb.web_elb.dns_name}"]
}

##############################################################################
# S3 Bucket
##############################################################################

resource "aws_s3_bucket" "web_server" {
  bucket = "${var.webserver_bucker_name}"
  region = "${var.aws_region}"
  versioning = {
    enabled = true
  }
  acl = "private"
  force_destroy  = true

  tags {
    stream = "${var.stream_tag}"
  }
}

resource "aws_s3_bucket_object" "nginx-certificate" {
  bucket = "${aws_s3_bucket.web_server.id}"
  key    = "environments/production/nginx/nginx.crt"
  source = "environments/production/nginx/nginx.crt"
  etag   = "${md5(file("environments/production/nginx/nginx.crt"))}"
}

resource "aws_s3_bucket_object" "nginx-private-key" {
  bucket = "${aws_s3_bucket.web_server.id}"
  key    = "environments/production/nginx/nginx.key"
  source = "environments/production/nginx/nginx.key"
  etag   = "${md5(file("environments/production/nginx/nginx.key"))}"
}
