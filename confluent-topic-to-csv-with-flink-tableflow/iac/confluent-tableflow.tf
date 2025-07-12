resource "confluent_tableflow_topic" "kafka_output_topic" {

  environment {
    id = var.confluent_cloud_environment_id
  }

  kafka_cluster {
    id = var.kafka_id
  }

  display_name = local.output_topic_name
  
  table_formats = ["ICEBERG"]
  
  managed_storage {}
  
  credentials {
    key    = var.tableflow_api_key
    secret = var.tableflow_api_secret
  }
}