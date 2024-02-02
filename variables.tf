variable "environment" {
  type        = string
  description = "Name of the deployment environment"
  validation {
    condition     = contains(["development", "staging", "production"], var.environment)
    error_message = "Environment must be development, staging or production"
  }
}

variable "db" {
  type = object({
    resource_id = string
    type        = string
    host        = string
    port        = optional(number)
    name        = string
    user        = string
    password    = optional(string)
    iam         = optional(bool)
  })
  default     = null
  description = "Database config with: name, host, port, user and password items"
  validation {
    condition     = var.db == null || (var.db.iam && var.db.password == null) || var.db.password != null
    error_message = "One of password or iam must be set"
  }
}

variable "config" {
  type        = any
  default     = {}
  description = "Optional arbitrary app config"
  validation {
    condition     = startswith(jsonencode(var.config), "{")
    error_message = "Must be an object value"
  }
}

variable "aws_region" {
  type        = string
  default     = "us-west-2"
  description = "Region to use for AWS access"
}

variable "memcache" {
  type = object({
    server = string
    port   = optional(number)
  })
  default     = null
  description = "Memcache server"
}

variable "aws_secret" {
  type        = string
  default     = null
  description = "Create an AWS secret to store the config"
}
