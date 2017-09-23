output "ecs-cluster-id" {
  value = "${aws_ecs_cluster.services.id}"
}

output "ecs-cluster-bucket-name" {
  value = "${aws_s3_bucket.services.id}"
}

output "ecs-cluster-bucket-domain-name" {
  value = "${aws_s3_bucket.services.bucket_domain_name}"
}
