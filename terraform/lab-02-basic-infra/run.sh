#!/usr/bin/env bash
# ==============================================================================
# NovaShop LAB-02: Tek Komutla AWS Altyapı Kurulumu (Zero-Touch Automation)
# ==============================================================================
# Sadece AWS Access Key ve Secret Key tanımlandığında:
# 1. AWS hesap kimliğini otomatik çözer.
# 2. S3 tfstate bucket'ını otomatik oluşturur ve versiyonlar.
# 3. novashop-key SSH anahtar çiftini kontrol edip yoksa üretir.
# 4. Terraform S3 backend ile başlatıp altyapıyı (VPC, EC2, RDS) ayağa kaldırır.
# ==============================================================================
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

: "${AWS_ACCESS_KEY_ID:?HATA: AWS_ACCESS_KEY_ID ortam değişkeni tanımlanmalıdır.}"
: "${AWS_SECRET_ACCESS_KEY:?HATA: AWS_SECRET_ACCESS_KEY ortam değişkeni tanımlanmalıdır.}"
export AWS_DEFAULT_REGION="${AWS_DEFAULT_REGION:-us-east-1}"

echo "======================================================================"
echo "🚀 NovaShop LAB-02 Terraform Altyapı Dağıtımı Başlatılıyor"
echo "   Bölge (Region): $AWS_DEFAULT_REGION"
echo "======================================================================"

echo "▶ 1. AWS Kimlik Doğrulaması yapılıyor..."
ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
IAM_ARN=$(aws sts get-caller-identity --query Arn --output text)
echo "   Hesap ID: $ACCOUNT_ID | IAM: $IAM_ARN"

BUCKET_NAME="novashop-tfstate-${ACCOUNT_ID}"
echo "▶ 2. S3 tfstate bucket kontrol ediliyor: $BUCKET_NAME ..."
if aws s3api head-bucket --bucket "$BUCKET_NAME" 2>/dev/null; then
    echo "   S3 bucket mevcut: $BUCKET_NAME"
else
    echo "   S3 bucket oluşturuluyor: $BUCKET_NAME ..."
    if [ "$AWS_DEFAULT_REGION" = "us-east-1" ]; then
        aws s3api create-bucket --bucket "$BUCKET_NAME" --region "$AWS_DEFAULT_REGION"
    else
        aws s3api create-bucket --bucket "$BUCKET_NAME" --region "$AWS_DEFAULT_REGION" \
            --create-bucket-configuration LocationConstraint="$AWS_DEFAULT_REGION"
    fi
    aws s3api put-bucket-versioning --bucket "$BUCKET_NAME" --versioning-configuration Status=Enabled
    echo "   S3 bucket başarıyla oluşturuldu ve versiyonlandı."
fi

echo "▶ 3. EC2 SSH Anahtar Çifti (novashop-key) kontrol ediliyor..."
mkdir -p ~/.ssh
if aws ec2 describe-key-pairs --key-names novashop-key --region "$AWS_DEFAULT_REGION" >/dev/null 2>&1; then
    echo "   'novashop-key' anahtarı AWS üzerinde mevcut."
else
    echo "   'novashop-key' oluşturuluyor ve ~/.ssh/novashop-key.pem dosyasına kaydediliyor..."
    aws ec2 create-key-pair --key-name novashop-key --query "KeyMaterial" --output text \
        --region "$AWS_DEFAULT_REGION" > ~/.ssh/novashop-key.pem
    chmod 400 ~/.ssh/novashop-key.pem
fi

echo "▶ 4. Terraform S3 Backend ile başlatılıyor (init)..."
terraform init -reconfigure -backend-config="bucket=$BUCKET_NAME"

echo "▶ 5. Altyapı oluşturuluyor (apply)..."
terraform apply -auto-approve

echo "======================================================================"
echo "✅ Kurulum Tamamlandı! Erişim Bilgileri:"
echo "======================================================================"
terraform output
