# NovaShop DevOps Store

> **From Code to Cloud** — DevOps Atölyesi Uygulamalı Eğitim Projesi

NovaShop DevOps Store, tek bir e-ticaret uygulamasının modern DevOps ve Cloud-Native teslim zinciri boyunca adım adım nasıl olgunlaştığını gösteren yaşayan eğitim platformudur:

`plan → code → review → test → quality → security → package → registry → deploy → verify → observe → respond → improve`

---

## 🏗️ Mimari ve Bileşenler

Uygulama, mikroservis mimarisine sahip çok dilli (polyglot) modern bir e-ticaret platformudur:

```mermaid
graph TD
    Client([Web Tarayıcı / Mobil İstemci]) -->|HTTP :8888 / :8080| UI[NovaShop UI Storefront<br/>Java 21 / Spring Boot / Thymeleaf]
    
    UI -->|REST / API| Catalog[Catalog Service<br/>Go / Gin]
    UI -->|REST / API| Cart[Cart Service<br/>Java / Spring Boot]
    UI -->|REST / API| Checkout[Checkout Service<br/>Node.js / Express]
    UI -->|REST / API| Orders[Orders Service<br/>Java / Spring Boot]
    
    Catalog -->|SQL :3306| CatDB[(Catalog DB<br/>MySQL / MariaDB)]
    Cart -->|NoSQL :8000| CartDB[(Cart DB<br/>DynamoDB / Local)]
    Orders -->|SQL :5432| OrdersDB[(Orders DB<br/>PostgreSQL)]
    Orders -->|AMQP :5672| RabbitMQ>RabbitMQ Mesaj Kuyruğu]
    Checkout -->|Cache :6379| Redis[(Checkout Cache<br/>Redis)]
```

### Servis Envanteri

| Servis | Teknoloji / Dil | Port | Görev |
|---|---|---|---|
| **UI** | Java 21 / Spring Boot / Thymeleaf | 8080 (Host 8888) | Mağaza ön yüzü, ürün vitrini ve API aggregator |
| **Catalog** | Go / Gin | 8080 (Host 8081) | Ürün kataloğu ve kategori sorgulama API'si |
| **Cart** | Java 21 / Spring Boot | 8080 (Host 8082) | Kullanıcı sepeti ve ürün ekleme API'si |
| **Orders** | Java 21 / Spring Boot | 8080 (Host 8083) | Sipariş oluşturma ve asenkron kuyruk yönetimi |
| **Checkout** | Node.js / Express | 8080 (Host 8085) | Ödeme ve sipariş tamamlama orkestrasyonu |

---

## 🚀 Hızlı Başlangıç (Starter Profil)

NovaShop UI, arka plan servisleri hazır olmadığında otomatik olarak **in-memory mock** modunda çalışır. Böylece harici veritabanları kurmadan arayüzü hemen test edebilirsiniz.

### Ön Koşullar
- Docker yüklü bir sistem (Ubuntu 22.04+ önerilir)

### 1. NovaShop UI Starter İmajını İnşa Edin
M01 aşamasında uyarlanan kurumsal marka kimliği, DevOps ürün kataloğu ve favicon'u içeren yerel container imajını oluşturun:
```bash
docker build -t novashop-ui:v0.1.0 src/ui
```

### 2. Starter Container'ı Çalıştırın
```bash
docker run -d --name novashop-ui -p 8888:8080 novashop-ui:v0.1.0
```

### 3. Sağlık ve Marka Doğrulaması (Smoke Test)
Container'ın ayağa kalktığını ve NovaShop başlığının döndüğünü doğrulayın:
```bash
# Sağlık kontrolü
curl -f http://localhost:8888/actuator/health

# Marka kontrolü
curl -s http://localhost:8888/ | grep -o "NovaShop DevOps Store"
```
*Beklenen Çıktı:* `{"status":"UP"}` ve `NovaShop DevOps Store`

### 4. Tarayıcıda İnceleyin
Tarayıcınızdan şu adrese gidin:
```text
http://localhost:8888
```

*(İsteğe bağlı referans: Orijinal upstream imajı `public.ecr.aws/aws-containers/retail-store-sample-ui:1.6.2` adresindedir; ancak NovaShop markasını içermez.)*

### 5. Durdurun ve Temizleyin
```bash
docker stop novashop-ui && docker rm novashop-ui
```

## 🏛️ Mimari ve Güvenlik Dokümantasyonu

- [Mimari Genel Bakış ve Ağ Topolojisi](docs/architecture/OVERVIEW.md) — Mikroservis envanteri, kullanıcı akışları ve port izolasyonu.
- [Güvenlik Temel İlkeleri (Security Baseline)](docs/architecture/SECURITY_BASELINE.md) — Secret yönetimi, non-root container ve anti-pattern yasakları.
- [Çalıştırma Profilleri ve Kaynak Bütçesi](docs/architecture/PROFILES.md) — D-008 kaynak kuralları ve profil izolasyonu.

---

## 📚 Eğitim Yol Haritası ve Laboratuvarlar

1. [LAB-01: Git Temelleri, Feature Branch ve Merge Conflict Çözümü](docs/labs/LAB-01-GIT-GITHUB.md)
2. [LAB-02: AWS Temelleri: VPC, Public/Private Subnet, EC2, RDS ve TLS Doğrulaması](docs/labs/LAB-02-AWS-BASICS.md)
3. [LAB-03: Dockerfile Optimizasyonu, Non-Root İmaj ve Docker Compose](docs/labs/LAB-03-DOCKER-COMPOSE.md)
4. [LAB-04: AWS 3-Tier Dağıtım: EC2 Compose, Private RDS ve Nginx TLS](docs/labs/LAB-04-AWS-3TIER.md)
5. [LAB-05: GitHub Actions CI/CD Pipeline (OIDC, AWS ECR ve Otomatik Rollback)](docs/labs/LAB-05-GITHUB-ACTIONS.md)
6. [LAB-06: Kubernetes Temelleri, Kind Çok Düğümlü Küme ve Helm Paketleme](docs/labs/LAB-06-KUBERNETES-HELM.md)
7. [LAB-07: Kurumsal CI Platformu (GitLab CE, Jenkins Pipeline ve Harbor Registry)](docs/labs/LAB-07-ENTERPRISE-CICD.md)
8. [LAB-08: DevSecOps Güvenlik Kapıları (SonarQube SAST, Trivy SCA, Secret Scan ve SBOM)](docs/labs/LAB-08-SECURITY-GATES.md)
9. [LAB-09: Argo CD ile Deklaratif GitOps Dağıtımı ve Self-Healing](docs/labs/LAB-09-ARGOCD-GITOPS.md)
10. [LAB-10: İleri Gözlemlenebilirlik (Prometheus, Grafana, OpenTelemetry, Jaeger ve SLO)](docs/labs/LAB-10-OBSERVABILITY.md)
11. [LAB-11: Merkezi Loglama (Fluent Bit → Elasticsearch → Kibana ve Trace-ID Korelasyonu)](docs/labs/LAB-11-CENTRALIZED-LOGGING.md)
12. [LAB-12: Altyapı Otomasyonu (Terraform Modülleri, Cloud-Init ve Idempotency)](docs/labs/LAB-12-TERRAFORM-IAC.md)
13. [LAB-13 (Bonus): AWS EKS Kurumsal Platform Dağıtımı, IRSA ve Güvenilirlik Yönetimi](docs/labs/LAB-13-EKS-ENTERPRISE.md)

---

## 📜 Lisans ve Kaynak Atfı

- NovaShop DevOps Store, AWS Containers Retail Store Sample App (`https://github.com/aws-containers/retail-store-sample-app`) projesinden eğitim amacıyla uyarlanmıştır.
- Orijinal kodlar Amazon.com, Inc. or its affiliates mülkiyetinde olup **MIT-0** ([LICENSE](LICENSE)) lisansı altındadır.
- Detaylı bağımlılık ve kaynak atıf bilgileri için [UPSTREAM.md](UPSTREAM.md) dosyasını inceleyebilirsiniz.
