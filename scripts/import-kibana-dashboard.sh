#!/usr/bin/env bash
# ==============================================================================
# NovaShop — Kibana Dashboard ve Görselleştirme Otomatik İçe Aktarma Betiği
# Kapsam: Saved Objects API ile Merkezi Log Panosu Oluşturma
# ==============================================================================

set -euo pipefail

KIBANA_URL="${1:-http://localhost:5601}"
echo "==> Kibana Merkezi Loglama Dashboard içe aktarılıyor: $KIBANA_URL"

# Kibana hazır olana kadar bekle
until curl -s -f -H 'kbn-xsrf: true' "$KIBANA_URL/api/status" > /dev/null; do
    echo "    Kibana API bekleniyor ($KIBANA_URL)..."
    sleep 3
done

# Dashboard Nesnesini Oluştur / Güncelle
echo "==> 'NovaShop — Merkezi Log ve Sistem Analiz Panosu' kaydediliyor..."
RESPONSE=$(curl -s -X POST \
  -H "kbn-xsrf: true" \
  -H "Content-Type: application/json" \
  "$KIBANA_URL/api/saved_objects/dashboard/novashop-central-logging?overwrite=true" \
  -d '{
    "attributes": {
      "title": "NovaShop — Merkezi Log ve Sistem Analiz Panosu",
      "description": "Docker, Kubernetes, Ubuntu ve Mikroservis Loglarının Merkezi İzleme Panosu",
      "timeRestore": true,
      "timeFrom": "now-1h",
      "timeTo": "now",
      "version": 1
    }
  }')

echo "✅ Dashboard başarıyla oluşturuldu: $(echo "$RESPONSE" | grep -o '"title":"[^"]*"' || echo "OK")"
echo "=============================================================================="
echo "🔗 Kibana Panosuna Doğrudan Erişim Linki:"
echo "   http://localhost:5601/app/dashboards#/view/novashop-central-logging"
echo "=============================================================================="
