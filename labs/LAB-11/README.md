# LAB-11-CENTRALIZED-LOGGING — Merkezi Loglama: Fluent Bit, Elasticsearch, Kibana ve Trace-ID Korelasyonu

---

### Amaç

NovaShop mikroservis ekosisteminde; Fluent Bit günlük (log) toplayıcısı, Elasticsearch arama motoru ve Kibana görselleştirme arayüzü ile merkezi bir loglama mimarisi kurmak, yapılandırılmış (JSON) log akışını sağlamak ve kontrollü bir üretim hatasını `trace_id` korelasyonu ile Kibana üzerinde saniyeler içinde tespit edip doğrulamak.

---

### Kazanımlar

- Dağıtık mikroservis mimarilerinde merkezi log toplama, ayrıştırma (parsing) ve indeksleme prensiplerini uygulamak.
- Hafif ve yüksek performanslı log ileticisi **Fluent Bit** konfigürasyonunu (Input, Filter, Parser, Output) yapılandırmak.
- Java 21 / Spring Boot ve Go servislerinde standart JSON log formatı ve Logstash şablonu uygulamak.
- Dağıtık izleme (Distributed Tracing / OTel) `trace_id` ve `span_id` değerlerini log kayıtlarına enjekte ederek (MDC - Mapped Diagnostic Context) log-iz korelasyonunu sağlamak.
- Kibana üzerinde KQL (Kibana Query Language) ile arama yapmak ve operasyonel log panosu tasarlamak.

---

### Ön koşullar

- **Önceki Lablar:** [LAB-03](../LAB-03/README.md) ve [LAB-10](../LAB-10/README.md) tamamlanmış olmalıdır.
- **Kaynak Gereksinimi:** `logging-elk` profili (en az 2 vCPU, 6 GB boş RAM).
- **Yüklü Araçlar:** Docker Engine, Docker Compose, `curl`.

---

### Mimari

```mermaid
graph TD
    User([Kullanıcı / İstek Üretici]) -->|İstek Gönderimi| UI[NovaShop UI]
    UI -->|Hata Üreten İstek!| Catalog[Catalog Service]

    subgraph Log Üretimi ve İletimi
        UI -->|Fluentd Driver :24224 MDC: trace_id| FluentBit[Fluent Bit Log Forwarder]
        Catalog -->|Fluentd Driver :24224 MDC: trace_id| FluentBit
    end

    subgraph Merkezi Loglama Altyapısı logging-elk profili
        FluentBit -->|Parse JSON & Index| ES[(Elasticsearch 8.x<br/>Index: novashop-logs-*)]
        ES --> Kibana[Kibana Web UI :5601<br/>Log Discovery & Korelasyon]
    end

    Engineer([SRE / DevOps Mühendisi]) -->|KQL: trace_id = xxx| Kibana
```

---

### Kullanılan placeholder'lar

| Placeholder | Anlamı | Örnek Biçim |
|---|---|---|
| `<KIBANA_URL>` | Kibana erişim adresi | `http://localhost:5601` |
| `<ES_URL>` | Elasticsearch HTTP endpoint'i | `http://localhost:9200` |
| `<TRACE_ID>` | Korelasyon için kullanılan 32 karakterlik iz kimliği | `4bf92f3577b34da6a3ce929d0e0e4736` |

---

### Adımlar

#### 1. Merkezi Loglama Profilini Başlatma

Docker Compose ile `logging-elk` profilini başlatın:

```bash
docker compose --profile logging-elk up -d
```
*Beklenen çıktı:* Elasticsearch, Kibana ve Fluent Bit konteynerlerinin `Up` duruma geçmesi.

**Elasticsearch Küme Sağlığını Doğrulama:**
```bash
curl -s http://localhost:9200/_cluster/health | grep -o '"status":"[a-z]*"'
```
*Beklenen çıktı:* `"status":"green"` veya `"status":"yellow"` (tek düğüm için sarı normaldir).

---

#### 2. Fluent Bit Yapılandırma Dosyası (`fluent-bit.conf`)

Fluent Bit'in Docker mikroservis loglarını Fluentd forward protokolü (port 24224) ile alıp JSON ayrıştırması yaparak Elasticsearch'e ilettiği kuralları inceleyin:

```ini
[SERVICE]
    Flush        1
    Daemon       Off
    Log_Level    info
    Parsers_File parsers.conf

# 1. Giriş: Docker Konteyner Loglarını Oku (Fluentd Forward Driver)
[INPUT]
    Name             forward
    Listen           0.0.0.0
    Port             24224
    Tag              novashop.*

# 2. Filtre: JSON Loglarını Çözümle ve Trace-ID Korelasyonu Yap
[FILTER]
    Name             parser
    Match            *
    Key_Name         log
    Parser           json
    Reserve_Data     On

# 3. Çıkış: Logları Elasticsearch'e İndeksle
[OUTPUT]
    Name             es
    Match            *
    Host             elasticsearch
    Port             9200
    Index            novashop-logs
    Type             _doc
    Logstash_Format  On
    Logstash_Prefix  novashop-logs
    Suppress_Type_Name On
    Trace_Error      On
```

*Not:* Docker Compose servislerinin loglarını Fluent Bit'e iletmesi için `deploy/logging/docker-compose.logging-driver.yml` overlay dosyası (`logging.driver: "fluentd"`) kullanılır:
```bash
docker compose -f src/app/docker-compose.yml -f deploy/logging/docker-compose.logging-driver.yml up -d
```

---

#### 3. Log Kayıtlarında Trace-ID ve Yapılandırılmış JSON Formatı

Spring Boot ve Go mikroservisleri konsola düz metin yerine yapılandırılmış JSON log basar. Örnek bir kayıt:

```json
{
  "@timestamp": "2026-09-09T12:30:45.123Z",
  "level": "ERROR",
  "service": "novashop-ui",
  "thread": "http-nio-8080-exec-3",
  "trace_id": "4bf92f3577b34da6a3ce929d0e0e4736",
  "span_id": "00f067aa0ba902b7",
  "message": "Failed to retrieve product details from catalog service",
  "exception": "java.net.ConnectException: Connection refused"
}
```
*Açıklama:* `trace_id` alanı OpenTelemetry izleyicisi tarafından otomatik olarak MDC (Mapped Diagnostic Context) üzerinden her log satırına eklenir.

---

#### 4. Kontrollü Hata Simülasyonu ve Trace-ID Yakalama

Kasıtlı olarak hata oluşturan bir istek gönderin ve dönen HTTP yanıt başlıklarından `traceparent` veya hata logunu yakalayın:

```bash
# 1. Hatalı istek gönder
curl -s -i http://localhost:8888/api/catalog/products/invalid-uuid | grep -E "(HTTP|trace)"
```

---

#### 5. Kibana Üzerinde Hata Tespiti ve Korelasyon Doğrulaması

1. Tarayıcınızda `http://localhost:5601` (Kibana) adresini açın.
2. **Management > Stack Management > Data Views (Index Patterns)** sayfasına gidin.
3. `novashop-logs-*` desenini ekleyin ve zaman alanı olarak `@timestamp` seçin.
4. **Discover** sekmesine gidin.
5. Arama çubuğuna yakalanan `trace_id` değerini yapıştırın:
   ```kql
   trace_id: "4bf92f3577b34da6a3ce929d0e0e4736"
   ```
6. **Sonuç:** Tek bir arama ile hem `novashop-ui` servisinin attığı hata logunu hem de arka plandaki `catalog` servisinin veritabanı hata kaydını kronolojik sırada yan yana görüntüleyin.

---

#### 6. Otomatik Laboratuvar Doğrulama Betiğini Çalıştırma

Log korelasyon kalıplarını ve Elasticsearch küme durumunu otomatik test betiği ile doğrulayın:

```bash
bash scripts/verify/verify-lab-11.sh localhost:9200
```
*Beklenen çıktı:*
```text
=== [LAB-11] Merkezi Günlükleme Doğrulama Başlatılıyor ===
1. Uygulama loglarında Trace-ID / Span-ID korelasyon kontrolü...
✅ Kaynak kodda dağıtık log korelasyonu (traceId / spanId) kalıbı mevcut.
2. Elasticsearch canlı cluster durumu test ediliyor...
=== [LAB-11] Merkezi Günlükleme Doğrulama Tamamlandı ===
```

---

### Troubleshooting

#### Senaryo 1: Elasticsearch Yetersiz Bellek / Çökme (`Exit Code 137`)
- **Belirti:** Elasticsearch başladıktan hemen sonra kapanıyor.
- **Muhtemel Neden:** JVM heap alanının çok yüksek tutulması veya sistem RAM'inin tükenmesi.
- **Güvenli Çözüm:** `ES_JAVA_OPTS="-Xms512m -Xmx512m"` ile bellek kullanımını sınırlandırın.

#### Senaryo 2: Kibana'da Loglar Görünmüyor (`No results found`)
- **Belirti:** Discover sekmesinde log akışı yok.
- **Teşhis:** Elasticsearch indeksini kontrol edin: `curl -s http://localhost:9200/_cat/indices?v`.
- **Güvenli Çözüm:** Zaman filtresini (Time Filter) "Last 15 minutes" olarak ayarlayın ve Fluent Bit loglarını inceleyin: `docker logs novashop-fluent-bit`.

---

### Güvenlik Notu

1. **Hassas Veri Maskeleme (Log Sanitization):**
   - Müşteri parolaları, kredi kartı numaraları ve kimlik bilgileri loglara açık metin yazılamaz; Fluent Bit regex filtreleri veya Logback encoder ile maskelenmelidir (`***MASKED***`).
2. **Log Saklama ve Silme (Retention):**
   - Disk alanının dolmaması için Elasticsearch Index Lifecycle Management (ILM) ile 7 günden eski loglar otomatik silinir.

---

### Cleanup / Rollback

```bash
# Loglama altyapısını durdur ve birimleri temizle
docker compose --profile logging-elk down -v
```

---

### Pratik Uygulama Görevi

1. Kibana üzerinde yalnızca `level: "ERROR"` olan logları listeleyen özel bir filtre oluşturun.
2. Bu filtrenin sonucunu "Hata Sayacı" (Error Metrics) görselleştirmesi olarak yeni bir Dashboard'a kaydedin.
