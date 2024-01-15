output "json" {
  value = local.full_config_json
  description = "Computed rrx_config json"
}

output "environment" {
  value = local.full_environment
  description = "App environment as a map"
}

output "container_environment" {
  value = local.container_environment
  description = "App environment as a list of name/value maps"
}
