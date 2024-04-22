resource "databricks_user" "unity_users" {
  provider  = databricks.mws
  for_each  = toset(local.databricks_metastore_admins)
  user_name = each.key
  force     = true
}

resource "databricks_group" "admin_group" {
  provider     = databricks.mws
  display_name = "unity-admin-group-${var.env}"
}

resource "databricks_group_member" "admin_group_member" {
  provider  = databricks.mws
  for_each  = toset(local.databricks_metastore_admins)
  group_id  = databricks_group.admin_group.id
  member_id = databricks_user.unity_users[each.value].id
}

resource "databricks_user_role" "metastore_admin" {
  provider = databricks.mws
  for_each = toset(local.databricks_metastore_admins)
  user_id  = databricks_user.unity_users[each.value].id
  role     = "account_admin"
}

resource "databricks_metastore" "this" {
  provider      = databricks.mws
  name          = "primary"
  owner         = "unity-admin-group-${var.env}"
  storage_root  = "s3://${aws_s3_bucket.root.id}/metastore"
  region        = data.aws_region.current.name
  force_destroy = true
}

resource "databricks_metastore_assignment" "default_metastore" {
  provider             = databricks.mws
  workspace_id         = databricks_mws_workspaces.this.workspace_id
  metastore_id         = databricks_metastore.this.id
  default_catalog_name = "snowplow"
}