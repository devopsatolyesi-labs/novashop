# 02 — Cloudflare DNS Proxy, Origin SSL ve Dual-Access Modeli

Bu doküman; Cloudflare DNS yönetimi, ters vekil sunucu (Nginx) yapılandırması ve çoklu öğrenci ortamlarında DNS çakışmalarının engellenmesi mimarisini açıklar.

---

## 1. Karşılaşılan Sorunlar ve Hata Belirtileri

### Senaryo A: Çoklu Yapay Zeka / Öğrenci Ortamında DNS Çakışması
- **Hata Belirtisi:** `devopsatolyesi.com` zone'unda başka bir laboratuvar veya öğrenci çalışırken ana domain veya genel ayarlar değiştirildiğinde tüm öğrencilerin erişiminin kopması.
- **Kural İhlali:** Root domain (`devopsatolyesi.com`) veya zone genelindeki SSL/TLS ayarlarının değiştirilmeye çalışılması.

### Senaryo B: Cloudflare Proxied Erişiminde 522 / 521 Hatası
- **Hata Çıktısı:** `Cloudflare 522 Connection Timed Out` veya `521 Web Server Is Down`.
- **Kök Neden:** VM üzerindeki Nginx servisinin ilgili portu dinlememesi veya Google Cloud Firewall kurallarında 80/443 portunun kısıtlanması.

---

## 2. Adım Adım Kodla Çözüm

### 1. Güvenli Alan Adı Kuralı (DNS Isolation)
Tüm DNS kayıtları istisnasız olarak öğrencinin tekil ID'si ile öneklenmelidir:
`student100-<servis>.devopsatolyesi.com`

### 2. Cloudflare API ile Otomatik DNS A Kaydı Oluşturma
Manuel panele girmeden, API üzerinden tekil kayıt açma betiği:
```bash
CF_TOKEN="<CLOUDFLARE_API_TOKEN>"
ZONE_ID="25d95256b65efd93ea3de7df1aaab798"
SUBDOMAIN="student100-argocd"
TARGET_IP="34.77.187.127"

# Mevcut kaydı kontrol et, yoksa POST ile oluştur
curl -s -X POST "https://api.cloudflare.com/client/v4/zones/${ZONE_ID}/dns_records"   -H "Authorization: Bearer ${CF_TOKEN}"   -H "Content-Type: application/json"   --data "{"type":"A","name":"${SUBDOMAIN}","content":"${TARGET_IP}","ttl":1,"proxied":true}"
```

### 3. Nginx Çift Erişim (Dual-Access) Konfigürasyonu
Öğrencilerin hem yerel IP (`34.77.187.127:<PORT>`) hem de kurumsal HTTPS alan adı (`student100-*.devopsatolyesi.com`) üzerinden sorunsuz çalışabilmesi için Nginx ters vekil blokları tanımlanır:

```nginx
# Örnek: Argo CD Ters Vekil Bloğu
server {
    listen 80;
    server_name student100-argocd.devopsatolyesi.com;

    location / {
        proxy_pass https://127.0.0.1:8080;
        proxy_ssl_verify off;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto https;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";
    }
}
```

---

## 3. Doğrulama Komutları

```bash
# DNS kaydının IP çözümlemesini test et:
dig +short student100-argocd.devopsatolyesi.com

# HTTP/2 SSL yanıtını doğrula:
curl -s -o /dev/null -w "%{http_code}" https://student100-argocd.devopsatolyesi.com
```
*Beklenen Sonuç:* `200` HTTP dönüş kodu.
