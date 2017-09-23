output "ecs-cluster-id" {
  value = "${aws_ecs_cluster.services.id}"
}
