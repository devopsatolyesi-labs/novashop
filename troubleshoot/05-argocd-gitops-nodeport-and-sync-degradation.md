# 05 — Argo CD GitOps NodePort Çakışması ve Sync Degradation

## 1. Problem: "spec.ports[0].nodePort: 30080 already allocated"

### Semptom
Argo CD Web arayüzünde `novashop-gitops` uygulaması `OutOfSync` ve `Degraded` durumuna düşüyor. Senkronizasyon hatası detayı:
```text
one or more objects failed to apply, reason: Service "novashop-gitops-ui" is invalid: 
spec.ports[0].nodePort: 30080 already allocated
```

### Kök Neden
Laboratuvar akışında LAB-06 (Manuel Helm Dağıtımı) yapıldıktan sonra LAB-09 (Argo CD ile GitOps Dağıtımı) çalıştırılmıştır.
- LAB-06'da oluşturulan `novashop-ui` servisi, Kubernetes kümesindeki `30080` numaralı statik NodePort'u rezerve etmiştir.
- Argo CD, Git deposundaki Helm chart'ı `novashop-gitops` adıyla senkronize etmeye çalıştığında, yeni üretilen `novashop-gitops-ui` servisi de aynı `nodePort: 30080` portunu talep etmiştir.
- Kubernetes bir NodePort'u aynı anda iki farklı Service nesnesine tahsis edemez; bu nedenle Service oluşturma isteği API sunucusu tarafından reddedilmiştir.

### Çözüm
1. **Çakışan Eski Manuel Sürümün Kaldırılması:**
   ```bash
   helm uninstall novashop -n novashop
   ```
2. **Kalan Statik Servisin Temizlenmesi (Gerekiyorsa):**
   ```bash
   kubectl delete svc novashop-ui -n novashop --ignore-not-found
   ```
3. **Argo CD Senkronizasyonunu Tetikleme:**
   ```bash
   argocd app sync novashop-gitops --force --prune
   ```
   *Sonuç:* `novashop-gitops-ui` servisi `30080` portunu başarıyla devralmış ve sync tamamlanmıştır.

---

## 2. Problem: Var Olmayan İmaj Sebebiyle "ImagePullBackOff" ve App Degradation

### Semptom
Argo CD senkronizasyonu başarılı olmasına rağmen uygulama sağlığı `Degraded` olarak görünüyordu. Pod durumları:
```text
novashop-gitops-catalog-...   0/1   ImagePullBackOff   0   2m
```
Pod betimlemesinde: `Failed to pull image "retail-store-sample-catalog:v1.6.2": rpc error: code = NotFound`.

### Kök Neden
`charts/novashop/values.yaml` dosyasında catalog alt modülü için `retail-store-sample-catalog:v1.6.2` imajı tanımlanmıştı ancak bu tag yerel Harbor kayıt defterinde veya uzak repoda mevcut değildi. Kubernetes pod başlatamadığı için Argo CD sağlık denetleyicisi uygulamayı `Degraded` olarak işaretledi.

### Çözüm
1. İlgili servis `charts/novashop/values.yaml` içinde devre dışı bırakıldı (veya mevcut geçerli imaj referansıyla güncellendi):
   ```yaml
   catalog:
     enabled: false
   ```
2. Değişiklik Git'e commit edilip pushlandı.
3. Argo CD otomatik olarak yeni commit'i algıladı (`c30ed39`), catalog podunu sildi ve uygulama sağlığını **`Healthy`** durumuna getirdi.

---

## 3. Pratik İpuçları: Argo CD Parola ve Port-Forward

- **Yönetici İlk Parolasını Alma:**
  ```bash
  kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d; echo
  ```
- **Port-Forward ile Arka Planda UI Açma:**
  ```bash
  kubectl port-forward svc/argocd-server -n argocd 8080:443 --address 0.0.0.0 &
  ```
