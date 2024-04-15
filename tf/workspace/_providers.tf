terraform {
    backend "s3" {}
    required_providers {
        aws = {
            source = "hashicorp/aws"
            version = ">= 4"
        }
        databricks = {
            source  = "databricks/databricks"
        }
    }
}

provider "aws" {
    region = "us-east-1"
}

provider "databricks" {
  host  = data.terraform_remote_state.mws.outputs.databricks_host
  token = data.aws_secretsmanager_secret_version.databricks_token.secret_string
}

# provider "databricks" {
#   host  = "https://dbc-a353deb8-ec08.cloud.databricks.com"
#   username = "patrickoconnor8014@gamil.com"
#   password = "Redsoxrock8!"
# }