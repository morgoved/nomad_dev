module "quota" {
  source = "./modules/quota"
  PARAMS = local.quota
}

module "ns" {
  source = "./modules/namespaces"
  PARAMS = local.NS
  depends_on = [ module.quota ]
}

resource "nomad_job" "app" {
  jobspec = file("../postgres.nomad")
  depends_on = [ module.ns ]
}
