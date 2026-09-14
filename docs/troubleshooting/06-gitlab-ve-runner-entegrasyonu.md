# 06 — GitLab CE Yönetici Güvenlik Uyarıları ve GitLab Runner Entegrasyonu

Bu doküman; GitLab Community Edition üzerindeki yönetici uyarı banner'larının kalıcı olarak kapatılmasını ve GitLab Runner kurulumunu açıklar.

---

## 1. Karşılaşılan Sorunlar ve Hata Belirtileri

### Senaryo A: "Check the restrictions for new users" Uyarısı
- **Belirti:** GitLab web paneline `root` ile girildiğinde en üstte sarı uyarı banner'ı:
  `Your GitLab instance allows anyone to register for an account, which is a security risk...`
- **Kök Neden:** Varsayılan kurulumda genel kayıt (`signup_enabled`) açıktır. Dış dünyaya açık sunucularda güvenlik riski teşkil eder.

### Senaryo B: "Web IDE single origin fallback is enabled" Uyarısı
- **Belirti:** Admin panelinde uyarı banner'ı:
  `Your GitLab instance serves VS Code static assets if the Web IDE extension host domain is unreachable...`
- **Kök Neden:** GitLab 15+ ile gelen VS Code Web IDE, bağımsız bir sandbox etki alanı tanımlanmadığında kendi kök dizininden statik dosyaları sunar ve yöneticileri uyarır.

### Senaryo C: GitLab 16+ Runner Kayıt Hatası
- **Hata:** `column "runners_registration_token" does not exist`
- **Kök Neden:** GitLab 16.0 sürümüyle birlikte eski paylaşılan token sistemi kaldırılmış, yerine GraphQL tabanlı kimlik doğrulama token'ları (`glrt-...`) getirilmiştir.

---

## 2. Adım Adım Kodla Çözüm

### 1. Genel Kayıtları Veritabanından Kapatma
```bash
sudo docker exec -u gitlab-psql gitlab-ce /opt/gitlab/embedded/bin/psql -h /var/opt/gitlab/postgresql -d gitlabhq_production   -c "UPDATE application_settings SET signup_enabled = false WHERE id = (SELECT MAX(id) FROM application_settings);"
```

### 2. Web IDE Fallback Uyarısını Kalıcı Olarak Sonlandırma
İki katmanlı kalıcı çözüm:
```bash
# 1. Veritabanında root kullanıcısı için bu bildirimi kalıcı olarak dismiss et (feature_name 124):
sudo docker exec -u gitlab-psql gitlab-ce /opt/gitlab/embedded/bin/psql -h /var/opt/gitlab/postgresql -d gitlabhq_production   -c "INSERT INTO user_callouts (feature_name, user_id, dismissed_at) VALUES (124, 1, NOW()) ON CONFLICT (user_id, feature_name) DO UPDATE SET dismissed_at = NOW();"

# 2. View şablonunun render edilmesini en baştan sonlandır (- return):
sudo docker exec gitlab-ce sed -i "s/- return unless show_single_origin_fallback_callout?/- return/"   /opt/gitlab/embedded/service/gitlab-rails/app/views/layouts/header/_single_origin_fallback_callout.html.haml
```

### 3. GitLab 16+ GraphQL Runner Token Üretme ve Kaydetme
```bash
# 1. GraphQL üzerinden proje runner tokeni al
TOKEN=$(curl -s -b /tmp/gl_cookie.txt -H "X-CSRF-Token: $CSRF" -H "Content-Type: application/json" -X POST http://127.0.0.1:8929/api/graphql   -d '{"query": "mutation { runnerCreate(input: { runnerType: PROJECT_TYPE, projectId: "gid://gitlab/Project/2", description: "novashop-runner" }) { runner { id ephemeralAuthenticationToken } errors } }"}' | grep -o '"glrt-[^"]*"' | tr -d ")

# 2. Host üzerinde gitlab-runner servisini kaydet
sudo gitlab-runner register --non-interactive   --url "http://127.0.0.1:8929/"   --token "$TOKEN"   --executor "shell"   --description "novashop-vm-shell-runner"

# 3. Servis olarak başlat
sudo gitlab-runner install --user=root --working-directory=/home/gitlab-runner
sudo gitlab-runner start
```

---

## 3. Doğrulama Komutları

```bash
# 1. Uyarı bannerlarının temizlendiğini test et:
curl -s -b /tmp/gl_cookie.txt http://127.0.0.1:8929/admin | grep -i "single origin fallback" || echo "CLEAN"

# 2. Runner durumunu test et:
sudo gitlab-runner verify
```
*Beklenen Sonuç:* `Verifying runner... is valid`.
