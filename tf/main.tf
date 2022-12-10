module "quota" {
  source = "./modules/quota"
  PARAMS = local.quota
}

module "ns" {
  source = "./modules/namespaces"
  PARAMS = local.NS
  depends_on = [ module.quota ]
}