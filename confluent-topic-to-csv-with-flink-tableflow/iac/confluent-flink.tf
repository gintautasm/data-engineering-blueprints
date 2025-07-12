# Deploy a Flink SQL statement to Confluent Cloud.
resource "confluent_flink_statement" "pizza_orders_silver" {
  organization {
    id = var.confluent_cloud_organization_id
  }

  environment {
    id = var.confluent_cloud_environment_id
  }

  compute_pool {
    id = var.flink_compute_pool_id
  }

  principal {
    id = var.flink_service_account_id
  }

  # This SQL reads data from source_topic, filters it, and ingests the filtered data into sink_topic.
  statement = <<EOT
INSERT INTO `pizza-orders-silver`
SELECT 
  `store_order_id` AS `key`,
  `store_id`,
  `store_order_id`,
  `coupon_code`,
  `date`,
  `status`,
  `registertime`,
  `userid`,
  `regionid`,
  `gender`,
  `order_lines`
FROM (
-- flattenning event CTE
WITH `pizza-orders.flat` AS (
  SELECT `$rowtime`, `store_order_id` AS `key`, *, `customer`.*
    FROM `pizza-orders` 
),
`pizza-orders.ranked` AS
-- adding rank CTE
(SELECT *
  ---- For Reasons PoC does not want to dedup pizza-orders topic, might be due to some misconfiguration
  ---- on Datagen source key schema
  --, ROW_NUMBER() OVER (PARTITION BY `store_order_id` ORDER BY `$rowtime` ASC) AS rownum
FROM `pizza-orders.flat`)
-- fetching deduped data

SELECT *
  FROM `pizza-orders.ranked`
--WHERE `rownum` = 1
  ) AS subquery;
    EOT

  properties = {
    "sql.current-catalog"  = var.confluent_cloud_environment_name
    "sql.current-database" = var.kafka_cluster_name
  }

  rest_endpoint = var.flink_rest_endpoint

  credentials {
    key    = var.flink_api_key
    secret = var.flink_api_secret
  }

  depends_on = [ 
    confluent_kafka_topic.input_topic,
    confluent_kafka_topic.output_topic
  ]

}
