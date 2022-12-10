provider "nomad" {
  alias = "cluster-mcs"
  address    = local.K8S_0.consul_cli_host
  #insecure_https = true
  scheme = "https"
  ca_pem = data.kubernetes_secret.consul-ca.data["ca.crt"]
  datacenter = local.K8S_0.consul_datacenter
  #http_auth = "f41bd239-35b9-cc19-46fb-bc881feb6ae6"
  http_auth = data.kubernetes_secret.consul-consul-bootstrap-acl-token.data.token
}
