data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

data "aws_vpc" "this" {
    filter {
        name = "tag:Name"
        values = ["${local.prefix}-vpc"]
    }
}

data "aws_subnets" "public" {
    filter {
        name = "tag:Name"
        values = ["${local.prefix}-public-us-east-1*"]
    }
}

data "aws_subnet" "public" {
  for_each = toset(data.aws_subnets.public.ids)
  id       = each.value
}

data "aws_subnets" "private" {
    filter {
        name = "tag:Name"
        values = ["${local.prefix}-private-us-east-1*"]
    }
}

data "aws_subnet" "private" {
  for_each = toset(data.aws_subnets.private.ids)
  id       = each.value
}

data "aws_subnets" "dbx_dataplane_vpce" {
    filter {
        name = "tag:Name"
        values = ["${local.prefix}-dbx-dataplane-vpce-us-east-1*"]
    }
}

data "aws_subnet" "dbx_dataplane_vpce" {
  for_each = toset(data.aws_subnets.dbx_dataplane_vpce.ids)
  id       = each.value
}

data "aws_secretsmanager_secret" "databricks_client_id" {
  name = "DATABRICKS_CLIENT_ID"
}

data "aws_secretsmanager_secret_version" "databricks_client_id" {
  secret_id = data.aws_secretsmanager_secret.databricks_client_id.id
}

data "aws_secretsmanager_secret" "databricks_client_secret" {
  name = "DATABRICKS_CLIENT_SECRET"
}

data "aws_secretsmanager_secret_version" "databricks_client_secret" {
  secret_id = data.aws_secretsmanager_secret.databricks_client_secret.id
}

data "aws_security_group" "dbx" {
  name = "${local.prefix}-dbx-sg"
}

data "aws_security_group" "dbx_dataplane_vpce" {
  name = "${local.prefix}-dbx-dataplane-vpce-sg"
}

data "aws_security_group" "snowplow_db_loader" {
  name = "${local.prefix}-snowplow-db-loader-server"
}

data "aws_security_group" "kubernetes" {
  tags = {
    "kubernetes.io/cluster/${local.prefix}-eks-cluster" = "owned"
  }
}

data "http" "my_ip" {
  url = "https://ifconfig.me"
}