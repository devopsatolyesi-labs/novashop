# 08 — Kubernetes Kind Kümesi, Argo CD CRD Boyut Sınırı ve GitOps Dağıtımı

Bu doküman; yerel Kind Kubernetes kümesinde Argo CD kurulumu, 256KB CRD boyut aşımı çözümü ve GitOps senkronizasyonunu açıklar.

---

## 1. Karşılaşılan Sorunlar ve Hata Belirtileri

### Senaryo A: 256KB CRD Annotation Boyut Sınırı Hatası
- **Hata Çıktısı:**
  ```text
  The CustomResourceDefinition "applicationsets.argoproj.io" is invalid: 
  metadata.annotations: Too long: may not be more than 262144 bytes
  ```
- **Kök Neden:** Standart `kubectl apply -f install.yaml` komutu manifestoyu son uygulanan durum olarak `kubectl.kubernetes.io/last-applied-configuration` annotation'ına yazar. ApplicationSet CRD'si çok büyük olduğundan Kubernetes API sınırı olan 256KB'ı aşar.

### Senaryo B: Argo CD Web Paneline Dışarıdan Erişilememesi
- **Kök Neden:** Kind kümesi Docker konteyner ağı içinde çalıştığı için `argocd-server` ClusterIP servisi host dışından doğrudan erişilemez.

---

## 2. Adım Adım Kodla Çözüm

### 1. Server-Side Apply ile CRD Sınırını Aşma
Kubernetes API sunucusunun nesneyi sunucu tarafında yönetmesini sağlayarak annotation boyut sınırını bertaraf etme:
```bash
kubectl apply --server-side --force-conflicts -n argocd   -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
```

### 2. İlk Yönetici Parolasını Alma
```bash
ARGOCD_PASS=$(kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d)
echo "Argo CD Admin Parolası: $ARGOCD_PASS"
```

### 3. Kalıcı Port-Forward ve Nginx Ters Vekil
Argo CD HTTPS servisini Nginx üzerinden dış dünyaya açma:
```bash
# Systemd servisi kur ve başlat:
sudo systemctl enable --now argocd-portforward.service

# Cloudflare DNS A kaydı ekle:
# student100-argocd.devopsatolyesi.com -> 34.77.187.127
```

### 4. GitOps Application ve Self-Healing Tanımı
`deploy/gitops/application.yaml`:
```yaml
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: novashop-ui-gitops
  namespace: argocd
spec:
  project: default
  source:
    repoURL: 'https://github.com/devopsatolyesi-labs/novashop.git'
    targetRevision: main
    path: charts/novashop
  destination:
    server: 'https://kubernetes.default.svc'
    namespace: novashop
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
    syncOptions:
      - CreateNamespace=true
```

---

## 3. Doğrulama Komutları

```bash
# 1. Argo CD uygulama senkronizasyon durumunu sorgula:
kubectl get application novashop-ui-gitops -n argocd -o jsonpath='{.status.sync.status} - {.status.health.status}'

# 2. Canlı pod durumunu incele:
kubectl get pods -n novashop
```
*Beklenen Sonuç:* `Synced - Healthy`.
