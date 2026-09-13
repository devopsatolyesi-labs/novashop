# NovaShop Eğitim Platformu — Altyapı, Port ve DNS Mimari Planı

> **Hedef:** Her öğrencinin ve eğitmenin Ubuntu sunucusunda bağımsız, çakışmasız ve hem doğrudan IP ile hem de kurumsal DNS/SSL ile erişilebilir bir DevOps ortamı sağlamak.

---

## 1. Genel Mimari ve Erişim Felsefesi

Tüm araçlar öğrencinin/eğitmenin **Ubuntu sunucusu** üzerinde çalışır. İki farklı erişim modeli desteklenir:

1. **Model A: Doğrudan IP:Port Erişimi (Hızlı / DNS'siz)**
   * Nginx veya DNS konfigürasyonu yapmaya vakti olmayan ya da yapmak istemeyen öğrenciler için.
   * `http://<UBUNTU_IP>:<PORT>` ile servise doğrudan bağlanılır.
   * Güvenlik duvarından (Cloud Provider Firewall / UFW) ilgili portun açık olması yeterlidir.

2. **Model B: Kurumsal DNS + Wildcard SSL Erişimi (Prod-Ready)**
   * Sunucu önünde Nginx Reverse Proxy (80/443) çalışır.
   * Cloudflare üzerinde `*.devopsatolyesi.com` Wildcard SSL aktiftir.
   * Her öğrenciye `studentXX-<tool>.devopsatolyesi.com` alt alan adı atanır.
   * Nginx bu domaini yakalayarak dahili porta iletir (Reverse Proxy).

> [!TIP]
> **Neden `studentXX-<tool>.devopsatolyesi.com`?**  
> Cloudflare standart Wildcard SSL sertifikası (`*.devopsatolyesi.com`) sadece **tek seviyeli** subdomainleri kapsar.  
> `student01-jenkins.devopsatolyesi.com` tek seviyeli olduğu için ek ücret ödemeden doğrudan SSL ile korunur.  
> Eğer `jenkins.student01.devopsatolyesi.com` yapılsaydı iki seviyeli olacağı için SSL geçersiz kalırdı.

---

## 2. Port ve DNS Tahsis Matrisi

| Servis | Protokol / Konteyner Portu | Host Portu (Doğrudan IP) | DNS Alan Adı (Nginx SSL) | Amaç & Açıklama |
| :--- | :---: | :---: | :--- | :--- |
| **Nginx Reverse Proxy** | `80 / 443` | `80 / 443` | `*.devopsatolyesi.com` | Let's Encrypt / Cloudflare SSL sonlandırma |
| **NovaShop Web UI** | `8080` (Dahili) | `8888` | `studentXX-novashop.devopsatolyesi.com` | E-ticaret ön yüz uygulaması (Spring Boot) |
| **Cockpit Web UI** | `9090` | `9090` | `studentXX-cockpit.devopsatolyesi.com` | Linux web tabanlı sunucu yönetim kokpiti |
| **GitLab CE Web** | `80` (Dahili) | `8929` | `studentXX-gitlab.devopsatolyesi.com` | Kurumsal Git ve CI/CD platformu |
| **GitLab SSH** | `22` (Dahili) | `2224` | `studentXX-gitlab.devopsatolyesi.com:2224` | Git push/pull için alternatif SSH portu |
| **Harbor Registry Web** | `80` (Dahili) | `18082` | `studentXX-harbor.devopsatolyesi.com` | OCI Container Registry & Trivy tarayıcı |
| **Harbor Notary** | `4443` | `18443` | `studentXX-notary.devopsatolyesi.com` | İmaj imzalama ve güvenlik |
| **SonarQube Web** | `9000` (Dahili) | `19000` | `studentXX-sonarqube.devopsatolyesi.com` | Statik Kod Analizi (SAST) & Quality Gates |
| **Jenkins Web** | `8080` (Dahili) | `18080` | `studentXX-jenkins.devopsatolyesi.com` | Jenkins Controller Web UI |
| **Jenkins Agent JNLP** | `50000` | `50000` | `studentXX-jenkins.devopsatolyesi.com:50000` | Jenkins Worker Agent bağlantı portu |
| **Kind K8s Ingress (HTTP)** | `80` | `18081` | `studentXX-k8s.devopsatolyesi.com` | Kind kümesi Traefik Ingress Controller HTTP |
| **Kind K8s Ingress (HTTPS)** | `443` | `18444` | `studentXX-k8s-ssl.devopsatolyesi.com` | Kind kümesi Traefik Ingress Controller HTTPS |
| **Argo CD Web UI** | `8080` (Dahili) | `18083` | `studentXX-argocd.devopsatolyesi.com` | Kubernetes GitOps CD kontrol paneli |
| **Prometheus** | `9090` (Dahili) | `19090` | `studentXX-prometheus.devopsatolyesi.com` | Metrik toplama (Cockpit 9090 ile çakışmaz!) |
| **Grafana** | `3000` (Dahili) | `13000` | `studentXX-grafana.devopsatolyesi.com` | Metrik görselleştirme & SLO panoları |

---

## 3. Eğitmen Sunucusu Bilgileri (`student100`)

* **VM Adı:** `ecommerce-cockpit-01`
* **Statik Dış IP:** `34.77.187.127`
* **Bölge:** GCP `europe-west1-b`
* **Kullanıcı:** `devopsatolyesi` (veya `hakan`)
* **Özel Subdomain:** `student100-*.devopsatolyesi.com`
  * UI: `https://student100-novashop.devopsatolyesi.com` (ve `https://novashop.devopsatolyesi.com`)
  * Cockpit: `https://student100-cockpit.devopsatolyesi.com`
  * GitLab: `https://student100-gitlab.devopsatolyesi.com`
  * Harbor: `https://student100-harbor.devopsatolyesi.com`
  * SonarQube: `https://student100-sonarqube.devopsatolyesi.com`
  * Jenkins: `https://student100-jenkins.devopsatolyesi.com`

---

## 4. Nginx Reverse Proxy Yapılandırma Şablonu

Ubuntu sunucusunda `/etc/nginx/sites-available/student-tools.conf` olarak yerleştirilecek şablon:

```nginx
# Örnek: student01 (veya student100) için Nginx Reverse Proxy
# /etc/nginx/sites-available/student-tools.conf

# 1. NovaShop UI (Port 8888)
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

# 2. GitLab CE (Port 8929)
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

# 3. Harbor Registry (Port 18082)
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

# 4. SonarQube (Port 19000)
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

# 5. Jenkins (Port 18080)
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

# 6. Grafana (Port 13000)
server {
    listen 80;
    server_name ~^(?<student>student\d+)-grafana\.devopsatolyesi\.com$;

    location / {
        proxy_pass http://127.0.0.1:13000;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}
```
