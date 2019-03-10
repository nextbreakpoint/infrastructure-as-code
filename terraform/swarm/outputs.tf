##############################################################################
# Outputs
##############################################################################

output "swarm-manager-a-id" {
  value = "${aws_instance.swarm_manager_a.id}"
}

output "swarm-manager-b-id" {
  value = "${aws_instance.swarm_manager_b.id}"
}

output "swarm-manager-c-id" {
  value = "${aws_instance.swarm_manager_c.id}"
}

output "swarm-worker-int-a-id" {
  value = "${aws_instance.swarm_worker_int_a.id}"
}

output "swarm-worker-int-b-id" {
  value = "${aws_instance.swarm_worker_int_b.id}"
}

output "swarm-worker-int-c-id" {
  value = "${aws_instance.swarm_worker_int_c.id}"
}

output "swarm-worker-ext-a-id" {
  value = "${aws_instance.swarm_worker_ext_a.id}"
}

output "swarm-worker-ext-b-id" {
  value = "${aws_instance.swarm_worker_ext_b.id}"
}

output "swarm-worker-ext-c-id" {
  value = "${aws_instance.swarm_worker_ext_c.id}"
}

output "swarm-manager-a-private-ip" {
  value = "${aws_instance.swarm_manager_a.private_ip}"
}

output "swarm-manager-b-private-ip" {
  value = "${aws_instance.swarm_manager_b.private_ip}"
}

output "swarm-manager-c-private-ip" {
  value = "${aws_instance.swarm_manager_c.private_ip}"
}

output "swarm-worker-int-a-private-ip" {
  value = "${aws_instance.swarm_worker_int_a.private_ip}"
}

output "swarm-worker-int-b-private-ip" {
  value = "${aws_instance.swarm_worker_int_b.private_ip}"
}

output "swarm-worker-int-c-private-ip" {
  value = "${aws_instance.swarm_worker_int_c.private_ip}"
}

output "swarm-worker-ext-a-public-ip" {
  value = "${aws_instance.swarm_worker_ext_a.public_ip}"
}

output "swarm-worker-ext-b-public-ip" {
  value = "${aws_instance.swarm_worker_ext_b.public_ip}"
}

output "swarm-worker-ext-c-public-ip" {
  value = "${aws_instance.swarm_worker_ext_c.public_ip}"
}

output "swarm-worker-ext-a-private-ip" {
  value = "${aws_instance.swarm_worker_ext_a.private_ip}"
}

output "swarm-worker-ext-b-private-ip" {
  value = "${aws_instance.swarm_worker_ext_b.private_ip}"
}

output "swarm-worker-ext-c-private-ip" {
  value = "${aws_instance.swarm_worker_ext_c.private_ip}"
}
