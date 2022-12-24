resource "nomad_quota_specification" "quota" {
  for_each    = var.PARAMS
  name        = each.value.name
  description = each.value.descr

  dynamic "limits" {
    for_each = lookup(each.value, "limits", [])
    content {
      region = limits.value.region
      region_limit {
        cpu       = limits.value.cpu
        memory_mb = limits.value.mem_mb
      }
    }
  }
}
