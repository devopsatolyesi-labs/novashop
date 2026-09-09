# NovaShop DevOps Store — Güvenlik Temel İlkeleri (Security Baseline)

Bu doküman, NovaShop DevOps Store projesinde kodlama, container paketleme, cloud altyapısı ve CI/CD süreçlerinde uyulması zorunlu güvenlik standartlarını tanımlar.

---

## 1. Secret (Gizli Bilgi) Yönetimi

1. **Repoya Secret Yazılmaz:**
   - Parolalar, AWS Access Key / Secret Key, Cloudflare API Token, SSH özel anahtarları (`*.pem`, `id_rsa`), veritabanı şifreleri kesinlikle Git'e commit edilemez.
2. **Örnek Dosyalar Sadece Şablon İçerir:**
   - `.env.example` veya `project.env.example` gibi dosyalarda yalnızca `<CHANGE_ME>` veya açıklayıcı `<PLACEHOLDER>` değerleri bulunur.
3. **Zorunlu `.gitignore` Koruması:**
   - `.env`, `*.key`, `*.pem`, `*.tfstate*`, `kubeconfig*` desenleri repo kökünde ignore edilmiştir.
4. **Secret Sızıntısı Durumunda Müdahale:**
   - Yanlışlıkla commit edilen bir secret yalnızca dosyadan silinerek çözülemez. Anahtar derhal AWS/servis sağlayıcı konsolundan iptal edilmeli (revoke/rotate), Git geçmişi temizlenmeli ve durum belgelenmelidir.

---

## 2. Container ve İmaj Güvenliği

1. **`latest` Tag Yasağı:**
   - Container imajlarında asla `latest` etiketi kullanılmaz. Sabit semantik versiyon (`v1.6.2`, `v0.1.0`) ve mümkün olduğunda SHA256 digest referansı kullanılır.
2. **Non-Root Kullanıcı:**
   - Container'lar root kullanıcısıyla çalıştırılmamalıdır. NovaShop UI Dockerfile'ında uygulandığı gibi `appuser` (UID 1000) gibi yetkisiz kullanıcılar tanımlanmalıdır.
3. **Dosya Sistemi İzolasyonu:**
   - Mümkün olan yerlerde kök dosya sistemi salt-okunur (`read_only: true`) yapılmalı, geçici yazma ihtiyaçları `tmpfs` (/tmp) ile sınırlandırılmalıdır.
4. **Gereksiz Yetkilerin Düşürülmesi (Capability Dropping):**
   - Container tanımında `cap_drop: [ALL]` uygulanmalı; yalnızca zorunlu yetkiler (örn. `NET_BIND_SERVICE`) verilmelidir.
5. **Docker Socket Bağlantısı Yasağı:**
   - Uygulama container'larına ana makinenin Docker socket'i (`/var/run/docker.sock`) kesinlikle bağlanamaz.

---

## 3. Bulut (AWS) Ağ ve Erişim Güvenliği

1. **Private Subnet ve İzole RDS:**
   - Veritabanı motorları (RDS MySQL/MariaDB/Postgres) daima private subnet'lerde konumlandırılır.
   - `PubliclyAccessible` parametresi kesinlikle `false` olmalıdır.
2. **Security Group En Az Ayrıcalık Kuralı (Least Privilege):**
   - RDS Security Group, yalnızca EC2 veya Kubernetes worker Security Group'undan gelen veritabanı portuna (3306 veya 5432) izin verir.
   - Veritabanı portları veya yönetim portları için `0.0.0.0/0` kuralı eklenemez.
3. **Yönetim Portları ve SSH:**
   - SSH (port 22) ve Cockpit (port 9090) yalnızca öğrencinin kendi kaynak IP'siyle (`<MY_IP>/32`) sınırlandırılmalıdır. Tercihen AWS Systems Manager (Session Manager) kullanılmalıdır.
4. **OIDC Tabanlı CI/CD Erişimi:**
   - GitHub Actions veya GitLab CI'ın AWS kaynaklarına erişiminde kalıcı AWS Access Key yerine OpenID Connect (OIDC) ve geçici AssumeRole kimlik doğrulaması kullanılır.

---

## 4. Yasaklı Kolaylaştırma Pratikleri (Anti-Patterns)

Eğitimde kolaylık olsun diye aşağıdaki güvensiz pratiklerin uygulanması **kesinlikle yasaktır**:

- ❌ `chmod -R 777` ile dosya izinlerini açmak.
- ❌ Doğrulanmamış veya içeriği incelenmemiş `curl https://... | bash` komutları çalıştırmak.
- ❌ `docker run --privileged` çalıştırmak.
- ❌ TLS sertifika doğrulamasını kapatmak (`--insecure`, `curl -k`, `TLS_SKIP_VERIFY=true`).
- ❌ SSH komutlarında `StrictHostKeyChecking=no` kullanmak.
- ❌ EC2 veya sunucu üzerinde servisleri doğrudan `root` kullanıcısıyla çalıştırmak.
