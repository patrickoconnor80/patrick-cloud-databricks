data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

data "databricks_current_user" "me" {}
data "databricks_spark_version" "latest" {}
data "databricks_node_type" "smallest" {
  local_disk = true
}
data "databricks_current_metastore" "this" {}

data "aws_secretsmanager_secret" "databricks_token" {
  name = "DATABRICKS_TOKEN_"
}

data "aws_secretsmanager_secret_version" "databricks_token" {
  secret_id = data.aws_secretsmanager_secret.databricks_token.id
}

data "aws_secretsmanager_secret" "databricks_client_id" {
  name = "DATABRICKS_CLIENT_ID"
}

data "aws_secretsmanager_secret_version" "databricks_client_id" {
  secret_id = data.aws_secretsmanager_secret.databricks_client_id.id
}

data "terraform_remote_state" "mws" {
  backend = "s3"
  config = {
    bucket = "patrick-cloud-tf-state"
    key    = "databricks.mws.${var.env}.tfstate"
    region = data.aws_region.current.name
  }
}