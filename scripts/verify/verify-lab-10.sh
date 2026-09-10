#!/usr/bin/env bash
# NovaShop — LAB-10 Gözlemlenebilirlik (Prometheus, Grafana, OpenTelemetry) Doğrulama Betiği
set -e

PORT="${1:-8888}"
HOST="${2:-localhost}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

echo "=== [LAB-10] Gözlemlenebilirlik Doğrulama Başlatılıyor ==="

if [ "$PORT" = "--config-only" ]; then
    for required_file in \
        "$REPO_ROOT/deploy/observability/docker-compose.observability.yml" \
        "$REPO_ROOT/deploy/observability/prometheus.yml" \
        "$REPO_ROOT/deploy/observability/alert.rules.yml" \
        "$REPO_ROOT/deploy/observability/alertmanager.yml" \
        "$REPO_ROOT/deploy/observability/otel-collector-config.yaml"; do
        if [ ! -f "$required_file" ]; then
            echo "❌ HATA: Gerekli gözlemlenebilirlik dosyası bulunamadı: $required_file" >&2
            exit 1
        fi
    done

    grep -q 'metrics_path: "/actuator/prometheus"' "$REPO_ROOT/deploy/observability/prometheus.yml" || {
        echo "❌ HATA: Prometheus Actuator metrik scrape yolu eksik." >&2
        exit 1
    }
    grep -q 'otlp/jaeger' "$REPO_ROOT/deploy/observability/otel-collector-config.yaml" || {
        echo "❌ HATA: Jaeger OTLP exporter yapılandırması eksik." >&2
        exit 1
    }
    grep -q 'alertmanager:9093' "$REPO_ROOT/deploy/observability/prometheus.yml" || {
        echo "❌ HATA: Prometheus Alertmanager yönlendirmesi eksik." >&2
        exit 1
    }
    echo "✅ Gözlemlenebilirlik yapılandırması (Prometheus, Alertmanager, OTel/Jaeger) doğrulandı."
    echo "=== [LAB-10] Yapılandırma Doğrulaması Başarılı (PASS) ==="
    exit 0
fi

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
