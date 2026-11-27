resource "local_file" "service_env" {
  filename             = "${path.module}/../generated/service.env"
  directory_permission = "0700"
  file_permission      = "0600"
  content              = <<-EOT
    APP_NAME=${var.app_name}
    APP_ENV=${var.app_env}
    LOG_LEVEL=${var.log_level}
    PORT=${var.port}
    FAIL_MODE=${var.fail_mode}
  EOT
}

output "service_env_path" {
  description = "Path to the generated application environment file."
  value       = local_file.service_env.filename
}
