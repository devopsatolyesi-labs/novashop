# NovaShop Eğitim Platformu — Eğitmen Ana Rehberi (Instructor Master Guide)

> **Gizlilik:** Bu doküman yalnızca eğitmene özeldir (`https://gitlab.com/devopsatolyesi/novashop`). Öğrenci reposunda (`github.com/devopsatolyesi-labs/novashop`) yer almaz.

---

## 1. Pedagojik Akış ve Müfredat Stratejisi

NovaShop eğitimi, klasik teorik anlatım yerine **"Yaşatarak Öğretme (Hands-on Troubleshooting & Engineering)"** yaklaşımını benimser.

### Akış Sıralaması:
1. **LAB-00 — Platform Kurulumu (Gerektiğinde):** Öğrenci sadece o günkü araçları (GitLab, Harbor, SonarQube, Jenkins) ayağa kaldırır, RAM şişmesi yaşanmaz.
2. **LAB-01 — Git & Branching:** Canlı kod bozulmadan izole `lab-01/products.json` üzerinde branch ve conflict pratiği yapılır.
3. **LAB-03 — Docker & Compose:** Multi-stage build, rootless güvenlik ve Compose overlay mantığı öğrenilir.
4. **LAB-06 — Kind Kubernetes & Helm:** Konteynerden orkestrasyona geçiş; Pod, Service, Ingress ve Helm chart mimarisi.
5. **LAB-07 — GitLab CI & Harbor:** Kod pushlandığında otomatik build, Trivy zafiyet taraması ve Harbor registry'e push.
6. **LAB-08 — DevSecOps:** SonarQube Quality Gate, SAST, secret scanning ve SBOM üretimi.
7. **LAB-10 — Observability:** Prometheus metrikleri, Grafana panoları ve SLO yönetimi.
8. **Bonus Lablar (ArgoCD, ELK, Terraform, AWS EKS/ECS):** İleri seviye konular için modüler lablar.

---

## 2. Derste Öğrencilere Sorulacak Soru-Cevap Bankası

Ders anlatımı sırasında öğrencilerin interaktif katılımını sağlamak için aşağıdaki soruları yönlendirebilirsiniz:

### Soru 1 (Docker Güvenliği):
* **Soru:** *"Neden container içinde uygulamayı root kullanıcısı yerine appuser (UID 10001) ile çalıştırıyoruz?"*
* **Eğitmen Cevabı:** Container izolasyonu Linux çekirdek namespace'lerine dayanır. Eğer container içindeki root yetkili olursa, container kaçışı (container escape) açığında host makinede de root yetkisi elde edebilir. Rootless container en az yetki (Least Privilege) ilkesinin temelidir.

### Soru 2 (Docker Compose Overlay):
* **Soru:** *"Prodüksiyonda `starter.secure.yml` overlay dosyasında `read_only: true` yaptık. Uygulama neden `/app` dizinine yazamadı ama `/tmp` dizinine yazabildi?"*
* **Eğitmen Cevabı:** `read_only: true` konteynerin root dosya sistemini (`/`) salt-okunur yapar. Ancak Linux uygulamaları geçici dosya yazmak zorunda olduğu için `/tmp` dizinine RAM üzerinde çalışan bir `tmpfs` (RAM diski) bağladık. Böylece kalıcı dosya sistemine yazma engellenirken geçici dosyalar bellekte tutulur.

### Soru 3 (GitLab vs Jenkins):
* **Soru:** *"Neden modern ekipler Jenkins yerine GitLab CI veya GitHub Actions'a geçiyor?"*
* **Eğitmen Cevabı:** Jenkins Controller-Agent mimarisi sunucu bakımı, plugin uyumsuzlukları ve snowflake server problemleri yaratır. GitLab CI ise repository ile declarative (`.gitlab-ci.yml`) olarak yaşar, her iş için taze Docker container ayağa kaldırır ve sunucu bağımlılığını sıfırlar.

### Soru 4 (SonarQube Quality Gate):
* **Soru:** *"Birim testlerin %100 geçmesi bir uygulamanın güvenli ve kaliteli olduğunu kanıtlar mı?"*
* **Eğitmen Cevabı:** Hayır. Birim testler sadece fonksiyonel mantığı doğrular; SQL Injection açıklarını, hardcoded secret'ları, bellek sızıntılarını veya OWASP Top 10 zafiyetlerini göremez. Bu yüzden SonarQube gibi statik analiz (SAST) araçları zorunludur.

---

## 3. Kritik Öğrenci Tuzakları (Gotchas) ve Hızlı Müdahale Reçeteleri

Öğrencilerin lab sırasında en çok takılacağı 6 kritik nokta ve eğitmenin anında uygulayacağı çözümler:

### Tuzak 1: Adım 10 Port Çakışması (`8888:8888 already allocated`)
* **Belirti:** Öğrenci Adım 10'da overlay başlatırken `Bind for 0.0.0.0:8888 failed: port is already allocated` hatası alır.
* **Neden:** Öğrenci önceki adımdaki container'ı durdurmadan (`docker compose down`) yeni overlay'i başlatmıştır.
* **Hızlı Çözüm:**
  ```bash
  docker compose down
  docker compose -p novashop-starter -f docker-compose.yml -f starter.secure.yml up -d
  ```

### Tuzak 2: JSON Sözdizim Hatası Nedeniyle UI Servisinin Çökmesi (`JsonParseException`)
* **Belirti:** `docker compose logs ui` çıktısında `Unexpected character ('<' (code 60))` veya `JsonParseException` görülür, container sürekli restart atar.
* **Neden:** Git merge conflict çözümü sırasında conflict marker'lar (`<<<<<<< HEAD`) veya bozuk JSON kalmıştır.
* **Hızlı Çözüm:**
  * Canlı `src/ui/src/main/resources/data/products.json` dosyasını `git checkout -- src/ui/...` ile orijinaline döndürün.
  * Öğrenciye conflict pratiğini `lab-01/products.json` üzerinde yapması gerektiğini hatırlatın.

### Tuzak 3: Her Git Push'ta Şifre / PAT Sorulması
* **Belirti:** Öğrenci her branch açıp pushladığında GitHub/GitLab token sorar.
* **Hızlı Çözüm:**
  ```bash
  git config --global credential.helper store
  ```
  İlk girişte şifreyi girdiğinde `~/.git-credentials` dosyasına kaydedilir ve bir daha sormaz.

### Tuzak 4: Harbor Docker Login Hatası (`server gave HTTP response to HTTPS client`)
* **Belirti:** `docker login <IP>:18082` dendiğinde SSL handshake hatası verir.
* **Hızlı Çözüm:** Docker daemon HTTP registry olduğunu bilmelidir:
  ```bash
  sudo mkdir -p /etc/docker
  cat << 'JSON' | sudo tee /etc/docker/daemon.json
  {
    "insecure-registries": ["<IP>:18082"]
  }
  JSON
  sudo systemctl restart docker
  ```

### Tuzak 5: SonarQube Başlamıyor (`max virtual memory areas vm.max_map_count [65530] is too low`)
* **Belirti:** `docker logs sonarqube` incelendiğinde Elasticsearch kernel limit hatasıyla durur.
* **Hızlı Çözüm:**
  ```bash
  sudo sysctl -w vm.max_map_count=524288
  ```

---

## 4. Doğrulama Scriptleri (Verification)

Her labın sonunda öğrencinin labı doğru tamamlayıp tamamlamadığını test etmek için `scripts/verify/` altındaki scriptleri kullanabilirsiniz:
* `bash scripts/verify/verify-lab-01.sh` -> Git branch ve commit kontrolleri
* `bash scripts/verify/verify-lab-03.sh` -> Docker healthcheck ve endpoint testi
* `bash scripts/verify/verify-lab-08.sh` -> Güvenlik ve gizli anahtar taramaları

---

## 5. Öğrenci DNS ve Altyapı Yönetimi

Sınıf listesi belli olduğunda tek komutla tüm öğrenci DNS'lerini açmak için:
```bash
export CLOUDFLARE_API_TOKEN="<TOKEN>"
python3 scripts/cloudflare/sync_dns.py scripts/cloudflare/students.csv
```
