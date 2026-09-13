# LAB-03: Docker Compose UI Servisi Çökme Sorunu ve Çözüm Raporu (Troubleshoot)

> **Tarih:** 2026-09-13  
> **Konum:** `devopsatolyesi@devops-c1-student100-vm:~/novashop/src/ui`  
> **Laboratuvar:** [LAB-03-DOCKER-COMPOSE.md](https://github.com/devopsatolyesi-labs/novashop/blob/main/docs/labs/LAB-03-DOCKER-COMPOSE.md)  
> **Durum:** ✅ ÇÖZÜLDÜ (PASS)

---

## 1. Hata Tanımı (Symptoms)
`src/ui` dizininde `docker compose up -d` komutu çalıştırıldığında `ui-ui-1` konteyneri ayakta kalamayarak sürekli `Restarting (1)` durumuna düşüyordu.

Konteyner logları incelendiğinde (`docker compose logs ui`):
```text
ui-1  | Caused by: com.fasterxml.jackson.core.JsonParseException: Unexpected character ('<' (code 60)): was expecting double-quote to start field name
ui-1  |  at [Source: REDACTED (`StreamReadFeature.INCLUDE_SOURCE_IN_LOCATION` disabled); line: 6, column: 1]
ui-1  |         at com.fasterxml.jackson.core.JsonParser._constructReadException(JsonParser.java:2672)
ui-1  |         at com.amazon.sample.ui.services.catalog.MockCatalogService.loadProductsFromJson(MockCatalogService.java:96)
ui-1  |         at com.amazon.sample.ui.services.catalog.MockCatalogService.<init>(MockCatalogService.java:44)
ui-1  |         at com.amazon.sample.ui.config.StoreServices.catalogService(StoreServices.java:94)
```

---

## 2. Kök Neden Analizi (Root Cause)
- Spring Boot uygulamasının `MockCatalogService` bileşeni, ürün kataloğunu `src/ui/src/main/resources/data/products.json` dosyasından okumaktadır.
- Daha önce yapılan bir birleştirme commit'inde (`bc00a4e`), Git merge conflict işaretleri (`<<<<<<< HEAD`, `=======`, `>>>>>>> feature/update-mug-product`) kazara JSON dosyasının içine commit edilmişti:
  ```json
  <<<<<<< HEAD
      "price": 50,
  =======
      "price": 55,
  >>>>>>> feature/update-mug-product
  ```
- Jackson JSON Parser, 6. satırda tırnak işareti (`"`) beklerken `<` karakteriyle karşılaştığı için `JsonParseException` fırlatmış ve Spring ApplicationContext başlatılamadığı için konteyner exit code 1 ile sonlanmıştır.

---

## 3. Uygulanan Çözüm Adımları (Resolution)
1. **JSON Temizliği ve Doğrulama:**
   - `src/ui/src/main/resources/data/products.json` dosyasındaki tüm conflict işaretleri (`<<<<<<<`, `=======`, `>>>>>>>`) ve mükerrer anahtarlar temizlendi.
   - İlgili ürünlerin fiyatları kararlaştırılan değere (`55` ve `55000`) çekildi.
   - Python `json.loads()` ile 12 ürünün tamamının geçerli JSON olduğu doğrulandı.

2. **Git Commit:**
   - Düzeltme Git yerel deposuna kaydedildi (`0cedad5 fix(catalog): remove merge conflict markers from products.json`).

3. **Docker İmajının Yeniden Derlenmesi ve Başlatılması:**
   ```bash
   cd ~/novashop/src/ui
   docker compose down
   docker compose build --no-cache
   docker compose up -d
   ```

4. **Doğrulama ve Sağlık Testi:**
   - Konteyner durumu kontrol edildi: `Up (healthy)`.
   - Actuator sağlık endpoint'i test edildi:
     ```bash
     curl -i http://localhost:8888/actuator/health
     # Yanıt: HTTP/1.1 200 OK {"status":"UP"}
     ```
   - Otomatik doğrulama betiği çalıştırıldı:
     ```bash
     cd ~/novashop
     bash scripts/verify/verify-lab-03.sh
     ```
     **Sonuç:** `=== [LAB-03] Canlı Smoke ve Güvenlik Doğrulaması Başarılı (PASS) ===`

---

## 4. Diğer Lablar ve AWS/Terraform Güvenliği
- Bu düzeltme sadece UI servisinin mock ürün kataloğundaki bozuk JSON sözdizimini onarmıştır.
- Docker port eşlemeleri (8888), ağ yapısı (`ui_default`, `novashop-net`), Kubernetes konfigürasyonları, diğer mikroservisler (`catalog`, `cart`, `orders`, `checkout`), Terraform dosyaları veya AWS kaynakları **kesinlikle etkilenmemiştir**.
- Sonraki lablar ve AWS terraform entegrasyonu tamamen güvenli ve uyumlu şekilde devam edebilir.
