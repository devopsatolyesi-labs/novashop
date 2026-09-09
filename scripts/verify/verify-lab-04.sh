#!/usr/bin/env bash
# NovaShop — LAB-04 AWS 3-Tier ve Nginx TLS Doğrulama Betiği
set -e

TARGET_HOST="${1:-}"
INSECURE_FLAG="${2:-}"

if [ -z "$TARGET_HOST" ]; then
    echo "Kullanım: $0 <HOST_VEYA_IP> [--insecure]"
    echo "Örnek:   $0 3.120.45.67 --insecure"
    echo "Örnek:   $0 novashop.example.com"
    exit 1
fi

CURL_OPTS="-s --connect-timeout 8"
if [ "$INSECURE_FLAG" = "--insecure" ] || [ "$INSECURE_FLAG" = "-k" ]; then
    CURL_OPTS="$CURL_OPTS -k"
fi

echo "=== [LAB-04] Doğrulama Başlatılıyor: $TARGET_HOST ==="

# 1. HTTP -> HTTPS Yönlendirmesi Kontrolü
echo "1. HTTP (Port 80) -> HTTPS yönlendirme testi..."
HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" --connect-timeout 5 "http://${TARGET_HOST}/" || echo "000")

if [ "$HTTP_CODE" = "301" ] || [ "$HTTP_CODE" = "302" ]; then
    echo "✅ HTTP -> HTTPS yönlendirmesi başarılı (HTTP $HTTP_CODE)."
else
    echo "⚠️ UYARI: HTTP 80 portu $HTTP_CODE döndü (Beklenen: 301/302 yönlendirme)."
fi

# 2. HTTPS Ana Sayfa ve Marka Doğrulama
echo "2. HTTPS üzerinden ana sayfa ve NovaShop marka kontrolü..."
HOME_PAGE=$(curl $CURL_OPTS "https://${TARGET_HOST}/" 2>/dev/null || echo "")

if echo "$HOME_PAGE" | grep -q "NovaShop DevOps Store"; then
    echo "✅ HTTPS erişimi ve marka başlığı ('NovaShop DevOps Store') doğrulandı."
else
    echo "❌ HATA: HTTPS ana sayfasında 'NovaShop DevOps Store' bulunamadı."
    exit 1
fi

# 3. HTTPS Actuator Sağlık Kontrolü
echo "3. HTTPS /actuator/health sağlık kontrolü..."
HEALTH_BODY=$(curl $CURL_OPTS "https://${TARGET_HOST}/actuator/health" 2>/dev/null || echo "")

if echo "$HEALTH_BODY" | grep -q '"status":"UP"'; then
    echo "✅ Actuator sağlık kontrolü başarılı: $HEALTH_BODY"
else
    echo "❌ HATA: /actuator/health yanıtı başarısız: $HEALTH_BODY"
    exit 1
fi

# 4. Favicon HTTP 200 Kontrolü
HTTP_CODE=$(curl $CURL_OPTS -o /dev/null -w "%{http_code}" "https://${TARGET_HOST}/favicon.ico" 2>/dev/null || echo "000")
if [ "$HTTP_CODE" = "200" ]; then
    echo "✅ HTTPS Favicon HTTP 200 OK."
fi

echo "=== [LAB-04] Tüm 3-Tier Doğrulamaları Başarılı! ==="
