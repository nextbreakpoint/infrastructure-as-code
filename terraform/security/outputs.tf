output "terraform-manage-networks-arn" {
  value = "${aws_iam_role.terraform-manage-networks.arn}"
}

output "terraform-manage-servers-arn" {
  value = "${aws_iam_role.terraform-manage-servers.arn}"
}

output "terraform-manage-clusters-arn" {
  value = "${aws_iam_role.terraform-manage-clusters.arn}"
}

output "packer-build-images-arn" {
  value = "${aws_iam_role.packer-build-images.arn}"
}

output "terraform-manage-networks-id" {
  value = "${aws_iam_role.terraform-manage-networks.id}"
}

output "terraform-manage-servers-id" {
  value = "${aws_iam_role.terraform-manage-servers.id}"
}

output "terraform-manage-clusters-id" {
  value = "${aws_iam_role.terraform-manage-clusters.id}"
}

output "packer-build-images-id" {
  value = "${aws_iam_role.packer-build-images.id}"
}
