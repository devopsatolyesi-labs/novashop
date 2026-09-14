# 06 — Nginx Edge Reverse Proxy, Çapraz Yönlendirme ve WebSocket İzolasyonu

## 1. Problem: Cockpit URL'i Açıldığında NovaShop UI'ın Yüklenmesi (Cross-Routing)

### Semptom
Kullanıcı tarayıcısında `https://student100-cockpit.devopsatolyesi.com` adresine gittiğinde Cockpit Web Terminal arayüzü yerine NovaShop e-ticaret web sayfası açılıyordu.

### Kök Neden
1. Nginx yapılandırmasında ilk tanımlanan HTTPS sunucu bloğu (`NovaShop UI`), açıkça bir `default_server` belirlenmediği sürece varsayılan geri dönüş (catch-all) sunucusu gibi davranır.
2. Cockpit için ayrı bir `server` bloğu tanımlanmadığında veya `server_name` eşleşmesi eksik olduğunda, Nginx gelen isteği ilk HTTPS bloğuna (NovaShop `:8888`) yönlendiriyordu.
3. Ayrıca tanımsız veya yanlış yazılmış tüm alt alan adları NovaShop'a yönlenerek güvenlik ve izolasyon açığı oluşturuyordu.

### Çözüm
1. **İzole Varsayılan SSL Bloğu (Blackhole/404):**
   Nginx yapılandırmasının en başına tanımsız istekleri yakalayıp 404 döndüren katı bir `default_server` eklendi:
   ```nginx
   server {
       listen 443 ssl default_server;
       server_name _;

       ssl_certificate /etc/nginx/ssl/devops-training/origin.crt;
       ssl_certificate_key /etc/nginx/ssl/devops-training/origin.key;

       location / {
           default_type text/plain;
           return 404 "NovaShop DevOps Platform: Tanimlanmamis servis veya alan adi.\n";
       }
   }
   ```
2. **Cockpit İçin Özel HTTPS ve WebSocket Bloğu:**
   Cockpit Web Terminal `:9090` portunda TLS ve yoğun WebSocket trafiği kullanır:
   ```nginx
   server {
       listen 443 ssl;
       server_name student100-cockpit.devopsatolyesi.com;

       ssl_certificate /etc/nginx/ssl/devops-training/origin.crt;
       ssl_certificate_key /etc/nginx/ssl/devops-training/origin.key;

       location / {
           proxy_pass https://127.0.0.1:9090;
           proxy_ssl_verify off;
           proxy_buffering off;
           proxy_http_version 1.1;
           proxy_set_header Host $host;
           proxy_set_header X-Real-IP $remote_addr;
           proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
           proxy_set_header X-Forwarded-Proto https;
           proxy_set_header Upgrade $http_upgrade;
           proxy_set_header Connection $connection_upgrade;
       }
   }
   ```

---

## 2. Problem: Jenkins ve Kibana WebSocket / Chunked Transfer Bağlantı Kesintileri

### Semptom
Jenkins canlı log akışında (Console Output) veya Kibana Discover canlı tail ekranında bağlantı anlık olarak kopuyor ve `WebSocket connection failed` uyarısı veriyordu.

### Kök Neden
Nginx varsayılan olarak HTTP/1.0 ve proxy tamponlama (buffering) kullanır; bu durum uzun ömürlü WebSocket ve Server-Sent Events (SSE) bağlantılarını kesintiye uğratır.

### Çözüm
İlgili servis bloklarına `proxy_http_version 1.1` ve connection upgrade direktifleri eklendi:
```nginx
proxy_http_version 1.1;
proxy_set_header Upgrade $http_upgrade;
proxy_set_header Connection $connection_upgrade;
```
`nginx.conf` içinde `http` bloğuna map tanımlandı:
```nginx
map $http_upgrade $connection_upgrade {
    default upgrade;
    '' close;
}
```
