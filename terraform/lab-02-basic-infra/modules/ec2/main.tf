# 1. En Güncel Resmi Ubuntu 22.04 LTS AMI Kimliğini Sorgula
data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"] # Canonical resmi AWS hesap kimliği

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

# 2. EC2 Web Sunucusu (Nginx & Cloud-Init ile Otomatik Yapılandırma)
resource "aws_instance" "web" {
  ami                         = data.aws_ami.ubuntu.id
  instance_type               = var.instance_type
  subnet_id                   = var.subnet_id
  vpc_security_group_ids      = [var.security_group_id]
  associate_public_ip_address = true
  key_name                    = var.key_name != "" ? var.key_name : null

  root_block_device {
    volume_size           = 20
    volume_type           = "gp3"
    encrypted             = true
    delete_on_termination = true
  }

  user_data = <<-EOF
              #!/bin/bash
              set -e
              export DEBIAN_FRONTEND=noninteractive
              apt-get update -y
              apt-get install -y nginx curl mysql-client ca-certificates

              # Nginx NovaShop Web & Healthcheck Yapılandırması
              cat << 'CONF' > /etc/nginx/conf.d/novashop.conf
              server {
                  listen 80 default_server;
                  listen [::]:80 default_server;
                  server_name _;

                  # Sağlık Kontrolü (Healthcheck) Uç Noktası
                  location = /healthz {
                      access_log off;
                      default_type application/json;
                      return 200 '{"status":"UP","layer":"web","provisioner":"terraform","service":"novashop-storefront"}\n';
                  }

                  # Ana Sayfa Karşılama Sayfası
                  location / {
                      default_type text/html;
                      return 200 '<!DOCTYPE html><html><head><title>NovaShop DevOps Store (Terraform IaC)</title><style>body{font-family:Arial,sans-serif;margin:40px;background:#f5f7fa;color:#333}h1{color:#0066cc}.badge{background:#28a745;color:white;padding:4px 8px;border-radius:4px;font-size:12px}</style></head><body><h1>NovaShop DevOps Store <span class="badge">Terraform ile Kuruldu</span></h1><p>Bu altyapı <strong>Terraform IaC</strong> modülleri ile tam otomatik olarak ayağa kaldırılmıştır.</p><hr/><p><strong>Ortam:</strong> AWS Cloud (EC2 Public Subnet)</p><p><strong>Veritabanı Uç Noktası:</strong> ${var.db_endpoint}</p><p><strong>Sağlık Uç Noktası:</strong> <a href="/healthz">/healthz</a></p></body></html>\n';
                  }
              }
              CONF

              # Varsayılan Ubuntu karşılama sayfasını kaldır ve servisi yeniden başlat
              rm -f /etc/nginx/sites-enabled/default
              nginx -t && systemctl restart nginx
              EOF

  tags = {
    Name        = "${var.project_name}-web"
    Tier        = "web"
    Provisioner = "terraform"
  }
}
