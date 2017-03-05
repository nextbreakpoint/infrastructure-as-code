output "elasticsearch-volume-a-id" {
  value = "${aws_ebs_volume.elasticsearch_volume_a.id}" 
}

output "elasticsearch-volume-b-id" {
  value = "${aws_ebs_volume.elasticsearch_volume_b.id}" 
}
