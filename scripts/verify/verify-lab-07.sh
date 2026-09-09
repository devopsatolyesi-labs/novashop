#!/usr/bin/env bash
# NovaShop — LAB-07 Kurumsal CI/CD (GitLab, Jenkins, Harbor) Doğrulama Betiği
set -e

HARBOR_HOST="${1:-}"

echo "=== [LAB-07] Kurumsal CI/CD ve Harbor Doğrulama Başlatılıyor ==="

# 1. Pipeline Tanım Dosyaları Kontrolü
REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"

FOUND_PIPELINE=false
if [ -f "$REPO_ROOT/Jenkinsfile" ]; then
    echo "✅ Jenkinsfile bildirimsel pipeline tanımı mevcut."
    FOUND_PIPELINE=true
fi

if [ -f "$REPO_ROOT/.gitlab-ci.yml" ]; then
    echo "✅ .gitlab-ci.yml GitLab CI pipeline tanımı mevcut."
    FOUND_PIPELINE=true
fi

if [ -d "$REPO_ROOT/.github/workflows" ]; then
    echo "✅ GitHub Actions iş akışları mevcut."
    FOUND_PIPELINE=true
fi

if [ "$FOUND_PIPELINE" = false ]; then
    echo "ℹ️ Bilgi: Kök dizinde Jenkinsfile veya .gitlab-ci.yml henüz oluşturulmamış."
fi

# 2. Canlı Harbor Registry Kontrolü (Argüman Verilmişse)
if [ -n "$HARBOR_HOST" ]; then
    echo "2. Harbor canlı servis kontrolü yapılıyor: $HARBOR_HOST"
    PING_RESP=$(curl -s --connect-timeout 5 "http://${HARBOR_HOST}/api/v2.0/ping" 2>/dev/null || echo "")
    if [ "$PING_RESP" = "pong" ]; then
        echo "✅ Harbor API ping başarılı (pong)."
    else
        echo "⚠️ UYARI: Harbor API /api/v2.0/ping yanıt vermedi. Port/IP kontrol edin."
    fi

    HEALTH_RESP=$(curl -s --connect-timeout 5 "http://${HARBOR_HOST}/api/v2.0/health" 2>/dev/null || echo "")
    if echo "$HEALTH_RESP" | grep -q '"status":"healthy"'; then
        echo "✅ Harbor genel sağlık durumu: healthy."
    fi
else
    echo "ℹ️ Harbor canlı denetimi için kullanım: $0 <HARBOR_HOST:PORT> (Örn: $0 localhost:80)"
fi

echo "=== [LAB-07] Kurumsal CI/CD Doğrulama Tamamlandı ==="
