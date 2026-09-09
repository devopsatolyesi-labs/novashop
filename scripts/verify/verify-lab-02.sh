#!/usr/bin/env bash
# NovaShop — LAB-02 AWS Temel Altyapı ve Nginx Doğrulama Betiği
set -e

EC2_HOST="${1:-}"

if [ -z "$EC2_HOST" ]; then
    echo "Kullanım: $0 <EC2_PUBLIC_IP_VEYA_HOST>"
    echo "Örnek:   $0 3.120.45.67"
    exit 1
fi

echo "=== [LAB-02] Doğrulama Başlatılıyor: $EC2_HOST ==="

# 1. HTTP 80 Ana Sayfa Yanıtı (Beklenen: 200 OK)
echo "1. Ana sayfa (HTTP 200) kontrol ediliyor..."
HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" --connect-timeout 5 "http://${EC2_HOST}/" || echo "000")

if [ "$HTTP_CODE" = "200" ]; then
    echo "✅ Ana sayfa HTTP 200 OK döndü."
else
    echo "❌ HATA: Ana sayfa $HTTP_CODE döndü (Beklenen: 200)."
    exit 1
fi

# 2. Sağlık Kontrolü Endpoint'i (/healthz)
echo "2. Sağlık kontrolü (/healthz) test ediliyor..."
HEALTH_BODY=$(curl -s --connect-timeout 5 "http://${EC2_HOST}/healthz" || true)

if echo "$HEALTH_BODY" | grep -q '"status":"UP"'; then
    echo "✅ Sağlık kontrolü başarılı: $HEALTH_BODY"
else
    echo "❌ HATA: /healthz beklenen yanıtı vermedi: $HEALTH_BODY"
    exit 1
fi

echo "=== [LAB-02] Tüm Testler Başarılı! ==="
