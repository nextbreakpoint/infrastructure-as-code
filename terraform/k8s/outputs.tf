##############################################################################
# Outputs
##############################################################################

output "cluster_name" {
  value       = var.cluster_name
}

output "cluster_id" {
  value       = aws_eks_cluster.cluster.id
}

output "cluster_endpoint" {
  value       = aws_eks_cluster.cluster.endpoint
}

output "kubectl_config" {
  value       = aws_eks_cluster.cluster.certificate_authority.0.data
}
