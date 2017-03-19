output "jenkins-server-private-ip" {
  value = "${aws_instance.jenkins_server.private_ip}"
}

output "jenkins-server-public-ip" {
  value = "${aws_instance.jenkins_server.public_ip}"
}
