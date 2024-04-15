output "databricks_token" {
  value     = databricks_mws_workspaces.this.token[0].token_value
  sensitive = true
}

output "databricks_host" {
  value = databricks_mws_workspaces.this.workspace_url
}

output "databricks_metastore" {
  value = databricks_metastore.this.id
}