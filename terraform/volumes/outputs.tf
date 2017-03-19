output "elasticsearch-volume-a-id" {
  value = "${aws_ebs_volume.elasticsearch_volume_a.id}" 
}

output "elasticsearch-volume-b-id" {
  value = "${aws_ebs_volume.elasticsearch_volume_b.id}" 
}

output "pipeline-volume-a-id" {
  value = "${aws_ebs_volume.pipeline_volume_a.id}" 
}
