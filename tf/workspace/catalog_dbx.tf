resource "databricks_grants" "metastore" {
  metastore = data.terraform_remote_state.mws.outputs.databricks_metastore
  grant {
    principal  = databricks_user.admin.user_name
    privileges = ["CREATE_EXTERNAL_LOCATION", "CREATE_CATALOG", "CREATE_RECIPIENT", "CREATE_SHARE", "USE_CONNECTION", "USE_SHARE", "USE_PROVIDER"]
  }

  grant {
    principal  = "03cfe233-c92e-4257-886e-e4e7e05c543a"
    privileges = ["CREATE_EXTERNAL_LOCATION", "CREATE_CATALOG", "CREATE_RECIPIENT", "CREATE_SHARE"]
  }
}

resource "databricks_storage_credential" "external" {
  name     = "${local.prefix}-dbx-external-access"
  aws_iam_role {
    role_arn = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/${local.prefix}-dbx-uc-access" //cannot reference aws_iam_role directly, as it will create circular dependency
  }
  comment = "Managed by TF"
}

resource "databricks_grants" "external_creds" {
  storage_credential = databricks_storage_credential.external.id
  grant {
    principal  = databricks_user.admin.user_name
    privileges = ["ALL_PRIVILEGES"]
  }
}

resource "databricks_external_location" "snowplow" {
  name            = "external"
  url             = "s3://${aws_s3_bucket.external.id}/snowplow"
  credential_name = databricks_storage_credential.external.id
  comment         = "Managed by TF"
}

resource "databricks_grants" "snowplow_external_location" {
  external_location = databricks_external_location.snowplow.id
  grant {
    principal  = databricks_user.admin.user_name
    privileges = ["ALL_PRIVILEGES"]
  }
}

resource "databricks_catalog" "snowplow" {
  storage_root = "s3://${aws_s3_bucket.external.id}/snowplow"
  name         = "snowplow"
  comment      = "this catalog is managed by terraform"
  properties = {
    purpose = "testing"
  }
}

resource "databricks_grants" "snowplow_catalog" {
  catalog  = databricks_catalog.snowplow.name
  grant {
    principal  = databricks_user.admin.user_name
    privileges = ["ALL_PRIVILEGES"]
  }
}

resource "databricks_schema" "snowplow_atomic" {
  catalog_name = databricks_catalog.snowplow.id
  name         = "atomic"
  comment      = "this database is managed by terraform"
  properties = {
    kind = "various"
  }
}

resource "databricks_grants" "things" {
  schema   = databricks_schema.snowplow_atomic.id
  grant {
    principal  = databricks_user.admin.user_name
    privileges = ["ALL_PRIVILEGES"]
  }
}