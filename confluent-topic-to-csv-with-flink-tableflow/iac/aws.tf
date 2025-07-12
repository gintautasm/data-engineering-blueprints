#region --- Data
data "aws_caller_identity" "current" {}

data "aws_ecr_authorization_token" "token" {}

#endregion

#region --- Providers

provider "aws" {
  # Configuration options
  region = var.aws_region

  default_tags  {
    tags = {
      Environment     = "dev"
      EnvironmentType = "dev"
      Owner           = "platform"
      Service         = "pizza-orders-poc"
      Domain          = "orders"
    }
  }
}

provider "docker" {
  host = "unix:///var/run/docker.sock"

  registry_auth {
    address  = format("%v.dkr.ecr.%v.amazonaws.com", data.aws_caller_identity.current.account_id, var.aws_region)
    username = data.aws_ecr_authorization_token.token.user_name
    password = data.aws_ecr_authorization_token.token.password
  }
}

#endregion

#region --- Docker

resource "aws_ecr_repository" "data_processing_lambda" {

  name = "data-processing-lambda"
  image_tag_mutability = "IMMUTABLE"

}

resource "aws_ecr_lifecycle_policy" "data_processing_lambda" {
  repository = aws_ecr_repository.data_processing_lambda.name

  policy = jsonencode({
    rules = [
      {
        rulePriority = 1
        description  = "Keep last 1 images"
        selection = {
          tagStatus   = "any"
          countType   = "imageCountMoreThan"
          countNumber = 1
        }
        action = {
          type = "expire"
        }
      }
    ]
  })
}

resource "docker_image" "data_processing_lambda" {
  lifecycle {
    ignore_changes = [
      name
    ]
  }

  name = format(
    "%v/%v:%v",
    format("%v.dkr.ecr.%v.amazonaws.com", data.aws_caller_identity.current.account_id, var.aws_region),
    aws_ecr_repository.data_processing_lambda.id,
    formatdate("YYYYMMDD-hhmmss", timestamp())
  )

  build {
    context = "${path.module}/../lambda-src"
  }

  # Rebuild each time the source code or Dockerfile changes
  triggers = {
    source_hash = sha256(
      join(
        ":",
        [
          for f
          in fileset("${path.module}/../lambda-src", "**")
          : filebase64sha256("${path.module}/../lambda-src/${f}")
        ]
      )
    )
  }
}

resource "docker_registry_image" "data_processing_lambda" {
  name          = docker_image.data_processing_lambda.name
  keep_remotely = true
}

#endregion

#region --- S3 bucket

resource "aws_s3_bucket" "data_product_bucket" {
  bucket = "dev-pizza-orders-poc"
}

resource "aws_s3_bucket_public_access_block" "data_product_bucket_public_access_block" {

  bucket = aws_s3_bucket.data_product_bucket.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

#endregion

#region --- cloudwatch

resource "aws_cloudwatch_log_group" "lambda_log_group" {
  name              = "/aws/lambda/${aws_lambda_function.data_processing_lambda.function_name}"
  retention_in_days = 7
}

#endregion

#region --- iam

data "aws_iam_policy_document" "assume_role" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }
}

data "aws_iam_policy_document" "s3_bucket_access" {
  statement {
    effect = "Allow"

    actions = [
      "s3:PutObject",
      "s3:PutObjectAcl",
      "s3:GetObject",
      "s3:GetObjectAcl",
      "s3:AbortMultipartUpload"
    ]

    resources = [
      "${aws_s3_bucket.data_product_bucket.arn}/*",
      aws_s3_bucket.data_product_bucket.arn
    ]
  }

  statement {
    effect = "Allow"

    actions = [
      "logs:CreateLogStream",
      "logs:PutLogEvents"
    ]

    resources = [
      aws_cloudwatch_log_group.lambda_log_group.arn
    ]
  }
}

resource "aws_iam_role_policy" "s3_role_policy" {
  name = "s3_role_policy"
  role = aws_iam_role.iam_for_lambda.id

  policy = data.aws_iam_policy_document.s3_bucket_access.json
}

resource "aws_iam_role" "iam_for_lambda" {
  name               = "dev-pizza-orders-poc-iam-lambda"
  assume_role_policy = data.aws_iam_policy_document.assume_role.json
}

#endregion

#region --- lambda

resource "aws_lambda_function" "data_processing_lambda" {
  function_name = "data-processing-lambda"
  role          = aws_iam_role.iam_for_lambda.arn
  timeout       = 60
  memory_size   = 512

  package_type = "Image"
  image_uri     = docker_registry_image.data_processing_lambda.name

  image_config {
    command = ["function.lambda_handler"]
  }

  environment {
    variables = {
      PYICEBERG_CATALOG__DEFAULT__URI = var.tableflow_catalog_rest_endpoint
      PYICEBERG_CATALOG__DEFAULT__CREDENTIAL = "${var.tableflow_api_key}:${var.tableflow_api_secret}"
      PYICEBERG_CATALOG__DEFAULT__REST__SIGNING_REGION = var.aws_region

      TABLEFLOW_NAMESPACE = var.kafka_id # ID of kafka cluster where the topic is located
      TABLEFLOW_TABLE = "pizza-orders-silver" # same as resource "confluent_kafka_topic" "output_topic"
    }
  }
}

# resource "aws_lambda_function" "data_processing_lambda" {
#   function_name = "data-processing-lambda"
#   role          = aws_iam_role.iam_for_lambda.arn
#   handler       = "function.lambda_handler"
#   timeout       = 60
#   memory_size   = 512

#   package_type = "Zip"

#   environment {
#     variables = {
#       PYICEBERG_CATALOG__DEFAULT__URI = var.tableflow_catalog_rest_endpoint
#       PYICEBERG_CATALOG__DEFAULT__CREDENTIAL = "${var.tableflow_api_key}:${var.tableflow_api_secret}"
#       PYICEBERG_CATALOG__DEFAULT__REST__SIGNING_REGION = var.aws_region
#     }
#   }

#   s3_bucket  = aws_s3_bucket.data_product_bucket.bucket
#   s3_key     = "lambda-functions/app.zip"

#   layers           = [aws_lambda_layer_version.lambda_layer.arn]

#   source_code_hash = data.archive_file.lambda.output_base64sha256

#   runtime = "python3.12"
# }

# data "archive_file" "lambda" {
#   type        = "zip"
#   source_file = "../lambda-src/function.py"
#   output_path = "lambda_function_payload.zip"
# }

# data "archive_file" "lambda_layer" {
#   type        = "zip"
#   source_dir = "../lambda-src/venv/lib"
#   output_path = "lambda_layer_payload.zip"
# }

# resource "aws_s3_object" "lambda_file_upload" {
#   bucket = "${aws_s3_bucket.data_product_bucket.id}"
#   key    = "lambda-functions/app.zip"
#   source = "${data.archive_file.lambda.output_path}" # its mean it depended on zip
# }

# resource "aws_s3_object" "lambda_layer_file_upload" {
#   bucket = "${aws_s3_bucket.data_product_bucket.id}"
#   key    = "lambda-functions/dependencies.zip"
#   source = "${data.archive_file.lambda_layer.output_path}" # its mean it depended on zip
# }

# resource "aws_lambda_event_source_mapping" "integration_lambda_event_source" {
#   event_source_arn  = aws_s3_table.s3_table.stream_arn
#   function_name     = aws_lambda_function.integration_lambda.arn
#   starting_position = "LATEST"
# }

# resource "aws_lambda_layer_version" "lambda_layer" {
#   layer_name = "core-dependencies-layer"
#   s3_bucket  = aws_s3_bucket.data_product_bucket.bucket
#   s3_key     = "lambda-functions/dependencies.zip"

#   #source_code_hash = data.archive_file.lambda_layer.output_base64sha256

#   compatible_runtimes = ["python3.12"]
# }

#endregion