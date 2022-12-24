job "nocodb" {
  datacenters = ["dc1"]
  namespace = "default"
  type = "service"
  group "nocodb" {
    count = 1
    network {
      port  "web"{
        static       = 8181
      }
    }
    volume "nocodb" {
      type      = "host"
      source    = "nocodb"
      read_only = false
    }
    task "nocodb" {
      driver = "docker"
      volume_mount {
        volume      = "nocodb"
        destination = "/usr/app/data"
        read_only   = false
      }
      constraint {
        attribute = "${meta.pg_host}"
        operator  = "="
        value     = "first_host"
      }
      config {
        image = "nocodb/nocodb:latest"
        network_mode = "host"
        ports = [
          "web"
          ]
      }
      env {
          NC_DB = "pg://postgres.service.consul:5432?u=nocodb&p=nocodbpassword12345&d=nocodb"
          PORT  = "8181"
      }

      logs {
        max_files     = 5
        max_file_size = 15
      }

      resources {
        cpu = 1000
        memory = 1024
        network {
          mbits = 10
        }
      }

      service {
        name = "nocodb"
        provider = "consul"
        tags = [
          "traefik.enable=true",
          "traefik.http.routers.nocodb.tls=true",
          "traefik.http.routers.nocodb.rule=Host(`nocodb.thstnm`)",
          "traefik.http.routers.nocodb.tls.certresolver=main",
          "traefik.http.routers.nocodb.tls.domains[0].main=nocodb.thstnm"
        ]
        port = "web"
        check {
          name = "alive"
          type = "tcp"
          interval = "10s"
          timeout = "2s"
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

