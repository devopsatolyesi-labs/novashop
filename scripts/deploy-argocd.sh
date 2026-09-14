#!/usr/bin/env bash
# ==============================================================================
# NovaShop — LAB-09 Argo CD GitOps Otomatik Kurulum ve Temizlik Betiği
# ==============================================================================
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

echo "===> [1/4] Argo CD Namespace ve Manifestoları Kuruluyor..."
kubectl create namespace argocd --dry-run=client -o yaml | kubectl apply -f -
kubectl apply --server-side --force-conflicts -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

echo "===> [2/4] Argo CD Sunucusunun Hazır Olması Bekleniyor..."
kubectl wait --for=condition=available --timeout=300s deployment/argocd-server -n argocd

echo "===> [3/4] Olası NodePort 30080 Çakışmaları Otomatik Temizleniyor..."
# LAB-06 manuel Helm kurulumundan kalan çakışan servisi temizle:
helm uninstall novashop -n novashop 2>/dev/null || true
kubectl delete svc novashop-ui -n novashop --ignore-not-found 2>/dev/null || true

echo "===> [4/4] Argo CD GitOps Application Uygulanıyor..."
kubectl apply -f "$REPO_ROOT/deploy/gitops/application.yaml"

echo ""
echo "======================================================================"
echo "🎉 Argo CD GitOps Başarıyla Kuruldu!"
echo "======================================================================"
ARGOCD_PASSWORD=$(kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" 2>/dev/null | base64 -d || echo "")
echo "Web UI Adresi: https://student100-argocd.devopsatolyesi.com veya https://localhost:8080"
echo "Kullanıcı Adı: admin"
echo "Admin Parola : ${ARGOCD_PASSWORD}"
echo "======================================================================"
