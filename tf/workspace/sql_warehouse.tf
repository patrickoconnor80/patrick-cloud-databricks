resource "databricks_sql_endpoint" "this" {
  name                 = "${local.prefix}-sql-warehouse"
  cluster_size         = "2X-Small"
  max_num_clusters     = 1
  auto_stop_mins       = 10
  spot_instance_policy = "COST_OPTIMIZED"
}

resource "databricks_permissions" "sql_warehouse" {
  sql_endpoint_id = databricks_sql_endpoint.this.id

  access_control {
    user_name        = databricks_user.admin.user_name
    permission_level = "IS_OWNER"
  }
}