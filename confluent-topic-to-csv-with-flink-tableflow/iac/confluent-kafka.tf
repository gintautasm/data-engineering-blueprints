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

#region -- Confluent Cloud topic

locals {
  input_topic_name = "pizza-orders"
  output_topic_name = "pizza-orders-silver"
}

resource "confluent_kafka_topic" "input_topic" {

  kafka_cluster {
    id = var.kafka_id
  }

  topic_name = local.input_topic_name

  partitions_count = 3

  config = {
      "retention.ms"                      = "604800000"   # infinite 0; default value is 604800000 (7 days)
      "confluent.key.schema.validation"   = "true" # default value is false
      "confluent.value.schema.validation" = "true" # default value is false
    }
}

## Datagen source connector does not use correct key schema while generating messages
## thus trying to read the topic with Flink gives error:
## Failed to deserialize Avro record.
## Suppressed: Unknown data format. Magic number does not match
## Suppressed: Failed to deserialize AVRO record.

# resource "confluent_schema" "input_key_schema" {

#   format = "AVRO"
#   subject_name = "${local.input_topic_name}-key"
#   schema  = file("${path.module}/int.avsc")
# }

resource "confluent_schema" "input_value_schema" {

  format = "AVRO"
  subject_name = "${local.input_topic_name}-value"
  schema  = file("${path.module}/datagen-pizza-orders-with-customers.json")
}

resource "confluent_kafka_topic" "output_topic" {

  kafka_cluster {
    id = var.kafka_id
  }

  topic_name = local.output_topic_name
  partitions_count = 3

  config = {
      "retention.ms"                      = "604800000"   # infinite 0; default value is 604800000 (7 days)
      "confluent.key.schema.validation"   = "true" # default value is false
      "confluent.value.schema.validation" = "true" # default value is false
    }
}

resource "confluent_schema" "output_key_schema" {

  format = "AVRO"
  subject_name = "${local.output_topic_name}-key"
  schema  = file("${path.module}/int.avsc")
}

resource "confluent_schema" "output_value_schema" {

  format = "AVRO"
  subject_name = "${local.output_topic_name}-value"
  schema  = file("${path.module}/datagen-pizza-orders-with-customers-silver.json")
}

#endregion

