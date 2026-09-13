# Eğitmen Rehberi — Cloudflare DNS ve Full SSL Proxy Otomasyonu

Bu rehber; eğitmenlerin öğrencilere ait Ubuntu sunucuları için Cloudflare üzerinde DNS A kayıtlarını (`studentXX-<service>.devopsatolyesi.com`), turuncu bulut (CDN / Proxied) modunu ve Cloudflare Zone SSL "Full" ayarını saniyeler içinde otomatik olarak açmasını açıklar.

---

## 🔑 1. Gerekli Cloudflare Bilgileri ve Tanımlamalar

Bu otomasyonun çalışabilmesi için 2 adet bilgiye ihtiyaç vardır:

1. **`CLOUDFLARE_ZONE_ID`:**
   * Cloudflare paneline giriş yapın -> `devopsatolyesi.com` alan adını seçin.
   * Sağ alt köşedeki **Overview** sekmesinde **Zone ID** değerini kopyalayın.

2. **`CLOUDFLARE_API_TOKEN`:**
   * Cloudflare paneli -> Sağ üstteki Profil simgesi -> **My Profile** -> **API Tokens**.
   * **Create Token** -> **Edit zone DNS** şablonunu seçin:
     * **Permissions:**
       * `Zone` - `DNS` - `Edit`
       * `Zone` - `Zone Settings` - `Edit` (SSL Full modunu otomatik açmak için)
       * `Zone` - `Zone` - `Read`
     * **Zone Resources:** `Include` -> `Specific zone` -> `devopsatolyesi.com`
   * Token'ı oluşturup kopyalayın.

---

## ⚙️ 2. GitLab CI / GitHub Actions Secret ve Değişken Tanımları

### GitLab İçin:
* Proje paneli -> **Settings** -> **CI/CD** -> **Variables** -> **Add Variable**:
  * **`CLOUDFLARE_API_TOKEN`** (Type: Variable, Flags: Masked, Protected: Opsiyonel)
  * **`CLOUDFLARE_ZONE_ID`** (Type: Variable)

### GitHub İçin:
* Proje paneli -> **Settings** -> **Secrets and variables** -> **Actions** -> **Repository secrets**:
  * **`CLOUDFLARE_API_TOKEN`**
  * **`CLOUDFLARE_ZONE_ID`**

---

## 🚀 3. Otomasyonu Çalıştırma Yöntemleri

### Yöntem A: Terminalden / Doğrudan CLI ile Çalıştırma (En Hızlı)

Sunucunuzda veya kendi bilgisayarınızda ortam değişkenlerini verip betiği çalıştırın:

```bash
export CLOUDFLARE_API_TOKEN="your_cloudflare_api_token"
export CLOUDFLARE_ZONE_ID="your_zone_id"

# 1. Tek bir öğrenci için DNS ve SSL açma:
./scripts/instructor/cloudflare-dns.sh apply student01 20.12.13.11 "novashop,gitlab,harbor,sonarqube,jenkins"

# 2. Birden fazla öğrenci için toplu çalıştırma (CSV dosyası ile):
# students.csv formatı:
# student01,20.12.13.11
# student02,20.12.13.12
# student100,54.12.34.56
./scripts/instructor/cloudflare-dns.sh batch students.csv

# 3. Lab bittiğinde kayıtları silme:
./scripts/instructor/cloudflare-dns.sh delete student01
```

---

### Yöntem B: GitLab CI/CD Pipeline Üzerinden Tetikleme

1. GitLab projesinde sol menüden **Build** -> **Pipelines** sayfasına gidin.
2. Sağ üstteki **Run pipeline** butonuna tıklayın.
3. Değişkenler (Variables) alanına değerleri girin:
   * **`STUDENT_ID`:** `student100` (veya öğrenci kodu)
   * **`STUDENT_IP`:** `20.12.13.11` (Öğrencinin sunucu dış IP adresi)
   * **`SERVICES`:** `novashop,gitlab,harbor,sonarqube,jenkins`
4. **Run pipeline** butonuna basın.

Pipeline tamamlandığında çıktı konsolunda tüm yeşil kilitli HTTPS linkleri listelenecektir:
```text
🎉 İşlem Tamamlandı! Oluşturulan HTTPS URL'leri:
🔗 https://student100-novashop.devopsatolyesi.com
🔗 https://student100-gitlab.devopsatolyesi.com
🔗 https://student100-harbor.devopsatolyesi.com
🔗 https://student100-sonarqube.devopsatolyesi.com
🔗 https://student100-jenkins.devopsatolyesi.com
```

---

### Yöntem C: GitHub Actions Üzerinden Tetikleme

1. **Actions** sekmesine gidin.
2. Sol menüden **Cloudflare DNS Automation** iş akışını seçin.
3. **Run workflow** butonuna tıklayıp açılan formda `student_id`, `student_ip` ve `services` bilgilerini girip onaylayın.

---

## 🎯 4. Öğrenci Tarafında Ne Yapılacak?

Eğitmen bu DNS kayıtlarını açtıktan sonra öğrenciye sadece şu komutu çalıştırmasını söylemeniz yeterlidir:

```bash
cd ~/novashop
sudo bash infra/nginx/setup-ssl-edge.sh student100
```

Bu komut öğrencinin sunucusunda yerel wildcard sertifikasını açar ve tüm servisleri Cloudflare üzerinden HTTPS olarak yayına verir!
