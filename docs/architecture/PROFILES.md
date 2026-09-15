# NovaShop DevOps Store — Çalıştırma Profilleri ve Kaynak Bütçesi

Bu doküman, katılımcıların eğitim boyunca kullanacağı **2 vCPU, 16 GB RAM ve 50 GB disk** kapasiteli sanal sunucu (VM) ortamında sistemin stabil çalışmasını sağlamak amacıyla tanımlanmış **çalıştırma profillerini (execution profiles)** ve kaynak yönetim kurallarını açıklar.

---

## 1. Altın Kural: Profil İzolasyonu

> [!WARNING]
> **Tüm bileşenleri aynı anda çalıştırmak KESİNLİKLE YASAKTIR.**  
> GitLab CE, Jenkins, Harbor, SonarQube, Kind Kubernetes, ELK Stack ve NovaShop mikroservisleri aynı anda ayağa kaldırıldığında sistem belleği (16 GB) tükenecek, işletim sistemi `OOM-killer` tetikleyerek kritik süreçleri sonlandıracak veya sanal makine tamamen kilitlenecektir.

Her lab modülünde **yalnızca o modüle ait profil** aktif edilir. Bir sonraki profile geçmeden önce bir önceki profil durdurulmalı ve temizlenmelidir (`cleanup`).

---

## 2. Profil Envanteri ve Kaynak Bütçesi

| Profil Adı | İlgili Laboratuvar Modülü | Dahil Olan Servisler | Hedef CPU | Hedef RAM | Disk Tüketimi |
|---|---|---|---|---|---|
| **`starter`** | LAB-01, LAB-03 (Starter) | NovaShop UI (In-Memory Mock) | 0.5 vCPU | 512 MB | ~300 MB |
| **`compose-core`** | LAB-03, LAB-04 | UI, Catalog, MySQL (Catalog DB) | 1.0 vCPU | 1.5 GB | ~1.5 GB |
| **`compose-full`** | LAB-03 (Gelişmiş / Full) | UI, Catalog, Cart, Checkout, Orders, MySQL, DynamoDB-local, Redis, Postgres, RabbitMQ | 1.8 vCPU | 4.0 GB | ~4.5 GB |
| **`cicd-github`** | LAB-05 | Runner / Local Action Tools, ECR Proxy | 1.0 vCPU | 2.0 GB | ~3.0 GB |
| **`cicd-enterprise`** | LAB-07 | GitLab CE veya Jenkins + Harbor Registry | 1.8 vCPU | 8.0 GB | ~12.0 GB |
| **`security-gates`** | LAB-08 | SonarQube Server + PostgreSQL + Trivy | 1.5 vCPU | 4.0 GB | ~5.0 GB |
| **`k8s-core`** | LAB-06 | Kind Cluster (1 Control-Plane, 2 Worker) + NovaShop Core Helm | 1.8 vCPU | 6.0 GB | ~8.0 GB |
| **`gitops-argo`** | LAB-09 | Kind Cluster + Argo CD Controller/Server | 1.8 vCPU | 6.5 GB | ~8.5 GB |
| **`observability`** | LAB-10 | Prometheus, Grafana, Alertmanager, Jaeger, OTel Collector | 1.5 vCPU | 4.0 GB | ~6.0 GB |
| **`logging-elk`** | LAB-11 | Fluent Bit, Elasticsearch (Tek Düğüm), Kibana | 1.8 vCPU | 6.0 GB | ~10.0 GB |

---

## 3. Profil Yaşam Döngüsü ve Geçiş Kuralları

Kullanıcılar bir labdan diğerine geçerken aşağıdaki standart komut sırasını izlemelidir:

### 1. Mevcut Profili Durdurma ve Kaynakları Serbest Bırakma
```bash
# Docker Compose profilini durdur ve birimleri temizle
docker compose --profile <AKTIF_PROFIL> down -v

# Askıda kalan konteynerleri ve bellek önbelleğini temizle
docker system prune -f
```

### 2. Hedef Profili Başlatma
```bash
# Yalnızca hedeflenen profili arka planda başlat
docker compose --profile <HEDEF_PROFIL> up -d
```

### 3. Kaynak Kullanımını İzleme
```bash
# Konteyner bazlı anlık RAM ve CPU tüketimini izle
docker stats --no-stream
```

---

## 4. Konteyner Kaynak Sınırları Şablonu

Docker Compose tanımlarında her servis için bellek ve işlemci tavan değerleri zorunludur:

```yaml
services:
  ui:
    image: novashop-ui:v0.1.0
    deploy:
      resources:
        limits:
          cpus: '0.50'
          memory: 512M
        reservations:
          cpus: '0.25'
          memory: 256M

  catalog:
    image: novashop-catalog:v0.1.0
    deploy:
      resources:
        limits:
          cpus: '0.30'
          memory: 256M

  catalog-db:
    image: mariadb:10.11
    deploy:
      resources:
        limits:
          cpus: '0.50'
          memory: 512M
```

---

## 5. Acil Durum: Bellek Tükendiğinde Müdahale

Eğer sanal makinede terminal yanıt vermemeye başlar veya `docker` komutları `cannot allocate memory` hatası verirse:

```bash
# 1. Tüm çalışan Docker konteynerlerini acil durdur
docker kill $(docker ps -q) 2>/dev/null || true

# 2. Kullanılmayan ağ ve birimleri temizle
docker system prune -a --volumes -f

# 3. Swap ve RAM durumunu incele
free -h
```
