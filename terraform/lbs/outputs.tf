##############################################################################
# Outputs
##############################################################################

output "lb-internal-alb-dns-name" {
  value = "${aws_alb.lb_internal.dns_name}"
}

output "lb-public-alb-dns-name" {
  value = "${aws_alb.lb_public.dns_name}"
}

output "lb-internal-alb-zone-id" {
  value = "${aws_alb.lb_internal.zone_id}"
}

output "lb-public-alb-zone-id" {
  value = "${aws_alb.lb_public.zone_id}"
}

output "lb-internal-listener-http-arn" {
  value = "${aws_alb_listener.lb_internal_http.arn}"
}

output "lb-internal-listener-https-arn" {
  value = "${aws_alb_listener.lb_internal_https.arn}"
}

output "lb-public-listener-http-arn" {
  value = "${aws_alb_listener.lb_public_http.arn}"
}

output "lb-public-listener-https-arn" {
  value = "${aws_alb_listener.lb_public_https.arn}"
}

output "lb-internal-target-group-http-arn" {
  value = "${aws_alb_target_group.lb_internal_http.arn}"
}

output "lb-internal-target-group-https-arn" {
  value = "${aws_alb_target_group.lb_internal_http.arn}"
}

output "lb-public-target-group-http-arn" {
  value = "${aws_alb_target_group.lb_public_http.arn}"
}

output "lb-public-target-group-https-arn" {
  value = "${aws_alb_target_group.lb_public_http.arn}"
}
