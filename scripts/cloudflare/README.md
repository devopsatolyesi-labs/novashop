# Cloudflare DNS Otomasyon Rehberi (Eğitmen Aracı)

Bu araç, eğitim sınıfındaki öğrencilerin VM IP adreslerini tek bir CSV dosyasından okuyarak Cloudflare üzerinde gerekli tüm `studentXX-*` alt alan adı kayıtlarını (A Record) saniyeler içinde otomatik olarak oluşturur veya günceller.

---

## 1. Hangi Kayıtları Oluşturur?

Her öğrenci için aşağıdaki 8 adet DNS A-kaydı oluşturulur:
* `studentXX-novashop.devopsatolyesi.com` -> `<VM_IP>`
* `studentXX-gitlab.devopsatolyesi.com` -> `<VM_IP>`
* `studentXX-harbor.devopsatolyesi.com` -> `<VM_IP>`
* `studentXX-sonarqube.devopsatolyesi.com` -> `<VM_IP>`
* `studentXX-jenkins.devopsatolyesi.com` -> `<VM_IP>`
* `studentXX-argocd.devopsatolyesi.com` -> `<VM_IP>`
* `studentXX-grafana.devopsatolyesi.com` -> `<VM_IP>`
* `studentXX-cockpit.devopsatolyesi.com` -> `<VM_IP>`

---

## 2. Yerel Terminalden Çalıştırma

### Adım 1: CSV Dosyasını Düzenleyin
`scripts/cloudflare/students.csv` dosyasına öğrencilerin ID ve IP adreslerini ekleyin:

```csv
# student_id,vm_ip
student01,34.77.10.11
student02,34.77.10.12
student100,34.77.187.127
```

### Adım 2: Cloudflare API Token'ı Belirleyin ve Çalıştırın
```bash
export CLOUDFLARE_API_TOKEN="<SIZIN_CLOUDFLARE_API_TOKENINIZ>"
python3 scripts/cloudflare/sync_dns.py scripts/cloudflare/students.csv
```

---

## 3. GitLab CI / GitHub Actions Üzerinden Tek Tıkla Çalıştırma (Manual Workflow)

GitLab veya GitHub arayüzünden **CI/CD Pipelines -> Run Pipeline** (veya Actions -> Run Workflow) diyerek:
* `STUDENT_ID`: `student05`
* `VM_IP`: `34.77.20.15`

parametrelerini girip tek tuşla tüm kayıtları açabilirsiniz.
