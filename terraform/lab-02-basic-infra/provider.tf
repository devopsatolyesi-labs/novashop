terraform {
  required_version = ">= 1.5.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region

  # AWS Kimlik Doğrulama:
  # Kimlik bilgileri otomatik olarak yerel ortam değişkenlerinden (AWS_ACCESS_KEY_ID, AWS_SECRET_ACCESS_KEY)
  # veya Ubuntu üzerindeki `~/.aws/credentials` dosyasından okunur.
  default_tags {
    tags = {
      Project     = "NovaShop"
      Lab         = "LAB-02-AWS-BASICS"
      Provisioner = "Terraform"
    }
  }
}
