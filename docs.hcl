variable "domain-lan" {
  type = string
}

variable "domain-wan" {
  type = string
}

job "docs" {
  datacenters = ["dc1"]

  group "example" {
    network {
      port "http" {
        to = "5678"
      }
    }

    task "server" {
      driver = "docker"

      config {
        image = "hashicorp/http-echo"
        ports = ["http"]
        args  = [
          "-listen",
          ":5678",
          "-text",
          "hello world",
        ]
      }

      service {
        port = "http"
        tags = [
          "traefik.enable=true",
          "traefik.http.routers.${NOMAD_JOB_NAME}-${NOMAD_TASK_NAME}-lan.rule=HOST(`${var.domain-lan}`)",
          "traefik.http.routers.${NOMAD_JOB_NAME}-${NOMAD_TASK_NAME}-lan.tls=true",

          "traefik.http.routers.${NOMAD_JOB_NAME}-${NOMAD_TASK_NAME}-wan.rule=HOST(`${var.domain-wan}`)",
          "traefik.http.routers.${NOMAD_JOB_NAME}-${NOMAD_TASK_NAME}-wan.tls.certResolver=dns",
          "traefik.http.routers.${NOMAD_JOB_NAME}-${NOMAD_TASK_NAME}-wan.tls=true",
        ]
      }
    }
  }
}
