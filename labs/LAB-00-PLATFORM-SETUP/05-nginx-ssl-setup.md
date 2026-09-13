# Platform Hazırlık 05 — Nginx Reverse Proxy ve SSL Yapılandırması

Ubuntu sunucusu üzerinde çalışan tüm DevOps araçlarını (`NovaShop UI`, `GitLab`, `Harbor`, `SonarQube`, `Jenkins`) standart HTTP/HTTPS (port 80 ve 443) üzerinden tek bir giriş noktasıyla dış dünyaya açmak ve SSL sertifikalarını sonlandırmak için Nginx kullanılır.

Bu rehber, sunucunuzda Nginx hiç kurulu olmasa bile sıfırdan adım adım kurulumu ve araç bazlı reverse proxy kurallarını açıklar.

---

## 🧭 Genel Bakış ve Alan Adı Eşleme Haritası

| Servis | İç Port | Alan Adı Formatı |
|---|:---:|---|
| **NovaShop UI** | `8888` | `https://studentXX-novashop.devopsatolyesi.com` |
| **GitLab CE** | `8929` | `https://studentXX-gitlab.devopsatolyesi.com` |
| **Harbor Registry** | `18082` | `https://studentXX-harbor.devopsatolyesi.com` |
| **SonarQube** | `19000` | `https://studentXX-sonarqube.devopsatolyesi.com` |
| **Jenkins** | `18080` | `https://studentXX-jenkins.devopsatolyesi.com` |

---

## 📋 Ana Yöntem: Adım Adım Manuel Kurulum

### Adım 1: Nginx ve Certbot Kurulumu

Sıfır Ubuntu makinesinde Nginx web sunucusunu ve Certbot SSL aracını yükleyin:

```bash
sudo apt update
sudo apt install -y nginx certbot python3-certbot-nginx
sudo systemctl enable --now nginx
```

Varsayılan karşılama sayfasını kaldırın:
```bash
sudo rm -f /etc/nginx/sites-enabled/default
```

---

### Adım 2: DevOps Araçları İçin Nginx Yapılandırmasını Oluşturma

Tüm servisler için proxy ayarlarını, WebSocket desteğini ve büyük imaj yüklemeleri için gerekli `client_max_body_size` kurallarını içeren konfigürasyon dosyasını oluşturun:

```bash
cat << 'NGINX_EOF' | sudo tee /etc/nginx/sites-available/student-tools.conf
# 1. NovaShop Web UI -> Port 8888
server {
    listen 80;
    server_name ~^(?<student>student\d+)-novashop\.devopsatolyesi\.com$;
    location / {
        proxy_pass http://127.0.0.1:8888;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}

# 2. GitLab CE -> Port 8929
server {
    listen 80;
    server_name ~^(?<student>student\d+)-gitlab\.devopsatolyesi\.com$;
    client_max_body_size 250M;
    location / {
        proxy_pass http://127.0.0.1:8929;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}

# 3. Harbor OCI Registry -> Port 18082
server {
    listen 80;
    server_name ~^(?<student>student\d+)-harbor\.devopsatolyesi\.com$;
    # Docker imaj yüklemelerinde boyut sınırı olmamalı:
    client_max_body_size 0;
    location / {
        proxy_pass http://127.0.0.1:18082;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}

# 4. SonarQube -> Port 19000
server {
    listen 80;
    server_name ~^(?<student>student\d+)-sonarqube\.devopsatolyesi\.com$;
    location / {
        proxy_pass http://127.0.0.1:19000;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}

# 5. Jenkins -> Port 18080 (WebSocket destekli)
server {
    listen 80;
    server_name ~^(?<student>student\d+)-jenkins\.devopsatolyesi\.com$;
    location / {
        proxy_pass http://127.0.0.1:18080;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";
    }
}
NGINX_EOF
```

---

### Adım 3: Yapılandırmayı Etkinleştirme ve Test

```bash
# 1. Sembolik link oluşturarak siteyi etkinleştirin
sudo ln -sf /etc/nginx/sites-available/student-tools.conf /etc/nginx/sites-enabled/

# 2. Sözdizimini test edin
sudo nginx -t

# 3. Nginx servisini yeniden yükleyin
sudo systemctl reload nginx
```

---

### Adım 4: SSL Sertifikası Yapılandırması

#### Yöntem A: Otomatik Let's Encrypt SSL (DNS Tanımlı İse)
Sunucunuza ait DNS kayıtları genel internete açıksa Certbot ile ücretsiz SSL alın:
```bash
sudo certbot --nginx -d studentXX-novashop.devopsatolyesi.com \
                    -d studentXX-gitlab.devopsatolyesi.com \
                    -d studentXX-harbor.devopsatolyesi.com \
                    -d studentXX-sonarqube.devopsatolyesi.com \
                    -d studentXX-jenkins.devopsatolyesi.com
```

#### Yöntem B: Yerel Test İçin Self-Signed (Kendinden İmzalı) Wildcard SSL
DNS'iniz genel internete açık değilse test ortamında HTTPS sağlamak için wildcard sertifika üretebilirsiniz:
```bash
sudo mkdir -p /etc/nginx/ssl
sudo openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
  -keyout /etc/nginx/ssl/wildcard.key \
  -out /etc/nginx/ssl/wildcard.crt \
  -subj "/CN=*.devopsatolyesi.com"
```

---

## ⚡ Alternatif Yöntem: Hızlı Kurulum (Fast-Track)

```bash
sudo apt update && sudo apt install -y nginx
sudo cp infra/nginx/student-tools.conf /etc/nginx/sites-available/ 2>/dev/null || true
sudo ln -sf /etc/nginx/sites-available/student-tools.conf /etc/nginx/sites-enabled/
sudo nginx -t && sudo systemctl restart nginx
```
