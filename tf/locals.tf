locals {
  NS = {
    ns_postgres = {
      name = "postgres"
      descr = "postgres namespace"
      quota = ""
      meta = {
        owner = "xz"
        proj = "pg_dev"
      }
    }
  }
  quota = {}
/*
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
*/
}