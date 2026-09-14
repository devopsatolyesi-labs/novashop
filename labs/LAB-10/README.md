# LAB-10-OBSERVABILITY — İleri Gözlemlenebilirlik: Prometheus, Grafana, OpenTelemetry, Jaeger ve SLO Yönetimi

---

### Amaç

NovaShop mikroservis ekosisteminde; OpenTelemetry (OTel) Collector ile dağıtık izleme (Distributed Tracing / Jaeger), Prometheus ile zaman serisi metrik toplama (RED/USE), Grafana ile görsel izleme panoları kurmak ve kontrollü bir alarm üreterek Hizmet Seviyesi Hedefleri (SLO - Service Level Objective) ve Hata Bütçesi (Error Budget) yönetimini doğrulamak.

---

### Kazanımlar

- Gözlemlenebilirliğin (Observability) üç temel direğini (Metrikler, İzler/Traces, Alarmlar) uygulamak.
- OpenTelemetry (OTel) standartları ile mikroservisler arasında uçtan uca istek akışını (Trace ID / Span) Jaeger üzerinde izlemek.
- Spring Boot Actuator ve Go Gin servislerinden `/actuator/prometheus` üzerinden RED (Rate, Errors, Duration) metriklerini toplamak.
- Grafana üzerinde NovaShop operasyonel panosu (Dashboard) tasarlamak.
- Alertmanager ile yapay bir hata yükü oluşturarak kontrollü alarm tetiklemek ve bildirim akışını teyit etmek.

---

### Ön koşullar

- **Önceki Lablar:** [LAB-03](../LAB-03/README.md) veya [LAB-06](../LAB-06/README.md) tamamlanmış olmalıdır.
- **Kaynak Gereksinimi:** `observability` profili (en az 2 vCPU, 4 GB boş RAM).
- **Yüklü Araçlar:** Docker Engine, Docker Compose, `curl`.

---

### Mimari

```mermaid
graph TD
    User([Kullanıcı / İstek Üretici]) -->|HTTP :8888| UI[NovaShop UI]
    UI -->|REST :8080| Catalog[Catalog Service]

    subgraph OpenTelemetry & Observability Katmanı
        UI -.->|OTLP Traces :4317| OTel[OpenTelemetry Collector]
        Catalog -.->|OTLP Traces :4317| OTel
        OTel --> Jaeger[Jaeger UI :16686<br/>Dağıtık İstek İzleme]

        Prometheus[Prometheus Server :9090] -->|Scrape :8080/actuator/prometheus| UI
        Prometheus -->|Scrape :8080/metrics| Catalog

        Prometheus --> Alertmanager[Alertmanager :9093<br/>SLO & Alarm Yönlendirme]
        Grafana[Grafana Dashboards :3000] -->|PromQL Sorguları| Prometheus
    end
```

---

### 🧭 Erişim Modelleri ve Kimlik Bilgileri (Credentials)

| Servis | Model B: Kurumsal DNS + SSL (1. Seçenek) | Model A: Doğrudan IP:Port (2. Seçenek) | Kullanıcı Adı | Varsayılan Parola |
| :--- | :--- | :--- | :---: | :---: |
| **Grafana Panosu** | `https://studentXX-grafana.devopsatolyesi.com` | `http://<UBUNTU_IP>:3000` | `admin` | `.env` içindeki `GRAFANA_ADMIN_PASSWORD` (`DevOps2026!`) |
| **Prometheus** | `https://studentXX-prometheus.devopsatolyesi.com` | `http://<UBUNTU_IP>:9091` | - | Kimlik doğrulaması yok (*Cockpit 9090 portunu kullandığı için 9091 ayrılmıştır*) |
| **Jaeger UI (Tracing)** | `https://studentXX-jaeger.devopsatolyesi.com` | `http://<UBUNTU_IP>:16686` | - | Kimlik doğrulaması yok |
| **Alertmanager** | - | `http://<UBUNTU_IP>:9093` | - | Kimlik doğrulaması yok |

---

### Adımlar

#### 1. Gözlemlenebilirlik Profilini Başlatma

İzleme altyapısını (`observability` profili) saf `docker compose` komutlarıyla ayağa kaldırın:

1. Yerel `.env` dosyasını oluşturun ve Grafana parolanızı belirleyin:
   ```bash
   test -f .env || cp config/project.env.example .env
   sed -i 's/<SET_A_LOCAL_SECRET>/DevOps2026!/g' .env
   chmod 600 .env
   ```

2. Saf `docker compose` komutuyla servisleri arka planda başlatın:
   ```bash
   docker compose --env-file .env -p novashop-observability -f deploy/observability/docker-compose.observability.yml up -d
   ```
   *(İsteğe bağlı helper betik: `bash scripts/compose-observability.sh up`)*

*Açıklama:* Bu stack, LAB-03'te oluşturulan `novashop-starter_default` ağına bağlanır; bu nedenle LAB-03 UI servisi önce çalışıyor olmalıdır.

3. **Servislerin Sağlık Durumunu Doğrulama:**
   ```bash
   docker compose -p novashop-observability -f deploy/observability/docker-compose.observability.yml ps
   ```

---

#### 2. Prometheus Metrik Toplama (Scraping) Kontrolü

Prometheus arayüzüne bağlanarak (`http://localhost:9090/targets` veya `student100-prometheus.devopsatolyesi.com/targets`) hedeflerin aktif (`UP`) olduğunu doğrulayın:

```bash
curl -s http://localhost:9090/api/v1/targets | jq -r '.data.activeTargets[] | "\(.labels.job): \(.health)"'
```
*Beklenen çıktı:* `cadvisor: up`, `node-exporter: up`, `novashop-ui: up`, `prometheus: up`.

---

#### 2.1. PromQL Derinlemesine Sorgulama: Table ve Graph Görünümleri

Prometheus Web Arayüzünde (`/graph`) ve Grafana **Explore** sekmesinde iki temel görünüm modu bulunur:

1. **Table (Anlık / Instant Vector) Görünümü:**
   - Belirli bir zaman anındaki (anlık snapshot) en güncel değerleri tablo olarak listeler.
   - Matematiksel karşılaştırmalar, scalar filtrelemeler (`== 0`, `> 80`) ve sistemin o andaki durumunu denetlemek için idealdir.
   - Örnek: `up{job=~"novashop-.*"}` sorgusu Table görünümünde her servisin o an çalışıp çalışmadığını (1 veya 0) net bir tablo olarak listeler.

2. **Graph (Zaman Serisi / Range Vector Trend) Görünümü:**
   - Metriğin seçilen zaman penceresi boyunca (örneğin son 15 dakika, 1 saat) nasıl değiştiğini çizgi grafiği ile gösterir.
   - `rate()`, `irate()`, `increase()` gibi zaman serisi türev fonksiyonları ve `histogram_quantile()` persentil hesaplamaları Graph görünümünde anlamlı dalgalanmalar ve trendler üretir.

**Pratik PromQL Sorgu Kütüphanesi:**

*A. RED Metrikleri (Rate, Errors, Duration — Uygulama Seviyesi):*
- **İstek Hızı (Rate - RPS):**
  ```promql
  sum by (uri) (rate(http_server_requests_seconds_count[1m]))
  ```
- **Hata Oranı (Errors - %5xx):**
  ```promql
  (sum(rate(http_server_requests_seconds_count{status=~"5.."}[1m])) / sum(rate(http_server_requests_seconds_count[1m]))) * 100
  ```
- **Yanıt Süresi (Duration - p95 & p99 Latency):**
  ```promql
  histogram_quantile(0.95, sum by (le) (rate(http_server_requests_seconds_bucket[5m])))
  ```

*B. Konteyner Kaynak Metrikleri (cAdvisor):*
- **Konteyner Başına CPU Kullanımı (%):**
  ```promql
  sum by (name) (rate(container_cpu_usage_seconds_total{name=~".+"}[1m])) * 100
  ```
- **Konteyner Çalışan Bellek (Working Set - MB):**
  ```promql
  container_memory_working_set_bytes{name=~".+"} / 1024 / 1024
  ```

*C. Host Altyapı Metrikleri (Node Exporter - USE Metodu):*
- **Sunucu Toplam CPU Kullanım Yüzdesi:**
  ```promql
  100 - (avg by (instance) (rate(node_cpu_seconds_total{mode="idle"}[2m])) * 100)
  ```
- **Kullanılabilir Bellek Oranı (%):**
  ```promql
  (node_memory_MemAvailable_bytes / node_memory_MemTotal_bytes) * 100
  ```
- **Kök Disk Boş Alan Yüzdesi:**
  ```promql
  (node_filesystem_avail_bytes{mountpoint="/"} / node_filesystem_size_bytes{mountpoint="/"}) * 100
  ```

---

#### 3. Jaeger Üzerinde Dağıtık İstek İzleme (Distributed Tracing)

Tarayıcıdan UI ana sayfasına birkaç istek gönderin veya curl ile trafik oluşturun:

```bash
for i in {1..10}; do curl -s http://localhost:8888/ > /dev/null; sleep 0.5; done
```

1. Tarayıcınızda `http://localhost:16686` (Jaeger UI) adresini açın.
2. **Service** açılır menüsünden `novashop-ui` servisini seçin ve **Find Traces** butonuna tıklayın.
3. Bir izi (Trace) açarak isteğin `UI` -> `Catalog` mikroservisleri arasındaki alt adımlarını (Spans), gecikme sürelerini (Latency) ve veritabanı bekleme sürelerini uçtan uca inceleyin.

---

#### 4. Grafana Üzerinde Metrik Panoları ve Hazır Dashboard İçe Aktarma

Tarayıcınızda `http://localhost:3000` (veya SSL proxy üzerinden `student100-grafana.devopsatolyesi.com`) adresine gidin. Kullanıcı adı: `admin`, parola: `.env` dosyasındaki `GRAFANA_ADMIN_PASSWORD` (`DevOps2026!`).

##### 4.1. Varsayılan Panolar:
1. **NovaShop — Microservices RED & Business Overview:** İstek hızı, HTTP 5xx hata yüzdesi, p95/p99 gecikme süreleri ve sepet/sipariş iş metrikleri.
2. **NovaShop — Docker Containers & Host Overview:** Konteyner CPU/RAM tüketimleri ve Host kaynak kullanım grafikleri.

##### 4.2. Grafana Resmi Kütüphanesinden Hazır Dashboard İçe Aktarma (Import):
Grafana topluluk ekosisteminde binlerce hazır pano ([grafana.com/dashboards](https://grafana.com/dashboards)) yer alır.

**En Çok Kullanılan Popüler Dashboard ID'leri:**
- **JVM (Micrometer) Dashboard:** `4701` (Spring Boot / Actuator metrikleri için altın standart)
- **Node Exporter Full:** `1860` (Sunucu OS, CPU, Disk, Ağ metrikleri)
- **Docker / cAdvisor Container Monitoring:** `893` veya `14282`

**Adım Adım Grafana UI Üzerinden İçe Aktarma (Import):**
1. Sol ana menüden **Dashboards** sekmesine tıklayın.
2. Sağ üstteki **New** butonuna basıp **Import** seçeneğini seçin (Doğrudan adres: `http://localhost:3000/dashboard/import`).
3. **Import via grafana.com** kutusuna Dashboard ID'sini yazın: `4701`.
4. **Load** butonuna tıklayın. Grafana dashboard metadata'sını otomatik çekecektir.
5. Açılan ekranda:
   - **Name:** `JVM (Micrometer) - NovaShop`
   - **Folder:** `NovaShop`
   - **Select a Prometheus data source:** Açılır kutudan tanımlı **`Prometheus`** veri kaynağını seçin.
6. **Import** butonuna basın. Spring Boot JVM bellek heap havuzları, garbage collection duraklamaları ve CPU yükü anında görselleşecektir.

> **💡 Otomasyon / Provisioning Notu:**
> Laboratuvar ortamımızda bu panolar manuel import gerektirmeden `deploy/observability/grafana/provisioning/dashboards/json/community-jvm-micrometer.json` dosyası olarak provizyonlanmıştır ve başlatıldığı anda hazır gelir.

---

#### 5. Kontrollü Alarm, SLO Hata Bütçesi İhlali ve Grafana Alerting

##### 5.1. Prometheus Alarm Kuralları (`alert.rules.yml`)
Prometheus üzerinde 3 ana alarm grubu aktiftir:
1. **novashop_slo_alerts:** HTTP 5xx hata oranı > %2, p95 yanıt süresi > 500ms, servis kesintisi (`up == 0`).
2. **container_resource_alerts:** Konteyner CPU > %85, Konteyner RAM > %85.
3. **host_infrastructure_alerts:** Host CPU > %85, Boş RAM < %15, Boş Disk < %15, Scrape hedefi kapalı.

Prometheus alarm durumunu izlemek için `http://localhost:9091/alerts` sayfasına gidin. Bir alarm kuralı 3 durumda bulunabilir:
- `Inactive`: Eşik aşılmadı, durum normal.
- `Pending`: Eşik aşıldı, `for` süresi boyunca eşiğin kalıcı olup olmadığı test ediliyor.
- `Firing`: Eşik süresi doldu, alarm resmen tetiklendi ve Alertmanager'a gönderildi.

##### 5.2. Grafana Üzerinde Yeni Alarm Kuralı Oluşturma (Adım Adım)
Grafana UI üzerinden görsel olarak alarm tanımlamak için:
1. Sol menüden **Alerting > Alert rules** sayfasına gidin ve **+ New alert rule** butonuna tıklayın.
2. **1. Rule name:** `NovaShop-UI-HighErrorRate` yazın.
3. **2. Set a query and condition:**
   - **Datasource:** `Prometheus` seçin.
   - **Query (A):** `sum(rate(http_server_requests_seconds_count{status=~"5.."}[1m])) / sum(rate(http_server_requests_seconds_count[1m])) * 100`
   - **Condition (C) - Threshold:** `Input: A`, `IS ABOVE: 2` (SLO %2 hata oranı).
4. **3. Set evaluation behavior:**
   - **Folder:** `NovaShop Alerts`
   - **Evaluation group:** `novashop-evaluation-1m`, **Evaluation interval:** `1m`, **Pending period:** `1m`.
5. **4. Add details:**
   - **Summary:** `NovaShop UI 5xx Hata Bütçesi İhlal Edildi`
   - **Severity label:** `critical`
6. **Save and exit** butonuna basarak alarmı kaydedin.

##### 5.3. Yapay Hata Yükü Oluşturma ve Alarm Tetikleme Testi
```bash
# Bilerek var olmayan veya geçersiz endpoint'lere yoğun istek göndererek 5xx/4xx hatası oluştur
for i in {1..50}; do curl -s http://localhost:8888/api/invalid-endpoint > /dev/null & done
```

**Alarm Durumunu İnceleme:**
1. Prometheus panelinde `http://localhost:9091/alerts` sekmesinde `HighHttpErrorRate` kuralının `Pending` -> `Firing` geçişini izleyin.
2. Alertmanager panelinde (`http://localhost:9093`) alarm bildiriminin üretildiğini teyit edin.
3. Grafana **Alerting > Alert rules** altında kuralın durumunun `Firing (Kırmızı)` olduğunu gözlemleyin.

---

#### 6. Otomatik Laboratuvar Doğrulama Betiğini Çalıştırma

Prometheus metrik endpoint'lerini, JVM metriklerini ve dağıtık izleme yeteneklerini otomatik test betiği ile doğrulayın:

```bash
bash scripts/verify/verify-lab-10.sh 8888 localhost
```
*Beklenen çıktı:*
```text
=== [LAB-10] Gözlemlenebilirlik Doğrulama Başlatılıyor ===
1. Actuator Prometheus metrik endpoint'i test ediliyor...
✅ /actuator/prometheus üzerinden JVM metrikleri başarıyla alınıyor.
✅ HTTP istek gecikme ve sayaç metrikleri (http_server_requests_seconds) mevcut.
✅ Dağıtık izleme (Trace) metrikleri etkin.
=== [LAB-10] Gözlemlenebilirlik Doğrulama Tamamlandı ===
```

---

### Troubleshooting

#### Senaryo 1: Jaeger'da İzler (Traces) Görünmüyor
- **Belirti:** Jaeger UI'da `novashop-ui` servisi listelenmiyor.
- **Muhtemel Neden:** Uygulamanın `MANAGEMENT_TRACING_SAMPLING_PROBABILITY=1.0` ayarının yapılmamış olması veya OTel Collector portunun (4317/4318) erişilemez olması.
- **Güvenli Çözüm:** Spring Boot ortam değişkenini kontrol edin: `docker exec -it novashop-ui printenv | grep TRACING`.

#### Senaryo 2: Grafana Prometheus'a Bağlanamıyor (`HTTP Error 502 / Connection refused`)
- **Belirti:** Grafana dashboard'larında `No data` görünmesi.
- **Teşhis:** Grafana iç ağdan `http://prometheus:9090` adresini çözebiliyor mu kontrol edin.
- **Güvenli Çözüm:** Docker Compose ağında `novashop-observability-net` köprüsünün tanımlı olduğunu teyit edin.

---

### Güvenlik Notu

1. **Metrik Uç Noktalarının İzolasyonu:**
   - `/actuator/prometheus` ve `/metrics` verileri hassas sistem mimarisi bilgisi içerebilir; dış internete (`0.0.0.0/0`) açılmamalı, yalnızca izleme sunucusunun IP'sine izin verilmelidir.
2. **Kişisel Veri (PII) Temizliği:**
   - Dağıtık izleme (Trace) verilerine kullanıcı şifreleri, kredi kartı numaraları veya gizli token'lar span attribute olarak eklenemez.

---

### Cleanup / Rollback

```bash
# Observability altyapısını durdur ve birimleri temizle
bash scripts/compose-observability.sh down -v
```

---

### Pratik Uygulama Görevi

1. Prometheus kural dosyasına (`alert.rules.yml`) p99 gecikmesi 500ms'yi aşarsa tetiklenecek `HighResponseLatency` alarmı ekleyin.
2. Konfigürasyonu yeniden yükleyin (`curl -X POST http://localhost:9090/-/reload`) ve kuralın panelde listelendiğini doğrulayın.
