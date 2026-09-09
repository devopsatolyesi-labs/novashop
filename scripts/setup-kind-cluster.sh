#!/usr/bin/env bash
# NovaShop — Kind Küme Kurulum ve Helm Dağıtım Otomasyonu
set -euo pipefail

CLUSTER_NAME="novashop-cluster"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
CONFIG_FILE="$REPO_ROOT/deploy/k8s/kind-cluster-config.yaml"

echo "=== [M06] Kind Kubernetes Kümesi Kurulumu Başlatılıyor ==="

# 1. Gerekli Araçların Varlık Kontrolü
for tool in kind kubectl helm; do
    if ! command -v "$tool" >/dev/null 2>&1; then
        echo "❌ HATA: '$tool' komutu bulunamadı. Lütfen kurulumunu tamamlayın." >&2
        exit 1
    fi
done

# 2. Mevcut Küme Varsa Kontrol Et veya Yenisini Oluştur
if kind get clusters | grep -q "^${CLUSTER_NAME}$"; then
    echo "ℹ️ '${CLUSTER_NAME}' isimli küme zaten mevcut."
else
    echo "2. Çok düğümlü Kind kümesi oluşturuluyor (1 control-plane, 2 worker)..."
    kind create cluster --config "$CONFIG_FILE"
fi

# 3. Kümeyi ve Düğümleri Doğrula
kubectl cluster-info --context "kind-${CLUSTER_NAME}"
echo "Düğüm Durumları:"
kubectl get nodes -o wide

# 4. novashop Namespace Oluşturma
if ! kubectl get namespace novashop >/dev/null 2>&1; then
    echo "4. 'novashop' namespace oluşturuluyor..."
    kubectl create namespace novashop
fi

# 5. Helm Chart ile NovaShop Uygulamasını Dağıtma
echo "5. NovaShop Helm chart dağıtılıyor..."
helm upgrade --install novashop "$REPO_ROOT/charts/novashop" \
  --namespace novashop \
  --wait \
  --timeout 5m

# 6. Dağıtım Durumunu Doğrulama
echo "6. Dağıtılan kaynaklar listeleniyor..."
kubectl get all -n novashop

echo "=== [M06] Kind ve Helm Dağıtımı Başarıyla Tamamlandı! ==="
echo "Mağaza Erişimi: http://localhost:8888"
echo "Sağlık Kontrolü: http://localhost:8888/actuator/health"
