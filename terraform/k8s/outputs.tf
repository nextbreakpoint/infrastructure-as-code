output "cluster_name" {
  value       = var.cluster_name
}

output "cluster_id" {
  value       = aws_eks_cluster.cluster.id
}

output "cluster_endpoint" {
  value       = aws_eks_cluster.cluster.endpoint
}
