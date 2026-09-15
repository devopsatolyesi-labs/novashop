#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
if [ -f "$SCRIPT_DIR/.env" ]; then
    set -a
    # shellcheck disable=SC1091
    source "$SCRIPT_DIR/.env"
    set +a
fi

# Değişken kontrolleri
: "${AWS_REGION:?HATA: AWS_REGION .env dosyasında tanımlanmalıdır}"
: "${AWS_ACCOUNT_ID:?HATA: AWS_ACCOUNT_ID .env dosyasında tanımlanmalıdır}"
: "${GITHUB_ORG_OR_USER:?HATA: GITHUB_ORG_OR_USER .env dosyasında tanımlanmalıdır}"

ECR_REPO_NAME="${ECR_REPO_NAME:-novashop-ui}"
ROLE_NAME="${ROLE_NAME:-novashop-github-actions-role}"
GITHUB_REPO_NAME="${GITHUB_REPO_NAME:-novashop}"

echo "=== 1. AWS ECR Kayıt Defteri Oluşturuluyor: ${ECR_REPO_NAME} ==="
if aws ecr describe-repositories --repository-names "$ECR_REPO_NAME" --region "$AWS_REGION" >/dev/null 2>&1; then
    echo "ℹ️ ECR reposu zaten mevcut: $ECR_REPO_NAME"
else
    aws ecr create-repository \
      --repository-name "$ECR_REPO_NAME" \
      --image-tag-mutability IMMUTABLE \
      --image-scanning-configuration scanOnPush=true \
      --region "$AWS_REGION"
    echo "✅ ECR reposu oluşturuldu: $ECR_REPO_NAME"
fi

echo "=== 2. GitHub OIDC Sağlayıcı (Identity Provider) Kontrol Ediliyor ==="
if aws iam list-open-id-connect-providers | grep -q "token.actions.githubusercontent.com"; then
    echo "ℹ️ GitHub OIDC provider zaten mevcut."
else
    aws iam create-open-id-connect-provider \
      --url https://token.actions.githubusercontent.com \
      --client-id-list sts.amazonaws.com \
      --thumbprint-list 6938fd4d98bab03faadb97b34396831e3780aea1 1c5860f5b04e3ca1a81f3cb0e6e1b4b0e8b5770e
    echo "✅ GitHub OIDC provider eklendi."
fi

echo "=== 3. GitHub Actions IAM Rolü ve Güven İlkesi Yapılandırılıyor ==="
TRUST_POLICY=$(cat << EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Federated": "arn:aws:iam::${AWS_ACCOUNT_ID}:oidc-provider/token.actions.githubusercontent.com"
      },
      "Action": "sts:AssumeRoleWithWebIdentity",
      "Condition": {
        "StringEquals": {
          "token.actions.githubusercontent.com:aud": "sts.amazonaws.com"
        },
        "StringLike": {
          "token.actions.githubusercontent.com:sub": "repo:${GITHUB_ORG_OR_USER}/${GITHUB_REPO_NAME}:*"
        }
      }
    }
  ]
}
EOF
)

if aws iam get-role --role-name "$ROLE_NAME" >/dev/null 2>&1; then
    echo "ℹ️ IAM Rolü mevcut, güven ilkesi güncelleniyor: $ROLE_NAME"
    aws iam update-assume-role-policy \
      --role-name "$ROLE_NAME" \
      --policy-document "$TRUST_POLICY"
else
    aws iam create-role \
      --role-name "$ROLE_NAME" \
      --assume-role-policy-document "$TRUST_POLICY"
    echo "✅ IAM rolü oluşturuldu: $ROLE_NAME"
fi

aws iam attach-role-policy \
  --role-name "$ROLE_NAME" \
  --policy-arn arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryPowerUser
echo "✅ ECR PowerUser yetki politikası role bağlandı."

echo ""
echo "========================================================================"
echo "🎉 AWS Kaynakları Başarıyla Hazırlandı!"
echo "GitHub reponuzun (Settings > Secrets and variables > Actions) sayfasına"
echo "aşağıdaki değerleri giriniz:"
echo "------------------------------------------------------------------------"
echo "[Repository Secrets]"
echo "EC2_SSH_KEY        : (cat ${KEY_PATH:-~/.ssh/novashop-key.pem} içeriği)"
echo ""
echo "[Repository Variables]"
echo "AWS_ROLE_TO_ASSUME : arn:aws:iam::${AWS_ACCOUNT_ID}:role/${ROLE_NAME}"
echo "AWS_REGION         : ${AWS_REGION}"
echo "ECR_REPOSITORY     : ${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com/${ECR_REPO_NAME}"
echo "EC2_HOST           : ${EC2_PUBLIC_IP:-<EC2_PUBLIC_IP>}"
echo "EC2_USER           : ${EC2_USER:-ubuntu}"
echo "========================================================================"
