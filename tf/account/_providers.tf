terraform {
  backend "s3" {}
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 4"
    }
    databricks = {
      source = "databricks/databricks"
    }
    http = {}
  }
}

provider "aws" {
  region = "us-east-1"
}

provider "databricks" {
  alias         = "mws"
  host          = "https://accounts.cloud.databricks.com"
  account_id    = var.databricks_account_id
  client_id     = data.aws_secretsmanager_secret_version.databricks_client_id.secret_string
  client_secret = data.aws_secretsmanager_secret_version.databricks_client_secret.secret_string
}