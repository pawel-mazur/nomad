variable "consul" {
  type = string
}

variable "email" {
  type = string
}

variable "cloudflare" {
  type = string
}

job "traefik" {

  type = "service"

  group "traefik" {
    count = 2

    network {
      port "api" {
        static = 8080
      }
      port "http" {
        static = 80
      }
      port "https" {
        static = 443
      }
      port "ping" {
        static = 591
      }
      port "psql" {
        static = 5432
      }
    }

    volume "traefik" {
      type   = "host"
      source = "traefik"
    }

    service {
      name = "traefik"

      check {
        name     = "alive"
        type     = "tcp"
        port     = "http"
        interval = "10s"
        timeout  = "2s"
      }
    }

    task "traefik" {
      driver = "docker"

      config {
        image        = "traefik:v3.0"
        network_mode = "host"

        volumes = [
          "local/traefik.yaml:/etc/traefik/traefik.yaml",
          "local/config:/etc/traefik/config",
        ]
      }

      env {
        CONSUL_HTTP_TOKEN = "${var.consul}"
        CF_API_EMAIL      = "${var.email}"
        CF_DNS_API_TOKEN  = "${var.cloudflare}"
      }

      volume_mount {
        volume      = "traefik"
        destination = "/var/lib/traefik"
      }

      template {
        data        = <<EOF
accessLog: {}
ping:
  entrypoint: public
api:
  dashboard: true
  insecure: true
  debug: true
providers:
  file:
    directory: /etc/traefik/config
    watch: true
  consulCatalog:
    prefix: traefik
    exposedByDefault: false
    endpoint:
      address: '127.0.0.1:8500'
      scheme: http
      token: '{{ env "CONSUL_HTTP_TOKEN" }}'

entryPoints:
  web:
    address: ':80'
    http:
      redirections:
        entryPoint:
          to: websecure
          scheme: https
  websecure:
    address: ':443'

  public:
    address: ':591'

  psql:

    address: ':5432'

  traefik:
    address: ':8080'

certificatesResolvers:
  http:
    acme:
      # ...
      email: {{ env "CF_API_EMAIL" }}
      storage: /var/lib/traefik/acme.json
      httpChallenge:
        entryPoint: websecure
  dns:
    acme:
      email: {{ env "CF_API_EMAIL" }}
      storage: /var/lib/traefik/acme.json
      dnsChallenge:
        provider: cloudflare
EOF
        destination = "local/traefik.yaml"
      }

      template {
        data        = <<EOF
tls:
  certificates:
    - certFile: /var/lib/traefik/tls/Homelab.crt
      keyFile: /var/lib/traefik/tls/Homelab.key
EOF
        destination = "local/config/tls.yaml"
      }

      resources {
        cpu        = 1000
        memory     = 128
        memory_max = 1000
      }
    }
  }
}

