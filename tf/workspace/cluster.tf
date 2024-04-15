resource "databricks_cluster" "this" {
  cluster_name            = "${local.prefix}-cluster"
  spark_version           = data.databricks_spark_version.latest.id
  node_type_id            = data.databricks_node_type.smallest.id
  autotermination_minutes = 20
  data_security_mode = "USER_ISOLATION"

  autoscale {
    min_workers = 1
    max_workers = 2
  }
}

resource "databricks_permissions" "cluster_usage" {
  cluster_id = databricks_cluster.this.id

  access_control {
    group_name       = databricks_group.read_only.display_name
    permission_level = "CAN_ATTACH_TO"
  }

  access_control {
    user_name        = databricks_user.admin.user_name
    permission_level = "CAN_MANAGE"
  }
}