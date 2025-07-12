
#region --- Providers

terraform {
  required_version = ">= 1.12.2"

  required_providers {
    aws = {
      source = "hashicorp/aws"
      version = "6.0.0"
    }

    confluent = {
      source = "confluentinc/confluent"
      version = "2.34.0"
    }

    docker = {
      source  = "kreuzwerker/docker"
      version = "3.6.2"
    }
  }
}

#endregion



