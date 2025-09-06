job "semaphore" {

  group "semaphore" {
    network {
      port "http" {
        to = "3000"
      }
    }

    service {
      port = "http"
      tags = [
        "traefik.enable=true",
        "traefik.http.routers.${NOMAD_JOB_NAME}-${NOMAD_TASK_NAME}.rule=HOST(`semaphore.lan`)",
        "traefik.http.routers.${NOMAD_JOB_NAME}-${NOMAD_TASK_NAME}.tls=true",
      ]
    }

    volume "semaphore" {
      type   = "host"
      source = "semaphore"
    }

    task "server" {
      driver = "docker"

      config {
        image = "semaphoreui/semaphore:v2.16.18"
        ports = ["http"]
      }

      env {
        SEMAPHORE_DB_DIALECT = "sqlite"
        SEMAPHORE_ADMIN      = "admin"
        SEMAPHORE_ADMIN_NAME = "Admin"
      }

      volume_mount {
        volume      = "semaphore"
        destination = "/var/lib/semaphore"
      }

      resources {
        memory = 256
      }
    }
  }
}
