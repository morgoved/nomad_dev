domain=$1
apt update
apt install apt-transport-https ca-certificates curl software-properties-common -y
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu focal stable"
mkdir -p /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
  $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
apt-get update
apt-get install docker-ce docker-ce-cli containerd.io docker-compose-plugin -y


curl -fsSL https://apt.releases.hashicorp.com/gpg | sudo apt-key add -
sudo apt-add-repository "deb [arch=amd64] https://apt.releases.hashicorp.com $(lsb_release -cs) main"
apt update && apt install consul -y
apt update && apt install nomad -y

mkdir /data
mkdir /pg_data
mkdir /letsencrypt
mkdir /nocodb
mkdir /n8n
chmod 777 /data
chmod 777 /pg_data
chmod 600 /letsencrypt
chmod 777 /nocodb
chmod 777 /n8n

extip=$(dig @resolver4.opendns.com myip.opendns.com +short)
consulkey=$(consul keygen)
mv /etc/consul.d/consul.hcl /etc/consul.d/consul.hcl.bak
cat <<EOF > /etc/consul.d/consul.hcl
datacenter = "dc1"
data_dir = "/opt/consul"
client_addr = "0.0.0.0"
ui_config{
  enabled = true
}
server = true
addresses = {
  "http"  = "0.0.0.0"
  "https" = "0.0.0.0"
  "dns"   = "0.0.0.0"
  "grpc"  = "0.0.0.0"
}

ports = {
  dns               = 8600
  http              = 8500
  https             = 8501
  grpc              = 8502
}

dns_config   = {
  "node_ttl" = "5s"
  "service_ttl" = {
    "*" = "5s"
  }
  "max_stale" = "5s"
}

connect {
  enabled = true
}
bootstrap_expect=1
encrypt = "$consulkey"
retry_join = ["$extip"]
EOF

systemctl enable consul
systemctl start consul
sleep 30
nomadkey=$(nomad operator gossip keyring generate)
ifacename=$(ifconfig | grep $extip -B1 | grep mtu | sed -r 's/:.+//')
mv /etc/nomad.d/nomad.hcl /etc/nomad.d/nomad.hcl.bak
cat <<EOF > /etc/nomad.d/nomad.hcl
bind_addr = "0.0.0.0"
datacenter = "dc1"
data_dir = "/var/lib/nomad"
name = "dev_node"
disable_update_check = true
leave_on_interrupt = true
leave_on_terminate = true
log_file = "/var/log/nomad.log"
log_rotate_bytes = 10485760
log_rotate_max_files = 5

addresses {
  http = "$extip"
}

advertise {
  http = "{{ GetInterfaceIP \"$ifacename\" }}"
  rpc  = "{{ GetInterfaceIP \"$ifacename\" }}"
  serf = "{{ GetInterfaceIP \"$ifacename\" }}"
}

server {
  enabled = true
  bootstrap_expect = 1
  encrypt          = "$nomadkey"
  server_join {
    retry_join = ["$extip"]
    retry_max = 0
  }
}

consul {
  address             = "$extip:8500"
  server_service_name = "nomad"
  client_service_name = "nomad-client"
  auto_advertise      = true
  server_auto_join    = true
  client_auto_join    = true
}

client {
  enabled             = true
  no_host_uuid        = true
  min_dynamic_port    = 30000
  max_dynamic_port    = 35000
  alloc_dir           = "/opt/nomad/alloc"
  max_kill_timeout    = "60s"
  node_class          = "regular"
  reserved            = {
    cpu     = 200
    memory  = 200
    disk    = 1
  }
  options = {
    "env.denylist" = "MY_CUSTOM_ENVVAR"
    "driver.denylist" = "qemu,java,exec,raw_exec"
    "driver.allowlist" = "docker"
  }
  host_volume "persistent-storage" {
    path = "/data"
    read_only = false
  }

  host_volume "pg_data" {
    path = "/pg_data"
    read_only = false
  }

  host_volume "letsencrypt" {
    path = "/letsencrypt"
    read_only = false
  }

  host_volume "nocodb" {
    path = "/nocodb"
    read_only = false
  }

  host_volume "n8n" {
    path = "/n8n"
    read_only = false
  }

  meta {
    pg_host = "first_host"
    host    = "1"
  }
}

plugin "docker" {
  config {
    allow_caps = [
      "CHOWN", "DAC_OVERRIDE", "FSETID", "FOWNER", "MKNOD",
      "SETGID", "SETUID", "SETFCAP", "SETPCAP", "NET_BIND_SERVICE",
      "SYS_CHROOT", "KILL", "AUDIT_WRITE",
    ]
    volumes {
      enabled = true
    }
    gc {
      image = true
    }
  }
}


acl {
  enabled = true
}
EOF

systemctl enable nomad
systemctl start nomad

sleep 30

export NOMAD_ADDR=http://$extip:4646
nomad acl bootstrap > bootstrap
echo "-----------------------------------------------------nomad token located now  in this folder into bootstrap file--------------------------------------------------------------------"
cat ./bootstrap
nomadtoken=$(cat ./bootstrap | grep Secret | awk '{print $4}')


