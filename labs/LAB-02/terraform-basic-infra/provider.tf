terraform {
  required_version = ">= 1.5.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  backend "s3" {
    # S3 bucket adi hesap bazli dinamik oldugu icin
    # 'terraform init -backend-config="bucket=..."' veya ./run.sh ile verilir.
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
