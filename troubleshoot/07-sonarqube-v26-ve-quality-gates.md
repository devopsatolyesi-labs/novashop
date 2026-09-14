# 07 — SonarQube v26 Community, PBKDF2 Şifre Algoritması ve Kalite Kapıları

Bu doküman; SonarQube v26 Community sürümünde PostgreSQL PBKDF2 parola sıfırlama, Maven eklentisi ve Quality Gate otomasyonunu açıklar.

---

## 1. Karşılaşılan Sorunlar ve Hata Belirtileri

### Senaryo A: SonarQube v26 Parola Sıfırlama Uyumsuzluğu
- **Hata:** PostgreSQL üzerinden `users` tablosundaki `crypted_password` alanına MD5 veya BCrypt yazıldığında SonarQube'un parolayı tanımaması.
- **Kök Neden:** SonarQube v26 sürümünde parola karma algoritması **PBKDF2-HMAC-SHA512** (100.000 iterasyon) standardına yükseltilmiştir.

### Senaryo B: Maven Taramasında Eklenti Bulunamadı Hatası
- **Hata Çıktısı:**
  ```text
  [ERROR] No plugin found for prefix 'sonar' in the current project and in the plugin groups
  ```
- **Kök Neden:** `src/ui/pom.xml` dosyasında `org.sonarsource.scanner.maven:sonar-maven-plugin` eklentisi tanımlanmamıştır.

---

## 2. Adım Adım Kodla Çözüm

### 1. Python ile SonarQube v26 PBKDF2 Parola Üretimi
`WebSalla454!!` şifresini SonarQube v26 formatında hashleme:
```python
import hashlib, base64

password = b"WebSalla454!!"
salt = base64.b64decode("qUkM7CUhROm/lcsywzLc564UV5M=") # 20 byte salt
hash_bytes = hashlib.pbkdf2_hmac("sha512", password, salt, 100000)
hash_b64 = base64.b64encode(hash_bytes).decode("utf-8")
print(f"Hash: {hash_b64}")
```
PostgreSQL güncellemesi:
```sql
UPDATE users SET 
  crypted_password = '<HASH_B64>', 
  salt = 'qUkM7CUhROm/lcsywzLc564UV5M=', 
  hash_method = 'PBKDF2',
  user_local = true,
  reset_password = false 
WHERE login = 'admin';
```

### 2. Maven `pom.xml` Eklenti Tanımı
`src/ui/pom.xml` dosyasına eklenmesi gereken blok:
```xml
<build>
  <plugins>
    <plugin>
      <groupId>org.sonarsource.scanner.maven</groupId>
      <artifactId>sonar-maven-plugin</artifactId>
      <version>5.0.0.4389</version>
    </plugin>
  </plugins>
</build>
```

### 3. Otomatik Kod Analizi ve Quality Gate Doğrulaması
```bash
cd src/ui
./mvnw clean verify sonar:sonar   -Dsonar.host.url=http://127.0.0.1:19000   -Dsonar.token=squ_6d2a2a21111fe9588f14df686173d2fc9d2990ad   -Dsonar.projectKey=novashop-ui   -Dsonar.projectName="NovaShop UI Storefront"
```

---

## 3. Doğrulama Komutları

```bash
# Quality Gate durumunu API üzerinden sorgula:
curl -s -u "squ_6d2a2a21111fe9588f14df686173d2fc9d2990ad:"   "http://127.0.0.1:19000/api/qualitygates/project_status?projectKey=novashop-ui" | jq .projectStatus.status
```
*Beklenen Sonuç:* `"OK"`.
