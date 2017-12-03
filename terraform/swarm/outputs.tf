output "swarm-master-a-private-ip" {
  value = "${aws_instance.sawrm_master_a.private_ip}"
}

output "swarm-worker1-a-private-ip" {
  value = "${aws_instance.sawrm_worker1_a.private_ip}"
}

output "swarm-worker2-a-private-ip" {
  value = "${aws_instance.sawrm_worker2_a.private_ip}"
}

output "swarm-master-b-private-ip" {
  value = "${aws_instance.sawrm_master_b.private_ip}"
}

output "swarm-worker1-b-private-ip" {
  value = "${aws_instance.sawrm_worker1_b.private_ip}"
}

output "swarm-worker2-b-private-ip" {
  value = "${aws_instance.sawrm_worker2_b.private_ip}"
}
