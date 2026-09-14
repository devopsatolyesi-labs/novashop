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

# 2. İmajı push et:
docker push 127.0.0.1:18082/novashop/ui:v0.1.1

# 3. İkinci kez aynı etiketi push etmeyi dene (Hata beklenir):
docker push 127.0.0.1:18082/novashop/ui:v0.1.1
```
*Beklenen Sonuç:* İkinci push `configured as immutable` hatası ile başarıyla reddedilmelidir.
