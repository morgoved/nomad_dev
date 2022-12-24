job "traefik" {
  datacenters = [
    "dc1"]
  namespace = "default"
  type = "service"
  group "traefik" {
    count = 1
    network {
      port  "http"{
        static = 80
      }
      port  "https"{
        static = 443
      }
      port  "admin"{
        static = 8080
      }
    }

    volume "letsencrypt" {
      type = "host"
      source = "letsencrypt"
      read_only = false
    }

    task "server" {
      driver = "docker"
      constraint {
        attribute = "${meta.pg_host}"
        operator = "="
        value = "first_host"
      }

      volume_mount {
        volume = "letsencrypt"
        destination = "/letsencrypt"
        read_only = false
      }

      config {
        image = "traefik:v2.9.6"
        network_mode = "host"
        ports = [
          "admin",
          "http",
          "https"]
        args = [
          "--api.dashboard=true",
          "--api.insecure=true",
          ### For Test only, please do not use that in production

          "--entrypoints.web.address=:${NOMAD_PORT_http}",
          "--entrypoints.traefik.address=:${NOMAD_PORT_admin}",
          "--entryPoints.web-secure.address=:${NOMAD_PORT_https}",

          "--entrypoints.web.http.redirections.entryPoint.to=web-secure",
          "--entrypoints.web.http.redirections.entryPoint.scheme=https",

          "--experimental.http3=true",
          "--entrypoints.web-secure.http3.advertisedport=443",

          "--providers.nomad=false",
          "--providers.nomad.namespace=default",
          "--providers.nomad.endpoint.address=http://11111111111:4646",
          "--providers.nomad.endpoint.token=0000000000000",

          ### IP to your nomad server

          "--providers.consulCatalog.prefix=traefik",
          "--providers.consulCatalog.exposedByDefault=false",
          "--providers.consulCatalog.endpoint.address=http://11111111111:8500",

          "--certificatesresolvers.main.acme.httpchallenge=true",
          "--certificatesresolvers.main.acme.caserver=https://acme-v02.api.letsencrypt.org/directory",
          "--certificatesresolvers.main.acme.httpchallenge.entrypoint=web",
          "--certificatesresolvers.main.acme.email=xxxxx",
          "--certificatesresolvers.main.acme.storage=/letsencrypt/acme.json"
        ]
      }


      logs {
        max_files = 5
        max_file_size = 15
      }

      resources {
        cpu = 1000
        memory = 1024
      }

      service {
        name = "traefik-http"
        provider = "consul"
        port = "http"
        check {
          name     = "alive"
          type     = "tcp"
          interval = "10s"
          timeout  = "2s"
        }
      }

      service {
        name = "traefik-https"
        provider = "consul"
        port = "https"
        check {
          name     = "alive"
          type     = "tcp"
          interval = "10s"
          timeout  = "2s"
        }
      }

      service {
        name = "traefik-admin"
        provider = "consul"
        port = "admin"
        check {
          name     = "alive"
          type     = "tcp"
          interval = "10s"
          timeout  = "2s"
        }
      }
    }
    restart {
    attempts = 10
    interval = "5m"
    delay = "25s"
    mode = "delay"
  }
}
  update {
    max_parallel = 1
    min_healthy_time = "5s"
    healthy_deadline = "3m"
    auto_revert = false
    canary = 0
  }
}

