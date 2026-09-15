# 04 — Harbor Özel Konteyner Kayıt Defteri ve Değiştirilemez Etiket (Tag Immutability)

Bu doküman; Harbor v2.10 üzerinde CI/CD robot hesaplarının yönetimi, zafiyet taraması ve değiştirilemez etiket kurallarının işletilmesini açıklar.

---

## 1. Karşılaşılan Sorunlar ve Hata Belirtileri

### Senaryo A: Robot Hesap Bash Kaçışı Hatası
- **Hata Çıktısı:** `unauthorized: incorrect username or password`
- **Kök Neden:** Harbor robot kullanıcı adı formatı `robot$novashop+novashop-cicd` şeklindedir. Bash ortamında çift tırnak içinde `$` işareti kabuk değişkeni olarak algılandığından kullanıcı adı bozulur.
- **Çözüm:** Kullanıcı adında tek tırnak veya kaçış karakteri kullanılmalıdır: `'robot$novashop+novashop-cicd'` veya `"robot\$novashop+novashop-cicd"`.

### Senaryo B: Değiştirilemez Etiket İhlali (409 Conflict)
- **Hata Çıktısı:**
  ```text
  push novashop/ui:v0.1.1
  failed to process request due to 'ui:v0.1.1' configured as immutable
  ```
- **Kök Neden:** Güvenlik gereği Harbor üzerinde `v*` kalıbındaki etiketler kilitlenmiştir. Aynı sürüm numarasıyla tekrar push yapılması engellenir.

### Senaryo C: Doğrulama Scriptinde Ping Çıktısı Uyumsuzluğu
- **Hata:** `/api/v2.0/ping` çağrısı `Pong` döndürdüğünde katı eşitlik (`[ "$RESP" = "pong" ]`) arayan scriptlerin hata vermesi.
- **Çözüm:** Case-insensitive arama: `echo "$RESP" | grep -qi "pong"`.

### Senaryo D: Harbor Token Realm Timeout ve Local DNS (/etc/hosts) Çözümü
- **Hata Çıktısı:**
  ```text
  Error response from daemon: Get "http://127.0.0.1:18082/v2/": 
  Get "http://student01-harbor.devopsatolyesi.com:18082/service/token?...": 
  net/http: request canceled while waiting for connection (Client.Timeout exceeded while awaiting headers)
  ```
- **Kök Neden:**
  1. `docker login 127.0.0.1:18082` çalıştırıldığında Harbor V2 registry `401 Unauthorized` yanıtı döner ve token almak için istemciyi `harbor.yml` içinde tanımlı olan `hostname` adresine (`student01-harbor.devopsatolyesi.com:18082`) yönlendirir (`Www-Authenticate: Bearer realm=...`).
  2. Sunucu bu adresi Cloudflare proxy IP'lerine çözümler. Cloudflare web portlarını (80/443) iletirken standart dışı portları (`18082`) sessizce düşürür (DROP).
  3. Docker daemon token isteğinde zaman aşımına uğrar.
- **Çözüm:**
  Sunucunun yerel trafiği dışarıya (Cloudflare'e) göndermesini engellemek için `/etc/hosts` dosyasına loopback eşlemesi eklenmelidir:
  ```bash
  echo "127.0.0.1 student01-harbor.devopsatolyesi.com" | sudo tee -a /etc/hosts
  ```
  Ardından login tekrar çalıştırılır:
  ```bash
  docker login student01-harbor.devopsatolyesi.com:18082 -u admin -p Harbor12345
  ```

---

## 2. Adım Adım Kodla Çözüm

### 1. Harbor API ile Programatik Robot Hesap Oluşturma
```bash
curl -s -u "admin:WebSalla454!!" -X POST "http://127.0.0.1:18082/api/v2.0/robots"   -H "Content-Type: application/json"   -d '{
    "name": "novashop-cicd",
    "description": "NovaShop CI/CD Pipeline Robot",
    "level": "system",
    "duration": -1,
    "permissions": [
      {
        "kind": "project",
        "namespace": "novashop",
        "access": [
          {"resource": "repository", "action": "push"},
          {"resource": "repository", "action": "pull"},
          {"resource": "artifact", "action": "read"}
        ]
      }
    ]
  }'
```

### 2. Tag Immutability Kuralı Tanımlama
`v*` kalıbındaki release etiketlerinin üzerine yazılmasını engelleme:
```bash
curl -s -u "admin:WebSalla454!!" -X POST "http://127.0.0.1:18082/api/v2.0/projects/novashop/immutabletagrules"   -H "Content-Type: application/json"   -d '{
    "priority": 1,
    "action": "immutable",
    "template": "immutable",
    "tag_selectors": [
      {
        "kind": "doublestar",
        "decoration": "matches",
        "pattern": "v*"
      }
    ],
    "scope_selectors": {
      "repository": [
        {
          "kind": "doublestar",
          "decoration": "repoMatches",
          "pattern": "**"
        }
      ]
    }
  }'
```

---

## 3. Doğrulama ve Test Komutları

```bash
# 1. Robot hesap ile oturum aç:
echo "IDPJHyl1Vr8hGHzoWxrHgWT1gwSRjbCe" | docker login 127.0.0.1:18082 -u "robot\$novashop+novashop-cicd" --password-stdin

# 2. İmajı ilk kez push et (Kabul edilir):
docker push 127.0.0.1:18082/novashop/ui:v0.1.1

# ⚠️ Önemli Mühendislik Notu:
# Eğer aynı imajı hiçbir değişiklik yapmadan tekrar push ederseniz, digest (parmak izi) 
# aynı olduğu için OCI standartlarına göre idempotent kabul edilir ve hata vermez.

# 3. Gerçek İhlal Testi (Farklı bir imajla aynı etiketin üzerine yazmaya çalışma):
docker pull alpine:latest
docker tag alpine:latest 127.0.0.1:18082/novashop/ui:v0.1.1
docker push 127.0.0.1:18082/novashop/ui:v0.1.1
```
*Beklenen Sonuç:*  
`error from registry: Failed to process request due to 'ui:v0.1.1' configured as immutable.`  
İşlem Harbor tarafından anında reddedilir.
