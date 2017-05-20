output "fractals-api-deployment-v1-url" {
  value = "${aws_api_gateway_deployment.deployment_v1.invoke_url}"
}
