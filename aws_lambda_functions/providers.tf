provider "aws" {
  region = "us-east-1"
  
}

terraform {
    backend "s3" {
      encrypt = true
      bucket = "sahurtado01172025"
      key = "states/lambda/terraform.tfstate"
      region = "us-east-1"
  }
}