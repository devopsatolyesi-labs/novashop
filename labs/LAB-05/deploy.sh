#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

NEW_IMAGE="${1:-}"
if [ -z "$NEW_IMAGE" ]; then
    echo "❌ Hata: İmaj parametresi eksik! Kullanım: ./deploy.sh <IMAGE_URI>" >&2
    exit 1
fi

# .env varsa yükle
if [ -f ".env" ]; then
    set -a
    # shellcheck disable=SC1091
    source ".env"
    set +a
fi

COMPOSE_FILE="${COMPOSE_FILE:-docker-compose.prod.yml}"
if [ ! -f "$COMPOSE_FILE" ]; then
    echo "❌ Hata: $COMPOSE_FILE dosyası bulunamadı!" >&2
    exit 1
fi

echo "=== 1. Mevcut Çalışan İmajı Yedekleme ==="
CURRENT_IMAGE=$(grep -oE "image: .*novashop-ui:[^ \"']+" "$COMPOSE_FILE" | awk '{print $2}' || true)
if [ -z "$CURRENT_IMAGE" ]; then
    CURRENT_IMAGE="public.ecr.aws/aws-containers/retail-store-sample-ui:1.6.2"
fi
echo "Mevcut çalışan stabil imaj: $CURRENT_IMAGE"

echo "=== 2. ECR Kayıt Defterine Giriş ve Yeni İmajı Çekme ==="
REGISTRY=$(echo "$NEW_IMAGE" | cut -d/ -f1)
if [ -n "${ECR_TOKEN:-}" ]; then
    echo "$ECR_TOKEN" | docker login --username AWS --password-stdin "$REGISTRY"
elif command -v aws >/dev/null 2>&1; then
    aws ecr get-login-password --region "${AWS_REGION:-eu-central-1}" | docker login --username AWS --password-stdin "$REGISTRY" 2>/dev/null || true
fi

echo "İmaj çekiliyor: $NEW_IMAGE..."
docker pull "$NEW_IMAGE"

echo "=== 3. $COMPOSE_FILE Güncelleniyor ==="
sed -i.bak -E "s|image: .*novashop-ui:[^ \"']+|image: ${NEW_IMAGE}|g" "$COMPOSE_FILE"
rm -f "${COMPOSE_FILE}.bak" 2>/dev/null || true

echo "=== 4. UI Servisi Güncelleniyor ==="
docker compose -f "$COMPOSE_FILE" up -d ui

echo "=== 5. Sağlık Kontrolü Doğrulaması (Smoke Test) ==="
SUCCESS=0
for i in $(seq 1 15); do
    STATUS=$(curl -s http://127.0.0.1:8888/actuator/health | grep -o '"status":"UP"' || true)
    if [ "$STATUS" = '"status":"UP"' ]; then
        echo "✅ Sağlık kontrolü BAŞARILI ($i/15): $STATUS"
        SUCCESS=1
        break
    fi
    echo "   Servis bekleniyor ($i/15)..."
    sleep 4
done

if [ "$SUCCESS" -ne 1 ]; then
    echo "❌ HATA: Sağlık kontrolü başarısız oldu! Otomatik Rollback başlatılıyor..." >&2
    echo "Geri dönülüyor: $CURRENT_IMAGE"
    sed -i.bak -E "s|image: .*novashop-ui:[^ \"']+|image: ${CURRENT_IMAGE}|g" "$COMPOSE_FILE"
    rm -f "${COMPOSE_FILE}.bak" 2>/dev/null || true
    docker compose -f "$COMPOSE_FILE" up -d ui
    echo "✅ Rollback tamamlandı: Stabil imaj ($CURRENT_IMAGE) yeniden devrede."
    exit 1
fi

echo "=== ✅ Dağıtım Başarıyla Tamamlandı ==="
