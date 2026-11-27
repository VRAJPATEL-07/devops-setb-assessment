variable "app_name" {
  description = "Application name written to the generated service environment."
  type        = string
}

variable "app_env" {
  description = "Application environment."
  type        = string
}

variable "log_level" {
  description = "Application log level."
  type        = string
}

variable "port" {
  description = "Port on which the application listens."
  type        = number

  validation {
    condition     = var.port >= 1024 && var.port <= 65535
    error_message = "The port must be between 1024 and 65535."
  }
}

variable "fail_mode" {
  description = "Readiness failure mode (0 = healthy, 1 = failing)."
  type        = number

  validation {
    condition     = var.fail_mode == 0 || var.fail_mode == 1
    error_message = "The fail_mode must be 0 (healthy) or 1 (failing)."
  }
}
