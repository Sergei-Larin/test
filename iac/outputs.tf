output "data_aws_caller_identity" {
  value = data.aws_caller_identity.current.account_id
}

output "data_aws_region_name" {
  value = data.aws_region.current.name
}

output "data_aws_region_description" {
  value = data.aws_region.current.description
}

output "latest_aws_linux_id" {
  value = data.aws_ami.latest_aws_linux.id
}

output "jenkins_server_public_ip" {
  value = aws_instance.jenkins.public_ip
}

output "sonar_server_public_ip" {
  value = aws_instance.sonar.public_ip
}

output "rds_replica_connection_parameters" {
  description = "RDS replica instance connection parameters"
  value       = "-h ${aws_db_instance.default.address} -p ${aws_db_instance.default.port} -U ${aws_db_instance.default.username} ${var.db_name}"
}

# ---------------------------------------------------------------------------------------------------------------------
# ELASTIC KUBERNETES SERVICE
# ---------------------------------------------------------------------------------------------------------------------

output "cluster_id" {
  description = "EKS cluster ID."
  value       = data.aws_eks_cluster.cluster.id
}

output "cluster_endpoint" {
  description = "Endpoint for EKS control plane."
  value       = data.aws_eks_cluster.cluster.endpoint
}

output "region" {
  description = "AWS region"
  value       = var.default_aws_region
}

output "docker_registry" {
  description = "Registry for docker images"
  value       = aws_ecr_repository.ecr_registry.repository_url
}
