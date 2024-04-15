output "notebook_url" {
  value = databricks_notebook.this.url
}

output "notebook_url_snowplow_visualization" {
  value = databricks_notebook.snowplow_visualization.url
}

output "job_url" {
  value = databricks_job.this.url
}