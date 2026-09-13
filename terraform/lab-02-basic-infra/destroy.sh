#!/usr/bin/env bash
# ==============================================================================
# NovaShop LAB-02: Kaynakları Tek Komutla İmha Etme (Cleanup)
# ==============================================================================
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

: "${AWS_ACCESS_KEY_ID:?HATA: AWS_ACCESS_KEY_ID ortam değişkeni tanımlanmalıdır.}"
: "${AWS_SECRET_ACCESS_KEY:?HATA: AWS_SECRET_ACCESS_KEY ortam değişkeni tanımlanmalıdır.}"
export AWS_DEFAULT_REGION="${AWS_DEFAULT_REGION:-us-east-1}"

echo "======================================================================"
echo "⚠️ NovaShop LAB-02 Terraform Kaynakları Siliniyor (destroy)..."
echo "======================================================================"

terraform destroy -auto-approve

echo "✅ Tüm AWS kaynakları (VPC, EC2, RDS) başarıyla temizlendi."
