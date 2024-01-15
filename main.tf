locals {
  memcache_port = try(var.memcache.port, 11211)
  db_types = {
    mysql    = { adapter = "mysql2", port = 1 }
    postgres = { adapter = "postgres", port = 1 }
  }
  db_aliases = {
    sql        = "mysql"
    mariadb    = "mysql"
    postgresql = "postgres"
    psql       = "postgres"
  }
  db_type = var.db == null ? null : try(
    local.db_types[var.db.type],
    local.db_types[local.db_aliases[var.db.type]]
  )

  db_config = local.db_type == null ? {} : { database = merge(
    {
      adapter  = local.db_type.adapter
      host     = var.db.host
      port     = coalesce(var.db.port, local.db_type.port)
      database = var.db.name
      username = var.db.user
    },
    var.db.iam == true ? {} : {
      password = var.db.password
    }
  ) }

  cache_config = var.memcache == null ? {} : {
    cache = {
      server = "${var.memcache.server}:${coalesce(var.memcache.port, local.memcache_port)}"
    }
  }

  full_config = merge(
    db_config,
    cache_config,
    var.config
  )

  full_config_json = jsonencode(local.full_config)

  full_environment = {
    RRX_ENVIRONMENT = var.environment
    RRX_CONFIG      = local.full_config_json
    SECRET_KEY_BASE = var.secret_key_base
    AWS_REGION      = var.aws_region
  }

  container_environment = [
    for name, value in local.full_environment :
    { name = name, value = value }
  ]
}
