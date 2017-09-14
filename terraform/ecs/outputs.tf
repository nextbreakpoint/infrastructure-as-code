output "ecs-cluster-id" {
  value = "${aws_ecs_cluster.services.id}"
}

output "ecs-cluster-elb-name" {
  value = "${aws_elb.cluster_elb.name}"
}
