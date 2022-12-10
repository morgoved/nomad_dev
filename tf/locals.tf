locals {
  NS = {
    ns_postgres = {
      name = "postgres"
      descr = "postgres namespace"
      quota = local.quota.pg.name
      meta = {
        owner = "xz"
        proj = "pg_dev"
      }
    }
  }

  quota = {
    pg = {
      name = "pg_limit"
      descr = "pg_limt"
      limits = [
        {
          region = "dc1"
          cpu = 4
          mem_mb = 2048
        }
     ]
   }
  }
}