resource "databricks_notebook" "this" {
  path     = "${databricks_user.admin.home}/Terraform"
  language = "PYTHON"
  content_base64 = base64encode(<<-EOT
    token = dbutils.secrets.get('${databricks_secret_scope.this.name}', '${databricks_secret.token.key}')
    print(f'This should be redacted: {token}')
    EOT
  )
}

resource "databricks_permissions" "notebook" {
  notebook_path = databricks_notebook.this.id
  access_control {
    user_name        = databricks_user.admin.user_name
    permission_level = "CAN_RUN"
  }
  access_control {
    group_name       = databricks_group.read_only.display_name
    permission_level = "CAN_READ"
  }
}

resource "databricks_notebook" "snowplow_visualization" {
  source = "../../src/notebooks/snowplow_advanced_analytics_for_web.ipynb"
  path   = "${databricks_user.admin.home}/Snowplow/Visualization/snowplow_advanced_analytics_for_web.ipynb"
}

resource "databricks_permissions" "snowplow_visualization" {
  notebook_path = databricks_notebook.snowplow_visualization.id
  access_control {
    user_name        = databricks_user.admin.user_name
    permission_level = "CAN_RUN"
  }
  access_control {
    group_name       = databricks_group.read_only.display_name
    permission_level = "CAN_READ"
  }
}

resource "databricks_job" "this" {
  name = "Terraform Demo (${data.databricks_current_user.me.alphanumeric})"

  task {
    task_key = "task1"

    new_cluster {
      num_workers   = 1
      spark_version = data.databricks_spark_version.latest.id
      node_type_id  = data.databricks_node_type.smallest.id
    }

    notebook_task {
      notebook_path = databricks_notebook.this.path
    }
  }
}

resource "databricks_permissions" "job" {
  job_id = databricks_job.this.id
  access_control {
    user_name        = databricks_user.admin.user_name
    permission_level = "IS_OWNER"
  }
  access_control {
    group_name       = databricks_group.read_only.display_name
    permission_level = "CAN_MANAGE_RUN"
  }
}