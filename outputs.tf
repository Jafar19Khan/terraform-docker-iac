output "container_name" {
  description = "Name of the running container"
  value       = docker_container.web.name
}

output "container_id" {
  description = "ID of the container"
  value       = docker_container.web.id
}

output "image_id" {
  description = "ID of the pulled image"
  value       = docker_image.nginx.image_id
}

output "web_url" {
  description = "URL of the web page served by the container"
  value       = "http://localhost:${var.external_port}"
}

# Sensitive outputs are hidden in the CLI: Terraform prints <sensitive>
output "app_secret" {
  description = "Secret passed to the container (hidden)"
  value       = var.app_secret
  sensitive   = true
}
