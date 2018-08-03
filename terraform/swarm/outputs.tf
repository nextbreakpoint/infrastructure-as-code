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

output "swarm-worker-a-id" {
  value = "${aws_instance.swarm_worker_a.id}"
}

output "swarm-worker-b-id" {
  value = "${aws_instance.swarm_worker_b.id}"
}

output "swarm-worker-c-id" {
  value = "${aws_instance.swarm_worker_c.id}"
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

output "swarm-worker-a-private-ip" {
  value = "${aws_instance.swarm_worker_a.private_ip}"
}

output "swarm-worker-b-private-ip" {
  value = "${aws_instance.swarm_worker_b.private_ip}"
}

output "swarm-worker-c-private-ip" {
  value = "${aws_instance.swarm_worker_c.private_ip}"
}
