output "terraform-manage-security-arn" {
  value = "${aws_iam_role.terraform-manage-security.arn}"
}

output "terraform-manage-security-id" {
  value = "${aws_iam_role.terraform-manage-security.id}"
}
