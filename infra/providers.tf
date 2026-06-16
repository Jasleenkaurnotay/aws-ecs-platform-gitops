terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0" #Any version in the 5.x series, equivalent to >= 5.0, <6.0
    }
  }

  backend "s3" {
    
  }
}

provider "aws" {
  region  = var.aws_region
  profile = var.aws_profile
}