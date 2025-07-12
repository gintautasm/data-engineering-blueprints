#region --- Datagen source connector

resource "confluent_connector" "pizza_orders_source" {
  environment {
    id = var.confluent_cloud_environment_id
  }
  kafka_cluster {
    id = var.kafka_id
  }

  config_sensitive = {
    "kafka.api.key"     = var.kafka_api_key
    "kafka.api.secret"  = var.kafka_api_secret

    "key.converter.basic.auth.user.info"   = "${var.schema_registry_api_key}:${var.schema_registry_api_secret}"
    "value.converter.basic.auth.user.info" = "${var.schema_registry_api_key}:${var.schema_registry_api_secret}"
  }

  config_nonsensitive = {
    "connector.class"          = "DatagenSource"
    "name"                     = "pizza-orders"
    "kafka.auth.mode"          = "KAFKA_API_KEY"
    "kafka.topic"              = local.input_topic_name
    "output.data.format"       = "AVRO"
    "tasks.max"                = "1"
    "max.interval"             = "5000" # milliseconds
    "schema.string"            = file("${path.module}/datagen-pizza-orders-with-customers.json")
    "schema.keyfield"          = "store_order_id",

    # "key.converter"                = "org.apache.kafka.connect.storage.StringConverter",
    # "key.converter.schemas.enable" = "false"

    # "value.converter"                = "org.apache.kafka.connect.json.JsonConverter",
    # "value.converter.schemas.enable" = "false"

    "key.converter.schemas.enable"                = "true",
    "key.converter"                               = "io.confluent.connect.avro.AvroConverter",
    "key.converter.basic.auth.credentials.source" = "USER_INFO"
    "key.converter.schema.registry.url"           = var.schema_registry_rest_endpoint

    "value.converter.schemas.enable"                = "true"
    "value.converter"                               = "io.confluent.connect.avro.AvroConverter"
    "value.converter.basic.auth.credentials.source" = "USER_INFO"
	  "value.converter.schema.registry.url"           = var.schema_registry_rest_endpoint
  }

}

#endregion