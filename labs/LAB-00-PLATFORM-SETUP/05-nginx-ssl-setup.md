# Platform Hazırlık 05 — Nginx Reverse Proxy ve SSL Yapılandırması

Ubuntu sunucusu üzerinde çalışan tüm araçları 80/443 portundan dış dünyaya açmak ve SSL sertifikasını sonlandırmak için Nginx kullanılır.

---

## 1. Nginx Kurulumu (Eğer kurulu değilse)

```bash
sudo apt update
sudo apt install -y nginx certbot python3-certbot-nginx
```

---

## 2. Reverse Proxy Yapılandırması

Aşağıdaki yapılandırmayı `/etc/nginx/sites-available/student-tools.conf` olarak kaydedin:

```nginx
# NovaShop UI -> 8888
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

# GitLab CE -> 8929
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

# Harbor Registry -> 18082
server {
    listen 80;
    server_name ~^(?<student>student\d+)-harbor\.devopsatolyesi\.com$;
    client_max_body_size 0;
    location / {
        proxy_pass http://127.0.0.1:18082;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}

# SonarQube -> 19000
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

# Jenkins -> 18080
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
```

---

## 3. Yapılandırmayı Etkinleştirme ve Test

```bash
sudo ln -sf /etc/nginx/sites-available/student-tools.conf /etc/nginx/sites-enabled/
sudo nginx -t
sudo systemctl reload nginx
```
