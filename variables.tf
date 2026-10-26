variable "docker_host" {
  description = "Address of the Docker daemon (Linux socket). On Windows Docker Desktop use npipe:////./pipe/docker_engine"
  type        = string
  default     = "unix:///var/run/docker.sock"
}

variable "image_name" {
  description = "Docker image that is pulled and run"
  type        = string
  default     = "nginx:alpine"
}

variable "container_name" {
  description = "Name of the Docker container"
  type        = string
  default     = "terraform-nginx"
}

variable "external_port" {
  description = "Port on the host machine that is mapped to port 80 of the container"
  type        = number
  default     = 8080

  validation {
    condition     = var.external_port >= 1024 && var.external_port <= 65535
    error_message = "external_port must be between 1024 and 65535."
  }
}

variable "environment" {
  description = "Environment name (dev, staging or prod)"
  type        = string
  default     = "dev"

  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "environment must be one of: dev, staging, prod."
  }
}

variable "memory_mb" {
  description = "Memory limit of the container in MB"
  type        = number
  default     = 128
}

variable "app_secret" {
  description = "Example secret passed to the container. The default is a dummy value for this demo only - set a real secret with TF_VAR_app_secret or a git-ignored terraform.tfvars file."
  type        = string
  sensitive   = true
  default     = "demo-only-not-a-real-secret"
}
