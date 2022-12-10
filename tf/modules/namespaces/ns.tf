resource "nomad_namespace" "ns" {
  for_each    = var.PARAMS
  name        = each.value.name
  description = each.value.descr != "" ? each.value.descr : null
  quota       = each.value.quota != "" ? each.value.quota : null
  meta        = each.value.meta  != "" ? each.value.meta : null
}