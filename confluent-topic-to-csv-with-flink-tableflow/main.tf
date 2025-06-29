#region Variables

variable "aws_region" {
  type = string
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

#endregion

#region Providers

terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
      version = "6.0.0"
    }

    confluent = {
      source = "confluentinc/confluent"
      version = "2.32.0"
    }
  }
}

provider "aws" {
  # Configuration options
  region = var.aws_region
}

provider "confluent" {
  # Configuration options
  cloud_api_key    = var.confluent_cloud_api_key    # optionally use CONFLUENT_CLOUD_API_KEY env var
  cloud_api_secret = var.confluent_cloud_api_secret # optionally use CONFLUENT_CLOUD_API_SECRET env var

  kafka_id            = var.kafka_id                   # optionally use KAFKA_ID env var
  kafka_rest_endpoint = var.kafka_rest_endpoint        # optionally use KAFKA_REST_ENDPOINT env var
  kafka_api_key       = var.kafka_api_key              # optionally use KAFKA_API_KEY env var
  kafka_api_secret    = var.kafka_api_secret           # optionally use KAFKA_API_SECRET env var

  schema_registry_id            = var.schema_registry_id            # optionally use SCHEMA_REGISTRY_ID env var
  schema_registry_rest_endpoint = var.schema_registry_rest_endpoint # optionally use SCHEMA_REGISTRY_REST_ENDPOINT env var
  schema_registry_api_key       = var.schema_registry_api_key       # optionally use SCHEMA_REGISTRY_API_KEY env var
  schema_registry_api_secret    = var.schema_registry_api_secret    # optionally use SCHEMA_REGISTRY_API_SECRET env var
}

#endregion

