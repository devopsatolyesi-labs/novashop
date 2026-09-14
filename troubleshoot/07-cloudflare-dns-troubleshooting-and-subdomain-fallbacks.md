# 07 — Cloudflare DNS Yönetimi ve Subdomain Fallback Stratejisi

## 1. Problem: Yeni Servisler İçin Cloudflare DNS Kayıtlarının Bulunamaması (NXDOMAIN)

### Semptom
Kullanıcı `student100-kibana.devopsatolyesi.com` veya `student100-elastic.devopsatolyesi.com` adresine erişmek istediğinde tarayıcı `DNS_PROBE_FINISHED_NXDOMAIN` hatası veriyordu:
```bash
dig +short student100-kibana.devopsatolyesi.com
# Çıktı: (boş - DNS kaydı yok)
```
Sunucu üzerinde Kibana (`:5601`) ve Elasticsearch (`:9200`) servisleri sağlıklı ve çalışır durumda olmasına rağmen harici internetten erişilemiyordu.

### Kök Neden
1. GitHub Actions üzerindeki otomatik Cloudflare DNS provizyon iş akışı, hesap ödeme limiti (`recent account payments have failed or your spending limit needs to be increased`) sebebiyle çalıştırılamadı.
2. Bu nedenle yeni eklenen servis alt alan adları (`student100-kibana`, `student100-elastic`, `student100-jaeger`) Cloudflare DNS tablosuna otomatik olarak yazılamadı.

---

## 2. Çözüm ve Fallback Stratejisi

### Adım 1: Aktif ve Çözümlenen Alt Alan Adlarının Tespiti
Mevcut Cloudflare bölgesinde daha önceden tanımlanmış ve sunucu IP'sine yönlendirilmiş aktif kayıtlar tarandı:
```bash
for prefix in app1 app2 k8s-app1 kind k8s cockpit novashop gitlab harbor sonarqube jenkins prometheus grafana; do
  res=$(dig +short student100-${prefix}.devopsatolyesi.com | tr '\n' ' ')
  [ -n "$res" ] && echo "student100-${prefix} -> $res"
done
```
*Bulgu:* `student100-app1.devopsatolyesi.com` ve `student100-k8s-app1.devopsatolyesi.com` kayıtlarının Cloudflare üzerinde aktif ve geçerli SSL sertifikasına sahip olduğu doğrulandı.

### Adım 2: Nginx Üzerinde Çift Yönlü Alias Eşlemesi
Nginx yapılandırmasında (`infra/nginx/student-tools.conf`), çalışan alt alan adları hedef servislere alias olarak eklendi:
```nginx
# Kibana Log Analitiği -> Port 5601
server {
    listen 443 ssl;
    server_name student100-kibana.devopsatolyesi.com student100-app1.devopsatolyesi.com;
    ...
    proxy_pass http://127.0.0.1:5601;
}

# Elasticsearch API -> Port 9200
server {
    listen 443 ssl;
    server_name student100-elastic.devopsatolyesi.com student100-k8s-app1.devopsatolyesi.com;
    ...
    proxy_pass http://127.0.0.1:9200;
}
```

### Sonuç ve Kazanımlar
1. **Sıfır Bekleme ile Anında Erişim:** Öğrenciler DNS yayılmasını veya Cloudflare dashboard müdahalesini beklemeden `https://student100-app1.devopsatolyesi.com` üzerinden Kibana'ya, `https://student100-k8s-app1.devopsatolyesi.com` üzerinden Elasticsearch'e SSL güvencesiyle anında erişti.
2. **Geriye Dönük Uyumluluk:** İleride Cloudflare paneline `student100-kibana` kaydı eklendiğinde hiçbir Nginx ayarını değiştirmeye gerek kalmadan her iki alan adı da paralel olarak çalışacaktır.

---

## 3. Alternatif Yerel Çözüm: `/etc/hosts` Eşlemesi

Eğer hiçbir subdomain bulunmuyorsa, yerel bilgisayarın `/etc/hosts` (veya Windows'ta `C:\Windows\System32\drivers\etc\hosts`) dosyasına sunucunun statik dış IP'si eklenerek DNS bağımlılığı anında aşılabilir:
```text
34.77.187.127 student100-kibana.devopsatolyesi.com student100-elastic.devopsatolyesi.com
```
