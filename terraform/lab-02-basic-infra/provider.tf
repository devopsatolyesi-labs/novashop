terraform {
  required_version = ">= 1.5.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  backend "s3" {
    bucket  = "novashop-tfstate-934639816492"
    key     = "lab-02/terraform.tfstate"
    region  = "us-east-1"
    encrypt = true
  }
}

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Project     = "NovaShop"
      Lab         = "LAB-02-AWS-BASICS"
      Provisioner = "Terraform"
    }
  }
}
