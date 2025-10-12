variable "domain" {
  type = string
}

variable "resolver" {
  type = string
}

job "dotnet" {

  type = "service"

  group "httpd" {

    network {
      port "http" {
        to = 8080
      }
    }

    task "httpd" {

      driver = "docker"

      config {
        image = "pakumaz/aspnet-core-app"
        entrypoint = ["dotnet"]
        command = "app.dll"
        ports = ["http"]
      }

      service {
        port = "http"
        tags = [
          "traefik.enable=true",
          "traefik.http.routers.${NOMAD_JOB_NAME}-${NOMAD_TASK_NAME}.rule=Host(`${var.domain}`)",
          "traefik.http.routers.${NOMAD_JOB_NAME}-${NOMAD_TASK_NAME}.tls.certresolver=${var.resolver}",
          "traefik.http.routers.${NOMAD_JOB_NAME}-${NOMAD_TASK_NAME}.entryPoints=https",
        ]
      }
    }

    shutdown_delay = "15s"
  }
}
