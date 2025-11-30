variable "domain" {
  type = string
}

variable "resolver" {
  type = string
}

job "httpd" {

  type = "service"

  group "httpd" {

    network {
      port "http" {
        to = 80
      }
    }

    count = 2

    update {
      max_parallel = 1
      canary       = 1
      auto_revert  = true
      auto_promote = true
    }

    task "httpd" {

      driver = "docker"

      config {
        image = "httpd"
        ports = ["http"]
        volumes = [
          "local/htdocs:/usr/local/apache2/htdocs",
        ]
      }

      template {
        data = <<EOH
<p><strong>It's Works!</strong></p>
<p>Allocation: {{ env "NOMAD_ALLOC_ID" }}</p>
<p>Short: {{ env "NOMAD_SHORT_ALLOC_ID" }}</p>
<p>Index: {{ env "NOMAD_ALLOC_INDEX" }}</p>
<p>Server: {{ env "NOMAD_IP_http" }}</p>
<p>Version: 11</p>
 EOH
        destination = "local/htdocs/index.html"
      }

      template {
        data = <<EOH
{"status": "OK"}
 EOH
        destination = "local/htdocs/status"
      }

      service {
        port = "http"
        tags = [
          "traefik.enable=true",

          "traefik.http.routers.${NOMAD_JOB_NAME}-${NOMAD_TASK_NAME}.rule=Host(`${var.domain}`)",
          "traefik.http.routers.${NOMAD_JOB_NAME}-${NOMAD_TASK_NAME}.tls.certresolver=${var.resolver}",
          "traefik.http.routers.${NOMAD_JOB_NAME}-${NOMAD_TASK_NAME}.entryPoints=websecure",

          "traefik.http.routers.${NOMAD_JOB_NAME}-status.rule=Host(`${var.domain}`) && Path(`/status`)",
          "traefik.http.routers.${NOMAD_JOB_NAME}-status.tls.certresolver=${var.resolver}",
          "traefik.http.routers.${NOMAD_JOB_NAME}-status.entryPoints=public",
        ]

        check {
          type     = "http"
          name     = "status"
          path     = "/status?_healthz"
          interval = "20s"
          timeout  = "5s"
        }
      }

      resources {
        memory = 100
      }
    }

    shutdown_delay = "15s"
  }
}
