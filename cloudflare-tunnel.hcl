variable "token" {
  type = string
}

job "cloudflare-tunel" {
  datacenters = ["dc1"]

  task "server" {
    driver = "docker"

    config {
      image = "cloudflare/cloudflared"
      command = "tunnel"
      args  = [
        "--no-autoupdate",
        "run",
      ]
    }

    env {
      TUNNEL_TOKEN = "${var.token}"
    }
  }
}
