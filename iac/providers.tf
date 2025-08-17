# Specify the Terraform version
terraform {
  required_version = ">= 1.0.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

# Configure the AWS provider
provider "aws" {
  region  = "us-east-1" # AWS region
}


terraform {
  backend "s3" {
    bucket = "snowflake-user-data-vader-k"
    key    = "iac/state_file/state_file"
    region = "us-east-1"
  }
}
