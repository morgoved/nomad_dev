job "postgres" {
  datacenters = ["dc1"]
  namespace = "postgres"
  type = "service"
  group "postgres" {
    count = 1

    task "postgres" {
      driver = "docker"
      config {
        image = "postgres:15.1"
        network_mode = "host"
        port_map {
          db = 5432
        }

      }
      env {
          POSTGRES_USER="root",
          POSTGRES_PASSWORD="rootpassword"
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
          port  "db"  {
            static = 5432
          }
        }
      }
      service {
        name = "postgres"
        tags = ["postgres"]
        port = "db"

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

