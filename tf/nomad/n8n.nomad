job "n8n" {
  datacenters = ["dc1"]
  namespace = "default"
  type = "service"
  group "n8n" {
    count = 1
    network {
      port  "web"{
        static = 5678
      }
    }
    volume "n8n" {
      type      = "host"
      source    = "n8n"
      read_only = false
    }
    task "n8n" {
      driver = "docker"
      volume_mount {
        volume      = "n8n"
        destination = "/home/node/.n8n"
        read_only   = false
      }
      constraint {
        attribute = "${meta.pg_host}"
        operator  = "="
        value     = "first_host"
      }
      config {
        image = "n8nio/n8n"
        command = "/bin/sh"
        args = ["-c", "n8n start --tunnel"]
        network_mode = "host"
        ports = [
          "web"
          ]
      }
      env {
        DB_TYPE = "postgresdb"
        DB_POSTGRESDB_HOST = "postgres.service.consul"
        DB_POSTGRESDB_PORT = 5432
        DB_POSTGRESDB_DATABASE = "n8n"
        DB_POSTGRESDB_USER = "n8n"
        DB_POSTGRESDB_PASSWORD = "n8npassword12345"
        N8N_BASIC_AUTH_ACTIVE = "true"
        N8N_BASIC_AUTH_USER = "test"
        N8N_BASIC_AUTH_PASSWORD = "testpwd"
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
        name = "n8n"
        provider = "consul"
        tags = [
          "traefik.enable=true",
          "traefik.http.routers.n8n.tls=true",
          "traefik.http.routers.n8n.rule=Host(`n8n.thstnm`)",
          "traefik.http.routers.n8n.tls.certresolver=main",
          "traefik.http.routers.n8n.tls.domains[0].main=n8n.hstnm"
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

