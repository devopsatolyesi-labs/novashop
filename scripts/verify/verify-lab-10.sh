#!/usr/bin/env bash
# NovaShop — LAB-10 Gözlemlenebilirlik (Prometheus, Grafana, OpenTelemetry) Doğrulama Betiği
set -e

PORT="${1:-8888}"
HOST="${2:-localhost}"

echo "=== [LAB-10] Gözlemlenebilirlik Doğrulama Başlatılıyor ==="

# 1. Spring Boot Actuator Prometheus Metrik Endpoint'i
echo "1. Actuator Prometheus metrik endpoint'i test ediliyor..."
METRICS_BODY=$(curl -s --connect-timeout 5 "http://${HOST}:${PORT}/actuator/prometheus" 2>/dev/null || echo "")

if echo "$METRICS_BODY" | grep -q "jvm_memory_used_bytes"; then
    echo "✅ /actuator/prometheus üzerinden JVM metrikleri başarıyla alınıyor."
else
    echo "⚠️ UYARI: http://${HOST}:${PORT}/actuator/prometheus yanıt vermedi veya jvm_memory_used_bytes içermiyor."
    echo "   (UI servisinin ayakta olduğundan emin olun)"
fi

# 2. HTTP Server İstek Sayacı Kontrolü
if echo "$METRICS_BODY" | grep -q "http_server_requests_seconds"; then
    echo "✅ HTTP istek gecikme ve sayaç metrikleri (http_server_requests_seconds) mevcut."
fi

# 3. OpenTelemetry / Jaeger Trace Context
if echo "$METRICS_BODY" | grep -qi "trace"; then
    echo "✅ Dağıtık izleme (Trace) metrikleri etkin."
fi

# 4. Prometheus / Grafana Canlı Port Kontrolü (Opsiyonel)
PROM_PORT="${3:-9090}"
PROM_HEALTH=$(curl -s --connect-timeout 3 "http://${HOST}:${PROM_PORT}/-/healthy" 2>/dev/null || echo "")
if [ "$PROM_HEALTH" = "Prometheus Server is Healthy." ]; then
    echo "✅ Prometheus sunucusu sağlıklı çalışıyor (Port $PROM_PORT)."
fi

echo "=== [LAB-10] Gözlemlenebilirlik Doğrulama Tamamlandı ==="
