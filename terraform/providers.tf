provider "aws" {
  region  = "us-east-1"
  profile = "dfx5"
}

terraform {
  backend "s3" {
    encrypt = true
    bucket  = "sahurtado01172025"
    key     = "states/code/terraform.tfstate"
    region  = "us-east-1"
  }
}