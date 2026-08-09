output "application_url" {
  description = "Public URL of the deployed full-stack application"
  value       = "http://${aws_lb.main.dns_name}"
}

output "load_balancer_dns_name" {
  description = "DNS name of the Application Load Balancer"
  value       = aws_lb.main.dns_name
}

output "frontend_ecr_repository_url" {
  description = "ECR repository URL for the frontend Docker image"
  value       = aws_ecr_repository.frontend.repository_url
}

output "backend_ecr_repository_url" {
  description = "ECR repository URL for the backend Docker image"
  value       = aws_ecr_repository.backend.repository_url
}

output "ecs_cluster_name" {
  description = "Name of the ECS cluster"
  value       = aws_ecs_cluster.main.name
}

output "frontend_ecs_service_name" {
  description = "Name of the frontend ECS service"
  value       = aws_ecs_service.frontend.name
}

output "backend_ecs_service_name" {
  description = "Name of the backend ECS service"
  value       = aws_ecs_service.backend.name
}

output "frontend_task_definition_family" {
  description = "Frontend ECS task definition family"
  value       = aws_ecs_task_definition.frontend.family
}

output "backend_task_definition_family" {
  description = "Backend ECS task definition family"
  value       = aws_ecs_task_definition.backend.family
}

output "cloudwatch_dashboard_name" {
  description = "Name of the CloudWatch monitoring dashboard"
  value       = aws_cloudwatch_dashboard.main.dashboard_name
}

output "sns_topic_arn" {
  description = "SNS topic used for CloudWatch alarm notifications"
  value       = aws_sns_topic.alerts.arn
}

output "jenkins_instance_profile_name" {
  description = "IAM instance profile to attach to the Jenkins EC2 instance"
  value       = aws_iam_instance_profile.jenkins.name
}
output "jenkins_public_ip" {
  description = "Public IPv4 address of the Jenkins server"
  value       = aws_instance.jenkins.public_ip
}

output "jenkins_url" {
  description = "URL for the Jenkins web interface"
  value       = "http://${aws_instance.jenkins.public_ip}:8080"
}