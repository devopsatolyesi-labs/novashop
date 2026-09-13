# NovaShop Eğitim Platformu — Eğitmen Master Yol Haritası ve Görev Takip Panosu

> **Son Güncelleme:** 2026-09-13  
> **Eğitmen:** Hakan Bayraktar (`@hbayraktar`)  
> **Eğitmen Reposu:** `https://gitlab.com/devopsatolyesi/novashop` (Yerel: `~/devops-workspace/novashop`)  
> **Öğrenci Reposu:** `https://github.com/devopsatolyesi-labs/novashop` (Yerel: `~/devops-workspace/student-novashop`)

---

## 📌 Genel Durum Özeti (Progress Dashboard)

| Aşama | Başlık | Durum | Hedef / Açıklama |
| :---: | :--- | :---: | :--- |
| **01** | Çalışma Alanı ve Repo Ayrımı | ✅ TAMAMLANDI | `student-novashop` (GitHub) & `novashop` (GitLab) ayrıştırıldı |
| **02** | Altyapı, IP/Port & DNS Planlaması | ✅ TAMAMLANDI | `studentXX-*` standartı, Nginx port matrisi ve IP tablosu hazırlandı |
| **03** | Cloudflare DNS Otomasyonu | ✅ TAMAMLANDI | CSV tabanlı çoklu öğrenci DNS kayıt scripti ve CI workflow hazırlandı |
| **04** | Platform Hazırlık Modülü (`LAB-00`) | ✅ TAMAMLANDI | GitLab, Harbor, SonarQube, Jenkins Ubuntu kurulumları & Compose şablonları |
| **05** | Öğrenci Reposunun Hazırlanması | ✅ TAMAMLANDI | `*` çekirdek lablar, `bonus` track, temizlendi ve local commit yapıldı |
| **06** | Eğitmen Rehberi ve Soru-Cevap Bankası | ✅ TAMAMLANDI | `INSTRUCTOR_GUIDE.md`, soru-cevaplar, gotchas ve troubleshooting raporu |
| **07** | Remote Senkronizasyonu | 🔄 HAZIR | GitHub (`student-novashop`) ve GitLab (`novashop`) depolarına push |

---

## 📋 Detaylı Görev Listesi (Task Breakdown)

### 1. Çalışma Alanı & Remote Yapılandırması
- [x] `/Users/hakan/devops-workspace/student-novashop` klonlandı ve `origin` -> `devopsatolyesi-labs/novashop.git` olarak ayarlandı.
- [x] `/Users/hakan/devops-workspace/novashop` eğitmen çalışma alanı yapıldı, `origin` -> `git@gitlab.com:devopsatolyesi/novashop.git` ve `upstream` -> GitHub olarak bağlandı.
- [x] GitLab SSH yapılandırması (`id_rsa` / `@hbayraktar`) entegre edildi.

### 2. Altyapı, IP, Port ve DNS Mimarisi
- [x] `docs/instructor/INFRASTRUCTURE_PLAN.md` oluşturuldu.
- [x] Tüm araçlar için tekil port tahsisleri (80/443, 8888, 8929, 9090, 13000, 18080, 18081, 18082, 18083, 19000, 19090) netleştirildi.
- [x] `studentXX-*` DNS isimlendirme formatı (Cloudflare single-level wildcard uyumu) belgelendi.
- [x] Nginx reverse proxy konfigürasyon şablonları hazırlandı.

### 3. Cloudflare DNS Otomasyonu
- [x] `scripts/cloudflare/students.csv` (Örnek öğrenci ID - IP eşleme tablosu).
- [x] `scripts/cloudflare/sync_dns.py` (Cloudflare API v4 ile A-kayıtlarını oluşturan/güncelleyen script).
- [x] `scripts/cloudflare/README.md` (CLI ve GitHub/GitLab Actions ile çalıştırma kılavuzu).
- [x] Manuel tetiklemeli CI/CD workflow (`.github/workflows/sync-student-dns.yml`).

### 4. Platform Hazırlık Modülü (`labs/LAB-00-PLATFORM-SETUP/`)
- [x] `README.md` (Platform genel mimarisi, IP:Port ve DNS/SSL çift erişim kılavuzu).
- [x] `01-gitlab-setup.md` + `infra/gitlab/docker-compose.yml`.
- [x] `02-harbor-setup.md` + `infra/harbor/install_harbor.sh` (Trivy scanner entegrasyonu).
- [x] `03-sonarqube-setup.md` + `infra/sonarqube/docker-compose.yml` (PostgreSQL + SonarQube).
- [x] `04-jenkins-setup.md` + `infra/jenkins/docker-compose.yml` (Docker socket entegreli).
- [x] `05-nginx-ssl-setup.md` (Nginx reverse proxy & SSL yapılandırması).

### 5. Öğrenci Reposunun Hazırlanması (`student-novashop`)
- [x] Çekirdek labların adlandırılması ve `*` zorunlu göstergesi eklenmesi (`labs/README.md`).
- [x] `LAB-03`, `LAB-07`, `LAB-08` rehberlerinde `LAB-00` ön koşul bağlantıları ve çift erişim modeli güncellendi.
- [x] Eğitmene özel notlar, planlama dokümanları ve geçici raporlar temizlendi.
- [x] Git pratiklerinin canlı kodu bozmaması için `lab-01/products.json` izolasyonu doğrulandı.
- [x] Yerel commit oluşturuldu (`feat(labs): add LAB-00 platform setup, compose templates and dual access model`).

### 6. Eğitmen Dokümantasyonu & Pedagojik Rehber (`novashop`)
- [x] `docs/instructor/INSTRUCTOR_GUIDE.md`:
  - Lab akış sıralamasının pedagojik mantığı.
  - Derste öğrencilere sorulacak düşündürücü soru-cevap bankası.
  - Sık karşılaşılan öğrenci tuzakları (gotchas) ve anında çözüm reçeteleri (Adım 10 Compose çakışması, JSON syntax hataları, `appuser` salt-okunur dosya sistemi).
  - Doğrulama test scriptleri (`verify-lab-*.sh`).
- [x] `troubleshot.md` dosyası `docs/instructor/troubleshooting/lab-03-json-crash.md` altına taşındı.

### 7. Remote Senkronizasyonu (Sıradaki Adım)
- [ ] `student-novashop` -> GitHub (`devopsatolyesi-labs/novashop:main`) push.
- [ ] `novashop` -> GitLab (`devopsatolyesi/novashop:main`) push.
