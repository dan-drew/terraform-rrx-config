output "json" {
  value       = local.full_config_json
  description = "Computed rrx_config json"
}

output "environment" {
  value       = local.full_environment
  description = "App environment as a map"
}

output "container_environment" {
  value       = local.container_environment
  description = "App environment as a list of name/value maps"
}

output "aws_secret_arn" {
  value       = try(aws_secretsmanager_secret.config.0.arn, null)
  description = "ARN of created secret if aws_secret was provided"
}

output "role_policy" {
  value       = data.aws_iam_policy_document.role_policy
  description = "Policy containing required permissions"
}
