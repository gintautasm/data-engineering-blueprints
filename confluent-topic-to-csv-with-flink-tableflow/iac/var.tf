#region --- var.tf

variable "aws_region" {
  type = string
}

variable "confluent_cloud_organization_id" {
    type = string
    sensitive = true
}

variable "confluent_cloud_environment_id" {
  type = string
  sensitive = true
}

variable "confluent_cloud_environment_name" {
  type = string
  sensitive = true
}

variable "confluent_cloud_api_key" {
  type = string
  sensitive = true
}

variable "confluent_cloud_api_secret" {
  type = string
  sensitive = true
}

variable "kafka_id" {
  type = string
  sensitive = true
}

variable "kafka_cluster_name" {
  type = string
  sensitive = true
}

variable "kafka_rest_endpoint" {
  type = string
  sensitive = true
}

variable "kafka_api_key" {
  type = string
  sensitive = true
}

variable "kafka_api_secret" {
  type = string
  sensitive = true
}

variable "schema_registry_id" {
  type = string
  sensitive = true
}

variable "schema_registry_rest_endpoint" {
  type = string
  sensitive = true
}

variable "schema_registry_api_key" {
  type = string
  sensitive = true
}

variable "schema_registry_api_secret" {
  type = string
  sensitive = true
}

variable "tableflow_catalog_rest_endpoint" {
  type = string
  sensitive = true
}

variable "tableflow_api_key" {
  type = string
  sensitive = true
}

variable "tableflow_api_secret" {
  type = string
  sensitive = true
}

variable "flink_compute_pool_id" {
  type = string
  sensitive = true
}

variable "flink_rest_endpoint" {
  type = string
  sensitive = true
}

variable "flink_api_key" {
  type = string
  sensitive = true
}

variable "flink_api_secret" {
  type = string
  sensitive = true
}

variable "flink_service_account_id" {
  type = string
  sensitive = true
}

#endregion
