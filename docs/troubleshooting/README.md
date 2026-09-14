# NovaShop DevOps — Kapsamlı Sorun Giderme (Troubleshooting) Dizin Rehberi

Bu dizin; NovaShop platformunda karşılaşılan tüm kritik mimari, ağ, güvenlik, CI/CD ve Kubernetes problemlerinin kök neden analizlerini ve adım adım kodlanmış çözümlerini içerir.

---

## 📚 Konu Başlıkları ve Kılavuzlar

| No | Kılavuz Dosyası | Kapsanan Konular ve Hata Senaryoları |
|---|---|---|
| **01** | [01-git-sync-ve-conflict-yonetimi.md](./01-git-sync-ve-conflict-yonetimi.md) | Çoklu repo senkronizasyonu, GitHub UI çakışması (`fetch first`), `rebase` ve merge conflict çözümü. |
| **02** | [02-cloudflare-dns-ve-ssl-proxy.md](./02-cloudflare-dns-ve-ssl-proxy.md) | Çoklu öğrenci DNS çakışmasını engelleme, Cloudflare API otomasyonu, Dual-Access (IP:Port + SSL DNS). |
| **03** | [03-docker-ve-sistem-kaynaklari.md](./03-docker-ve-sistem-kaynaklari.md) | RAM bütçesi ve OOMKilled (Exit 137), port haritası, systemd kalıcı port yönlendirme servisleri. |
| **04** | [04-harbor-registry-ve-tag-immutability.md](./04-harbor-registry-ve-tag-immutability.md) | Harbor robot hesapları (`$` kaçışı), API v2 ping formatı, `v*` Tag Immutability koruması. |
| **05** | [05-jenkins-otomasyon-ve-sihirbaz-bypass.md](./05-jenkins-otomasyon-ve-sihirbaz-bypass.md) | Jenkins Setup Wizard bypass (`runSetupWizard=false`), BCrypt şifre sabitleme, CSRF Crumb REST API. |
| **06** | [06-gitlab-ve-runner-entegrasyonu.md](./06-gitlab-ve-runner-entegrasyonu.md) | Admin bildirimleri kapatma (signup restrictions, Web IDE single origin), GitLab 16+ GraphQL Runner. |
| **07** | [07-sonarqube-v26-ve-quality-gates.md](./07-sonarqube-v26-ve-quality-gates.md) | SonarQube v26 Community, PostgreSQL PBKDF2-SHA512 şifre güncelleme, Maven plugin ve Quality Gate. |
| **08** | [08-kubernetes-kind-ve-argocd-gitops.md](./08-kubernetes-kind-ve-argocd-gitops.md) | Argo CD CRD 256KB annotation aşımı (`--server-side`), GitOps self-healing, Kind cluster port mapping. |

---

## ⚡ Hızlı Teşhis ve Acil Durum Kontrol Listesi

```bash
# 1. Sanal makine bellek ve yük durumunu kontrol edin:
free -h && uptime

# 2. Konteyner sağlık durumlarını listeleyin:
docker ps --format "table {{.Names}}	{{.Status}}	{{.Ports}}"

# 3. Kubernetes kümesi düğüm ve pod durumlarını sorgulayın:
kubectl get nodes,pods -A

# 4. Genel servis erişimlerini test edin:
for port in 8888 8929 18080 18082 19000 8080 30080; do
  echo -n "Port $port: "
  curl -s -o /dev/null -w "%{http_code}
" "http://127.0.0.1:$port" || echo "FAILED"
done
```
