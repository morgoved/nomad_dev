module "quota" {
  source = "./modules/quota"
  PARAMS = local.quota
}

module "ns" {
  source = "./modules/namespaces"
  PARAMS = local.NS
  depends_on = [ module.quota ]
}

resource "nomad_job" "postgres" {
  jobspec = file("./nomad/postgres.nomad")
  depends_on = [ module.ns ]
}

resource "nomad_job" "traefik" {
  jobspec = file("./nomad/traefik.nomad")
  depends_on = [ module.ns ]
}
/*
resource "nomad_job" "nocodb" {
  jobspec = file("./nomad/nocodb.nomad")
  depends_on = [ module.ns, nomad_job.postgres, nomad_job.traefik ]
}

resource "nomad_job" "n8n" {
  jobspec = file("./nomad/n8n.nomad")
  depends_on = [ module.ns, nomad_job.postgres, nomad_job.traefik ]
}
*/