resource "random_bytes" "secret_key_base" {
  length = 32
}

locals {
  aws_secret_count = var.aws_secret == null ? 0 : 1
  memcache_port    = try(var.memcache.port, 11211)

  db_types = {
    mysql    = { adapter = "mysql2", port = 3306 }
    postgres = { adapter = "postgres", port = 5432 }
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
    var.db.iam == true ? { iam = true } : { password = var.db.password }
  ) }

  cache_config = var.memcache == null ? {} : {
    cache = {
      server = "${var.memcache.server}:${coalesce(var.memcache.port, local.memcache_port)}"
    }
  }

  full_config = merge(
    local.db_config,
    local.cache_config,
    var.config
  )

  full_config_json = jsonencode(local.full_config)

  full_environment = merge(
    {
      RAILS_ENV       = "production"
      RRX_ENVIRONMENT = var.environment
      SECRET_KEY_BASE = random_bytes.secret_key_base.hex
      AWS_REGION      = var.aws_region
    },
    var.aws_secret != null ? {
      RRX_CONFIG_AWS_SECRET = var.aws_secret
      } : {
      RRX_CONFIG = local.full_config_json
    }
  )

  container_environment = [
    for name, value in local.full_environment :
    { name = name, value = value }
  ]

  policies = merge(
    var.db.iam ? { rrxConfigDbIam = {
      actions   = ["rds-db:connect"]
      resources = ["arn:aws:rds-db:${module.aws[0].region}:${module.aws[0].account}:dbuser:${var.db.resource_id}/${var.db.user}"]
    } } : {},
    var.aws_secret != null ? { rrxConfigSecret = {
      actions   = ["secretsmanager:GetSecretValue"]
      resources = [aws_secretsmanager_secret.config[0].arn]
    } } : {}
  )
}

module "aws" {
  count  = var.db.iam ? 1 : 0
  source = "github.com/tfext/terraform-aws-base"
}

resource "aws_secretsmanager_secret" "config" {
  count = local.aws_secret_count
  name  = var.aws_secret
}

resource "aws_secretsmanager_secret_version" "config" {
  count         = local.aws_secret_count
  secret_id     = aws_secretsmanager_secret.config.0.id
  secret_string = local.full_config_json
}

data "aws_iam_policy_document" "role_policy" {
  dynamic "statement" {
    for_each = local.policies
    content {
      sid       = statement.key
      actions   = statement.value.actions
      resources = statement.value.resources
    }
  }
}
