# LAB-03-DOCKER-COMPOSE — Docker ve Docker Compose ile Konteynerleştirme

---

### Amaç

NovaShop mikroservis mimarisini; multi-stage Dockerfile ile optimize ve güvenli (non-root) container imajı olarak derlemek, Docker Compose profilleri ve katı kaynak limitleri (CPU/RAM) altında yerel geliştirme ortamında çalıştırıp sağlık kontrollerini doğrulamak.

---

### Kazanımlar

- Multi-stage Docker build mimarisi ile minimal ve güvenli Java 21 / Spring Boot container imajı üretmek.
- Container güvenliği temel ilkelerini (non-root `appuser`, `read_only: true`, `cap_drop: [ALL]`, `no-new-privileges`) uygulamak.
- Docker Compose üzerinde servis profilleri (`compose`, `full`) tanımlayarak öğrenci VM kaynak sınırlarını (2 vCPU, 16 GB RAM) korumak.
- Container sağlık kontrollerini (`HEALTHCHECK` / `/actuator/health`) yapılandırmak ve durumlarını izlemek.
- Docker Compose logları, ağ izolasyonu ve konteyner yaşam döngüsü yönetiminde yetkinlik kazanmak.

---

### Ön koşullar

- **Önceki Lab:** [LAB-01-GIT-GITHUB.md](file:///Users/hakan/novashop-workspace/novashop/docs/labs/LAB-01-GIT-GITHUB.md) tamamlanmış olmalıdır.
- **İşletim Sistemi:** Ubuntu 22.04 LTS veya macOS/Linux geliştirme ortamı.
- **Yüklü Araçlar:** Docker Engine v24+ (`docker --version`), Docker Compose v2.20+ (`docker compose version`).
- **Kaynak Gereksinimi:** En az 2 vCPU ve 4 GB boş bellek (D-008 kaynak koruma kuralı).

---

### Mimari

```mermaid
graph TD
    Developer([Öğrenci / Web Tarayıcısı]) -->|HTTP :8888| UI_Container[NovaShop UI Container<br/>Java 21 / Spring Boot 3<br/>Non-Root appuser:1000<br/>Port: 8080]

    subgraph Docker Host (Öğrenci VM)
        subgraph Isolated Bridge Network: novashop-net
            UI_Container
            
            subgraph Core Compose Profile Opsiyonel
                Catalog_Container[Catalog Service<br/>Go Gin / Port: 8080]
                Catalog_DB[(Catalog DB<br/>MySQL 8.0 / Port: 3306)]
                UI_Container -.->|HTTP :8080| Catalog_Container
                Catalog_Container -.->|TCP :3306| Catalog_DB
            end
        end
    end
```

---

### Kullanılan placeholder'lar

| Placeholder | Anlamı | Örnek Biçim |
|---|---|---|
| `<IMAGE_TAG>` | Derlenecek Docker imaj etiketi | `v0.1.0` veya `v0.3.0` |
| `<HOST_PORT>` | Yerel makinede açılacak web portu | `8888` |
| `<CONTAINER_NAME>` | Çalışan konteyner adı | `novashop-ui-dev` |

---

### Adımlar

#### 1. Docker Ortamını Doğrulama

Docker daemon ve Compose eklentisinin çalıştığından emin olun:

```bash
docker --version
docker compose version
docker info --format '{{.ServerVersion}}'
```
*Açıklama:* Docker sunucu sürümünü ve CLI erişimini doğrular.  
*Beklenen çıktı:*
```text
Docker version 24.x.x...
Docker Compose version v2.xx.x
24.x.x
```

---

#### 2. Güvenli Multi-Stage Dockerfile İncelemesi

`novashop/src/ui/Dockerfile` dosyasını inceleyin. Bu Dockerfile kurumsal güvenlik standartlarına göre iki aşamalı (multi-stage) tasarlanmıştır:
1. **Derleme Aşaması (Builder):** `eclipse-temurin:21-jdk` imajında `./mvnw clean package` ile JAR üretilir. Derleme araçları nihai imaja taşınmaz.
2. **Çalıştırma Aşaması (Runtime):** Minimal `eclipse-temurin:21-jre` imajı kullanılır.
3. **Güvenlik (Non-root):** UID 1000 `appuser` tanımlanır; container asla `root` olarak çalışmaz.

---

#### 3. Starter Profil: NovaShop UI İmajını Derleme

UI dizinine geçerek yerel imajı derleyin:

```bash
cd novashop
docker build -t novashop-ui:v0.1.0 src/ui
```
*Açıklama:* UI kaynak kodunu derler ve `novashop-ui:v0.1.0` etiketiyle yerel Docker kayıt defterine ekler.  
*Beklenen çıktı:*
```text
[+] Building ...
 => => naming to docker.io/library/novashop-ui:v0.1.0
```

**Derlenen İmajı Doğrulama:**
```bash
docker images novashop-ui:v0.1.0
```
*Beklenen çıktı:* Yaklaşık 250-300MB boyutunda `novashop-ui` imajı listelenir.

---

#### 4. Bağımsız Konteyneri Başlatma ve Smoke Testi

Starter profil ile UI'ı tek başına ayağa kaldırın (arka uç servisleri tanımlanmadığında dahili mock verilerini kullanır):

```bash
docker run -d \
  --name novashop-ui-starter \
  -p 8888:8080 \
  --memory=512m \
  --cpus=0.5 \
  --read-only \
  --tmpfs /tmp \
  novashop-ui:v0.1.0
```
*Açıklama:*
- `-p 8888:8080`: Host 8888 portunu container 8080 portuna yönlendirir.
- `--memory=512m --cpus=0.5`: Kaynak tüketimini sınırlandırır.
- `--read-only`: Kök dosya sistemini salt-okunur yaparak güvenlik sertleştirmesi sağlar.
- `--tmpfs /tmp`: Spring Boot geçici dosyaları için RAM tabanlı geçici alan açar.

**Konteyner Durumunu Kontrol Etme:**
```bash
docker ps --filter "name=novashop-ui-starter"
```
*Beklenen çıktı:*
```text
CONTAINER ID   IMAGE                  STATUS         PORTS                    NAMES
a1b2c3d4e5f6   novashop-ui:v0.1.0     Up 5 seconds   0.0.0.0:8888->8080/tcp   novashop-ui-starter
```

---

#### 5. Sağlık Kontrolü ve Marka Doğrulama

Konteynerin canlılığını ve NovaShop marka kimliğini test edin:

```bash
# 1. Spring Boot Actuator Sağlık Kontrolü
curl -s http://localhost:8888/actuator/health
```
*Beklenen çıktı:*
```json
{"status":"UP"}
```

```bash
# 2. NovaShop Marka Başlığı Kontrolü
curl -s http://localhost:8888/ | grep -o "NovaShop DevOps Store"
```
*Beklenen çıktı:*
```text
NovaShop DevOps Store
```

```bash
# 3. Favicon HTTP Durum Kodu Kontrolü
curl -s -o /dev/null -w "%{http_code}\n" http://localhost:8888/favicon.ico
```
*Beklenen çıktı:* `200`

---

#### 6. Konteyner Loglarını İnceleme

Uygulamanın başlangıç günlüklerini ve NovaShop terminal bannerını görüntüleyin:

```bash
docker logs novashop-ui-starter | head -n 25
```
*Beklenen çıktı:* `NOVASHOP DEVOPS STORE` ASCII karşılama bannerı ve `Started UiApplication in ... seconds`.

---

#### 7. Konteyneri Temizleme

Starter konteynerini durdurup kaldırın:

```bash
docker stop novashop-ui-starter
docker rm novashop-ui-starter
```

---

### Troubleshooting

#### Senaryo 1: Port Çakışması (`bind: address already in use: 8888`)
- **Belirti:** `docker run` çalıştırıldığında `Error response from daemon: driver failed programming external connectivity ... bind: address already in use` hatası alınması.
- **Muhtemel Neden:** 8888 portunun başka bir süreç veya önceki bir konteyner tarafından kullanılıyor olması.
- **Teşhis Komutu:**
  ```bash
  lsof -i :8888 || netstat -tulpn | grep 8888
  docker ps -a --filter "publish=8888"
  ```
- **Güvenli Çözüm:** Portu kullanan eski konteyneri durdurun veya farklı bir host portu kullanın (`-p 8889:8080`).

#### Senaryo 2: Yetersiz Bellek Nedeniyle Konteynerin Çökmesi (OOMKilled - Exit Code 137)
- **Belirti:** Konteyner başladıktan birkaç saniye sonra aniden duruyor ve `docker ps -a` çıktısında `Exited (137)` görünüyor.
- **Muhtemel Neden:** Java Sanal Makinesi (JVM) bellek ihtiyacının verilen `--memory=512m` sınırını aşması.
- **Teşhis Komutu:**
  ```bash
  docker inspect novashop-ui-starter --format '{{.State.OOMKilled}}'
  ```
- **Güvenli Çözüm:** JVM heap alanını container sınırına uygun yapılandırın:
  ```bash
  docker run -d --name novashop-ui-starter -p 8888:8080 \
    --memory=768m --cpus=0.5 \
    -e JAVA_TOOL_OPTIONS="-XX:MaxRAMPercentage=75.0" \
    novashop-ui:v0.1.0
  ```

#### Senaryo 3: Salt-Okunur Dosya Sistemi Yazma Hatası (`Read-only file system`)
- **Belirti:** Konteyner loglarında `java.io.IOException: Read-only file system` hatası çıkması.
- **Muhtemel Neden:** Spring Boot veya Tomcat'in `/tmp` dışındaki bir dizine yazmaya çalışması.
- **Teşhis Komutu:**
  ```bash
  docker logs novashop-ui-starter | grep -i "Read-only file system"
  ```
- **Güvenli Çözüm:** İlgili yazma dizinini `tmpfs` olarak container'a mount edin: `--tmpfs /tmp --tmpfs /run`.

---

### Güvenlik Notu

1. **Non-Root Kullanıcı:**
   - İmaj içindeki süreç asla `root` kullanıcısı ile çalıştırılamaz. Dockerfile'da `USER 1000:1000` tanımlanmalıdır.
2. **`latest` Tag Yasağı:**
   - İmaj adlandırmalarında asla `novashop-ui:latest` kullanılmaz. Sabit semantik versiyon (`v0.1.0`) kullanılır.
3. **Docker Socket Yasağı:**
   - `/var/run/docker.sock` kesinlikle uygulama konteynerlerine bağlanamaz.
4. **Kaynak Sınırları:**
   - Öğrenci makinesinin kilitlenmesini önlemek için hiçbir konteyner sınırsız bellek/CPU ile çalıştırılamaz.

---

### Cleanup / Rollback

Lab sonunda yerel kaynakları temizlemek için:

```bash
# 1. Konteyneri durdur ve sil
docker rm -f novashop-ui-starter 2>/dev/null || true

# 2. Üretilen test imajını sil (disk alanından tasarruf)
docker rmi novashop-ui:v0.1.0 2>/dev/null || true

# 3. Askıda kalan derleme önbelleğini temizle
docker builder prune -f
```

---

### Öğrenci Görevi

1. `docker run` komutuna `-e SPRING_PROFILES_ACTIVE=production` ortam değişkenini ekleyerek konteyneri başlatın.
2. Loglarda profilin aktifleştiğini `docker logs` ile doğrulayın.
3. Sağlık durumunun `UP` olduğunu teyit edin.

---

### Eğitmen Kontrol Listesi

- [ ] Multi-stage Dockerfile ile imaj başarıyla derlendi mi?
- [ ] Konteyner non-root `appuser` (UID 1000) ile mi çalışıyor?
- [ ] `--memory` ve `--cpus` kaynak limitleri uygulandı mı?
- [ ] `/actuator/health` endpoint'i `{"status":"UP"}` dönüyor mu?
- [ ] Ana sayfada "NovaShop DevOps Store" marka başlığı görünüyor mu?
- [ ] Öğrenci troubleshooting adımlarını ve cleanup komutunu başarıyla uyguladı mı?
