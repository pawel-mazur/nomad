variable "domain" {
  type = string
}

variable "encryption_key" {
  type = string
}

job "n8n" {
  type = "service"

  group "n8n" {
    network {
      port "http" {
        to = 5678
      }
    }

    volume "n8n" {
      type   = "host"
      source = "n8n"
    }

    service {
      port = "http"
      tags = [
        "traefik.enable=true",
        "traefik.http.routers.${NOMAD_JOB_NAME}.rule=Host(`${var.domain}`)",
        "traefik.http.routers.${NOMAD_JOB_NAME}.tls=true",
        "traefik.http.routers.${NOMAD_JOB_NAME}.entryPoints=websecure",
      ]

      check {
        type     = "http"
        name     = "healthz"
        path     = "/healthz"
        interval = "20s"
        timeout  = "5s"
      }
    }

    task "server" {
      driver = "docker"

      config {
        image = "docker.n8n.io/n8nio/n8n:latest"
        ports = ["http"]
      }

      env {
        GENERIC_TIMEZONE   = "Europe/Warsaw"
        N8N_ENCRYPTION_KEY = "${var.encryption_key}"
        N8N_WEBHOOK_URL    = "https://${var.domain}/"
        N8N_HOST           = "${var.domain}"
        N8N_PORT           = "5678"
        N8N_PROTOCOL       = "https"
        N8N_PROXY_HOPS     = "1"
        NODE_ENV           = "production"
        TZ                 = "Europe/Warsaw"
      }

      volume_mount {
        volume      = "n8n"
        destination = "/home/node/.n8n"
      }

      resources {
        cpu    = 500
        memory = 1024
      }
    }

    shutdown_delay = "15s"
  }
}
