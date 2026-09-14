# LAB-00 — Platform Kurulumu ve DevOps Araçları Hazırlığı

Bu modül, kurumsal DevOps laboratuvarlarında kullanılacak temel platform araçlarının (**GitLab CE, Harbor OCI Registry, SonarQube, Jenkins ve Nginx Reverse Proxy**) sıfır bir Ubuntu sunucusu üzerinde adım adım ve kendi kendine yeten biçimde kurulmasını kapsar.

---

## 🎯 Temel İlkeler ve Yaklaşım

1. **Sıfır Sunucu Varsayımı:** Sunucuda `/opt/harbor` veya benzeri dizinler ya da araçlar önceden kurulu olmak zorunda değildir. Her rehber, sıfır bir sanal makinede baştan sona çalışacak şekilde tasarlanmıştır.
2. **Çift Erişim Modeli (Dual Mode):**
   * **Model A (Doğrudan IP:Port — Standart & Varsayılan):** DNS ve SSL zorunluluğu olmadan doğrudan `http://<UBUNTU_IP>:<PORT>` ile çalışır.
   * **Model B (Kurumsal DNS + Wildcard SSL):** Sunucuya DNS tahsis edildiğinde (`student100` gibi) tek komutla Nginx 443 SSL ayağa kalkar.
   * **Önemli:** Model B aktif olsa bile Model A (doğrudan IP:Port erişimi) asla kapanmaz; iki model eşzamanlı çalışır.
3. **Sıfır `.env` Hatası:** Yapılandırmalar harici eksik `.env` dosyalarına bağımlı değildir; tüm çevre değişkenleri varsayılan değerlerle gömülüdür.
4. **Bellek (RAM) Yönetimi:** Tüm araçları aynı anda çalıştırmak zorunda değilsiniz. İlgili laba geçildiğinde aracı başlatıp, lab bitiminde durdurarak (`docker compose stop`) RAM tasarrufu sağlayabilirsiniz.

---

## 🛠️ Sıfır Sunucu Temel Hazırlığı (Adım 0)

Sıfır bir Ubuntu makinesinde Docker Engine ve Docker Compose v2 eklentisini kurun:

```bash
sudo apt-get update
sudo apt-get install -y ca-certificates curl git docker.io docker-compose-plugin
sudo usermod -aG docker $USER
```

---

## 🧭 DevOps Araçları, Port ve Erişim Haritası (Örnek: `student100`)

| Araç | Kurulum Rehberi | Model A: Doğrudan IP:Port | Model B: DNS + SSL (HTTPS) | RAM Tüketimi | Hızlı Başlatma |
| :--- | :--- | :---: | :---: | :---: | :--- |
| **NovaShop UI** | [LAB-06](../LAB-06/README.md) | `http://<UBUNTU_IP>:8888` | `https://student100-novashop.devopsatolyesi.com` | ~512 MB | Helm / Kind |
| **Harbor Registry** | [02-harbor-setup.md](02-harbor-setup.md) | `http://<UBUNTU_IP>:18082` | `https://student100-harbor.devopsatolyesi.com` | ~1.5 GB | `sudo bash infra/harbor/install_harbor.sh` |
| **GitLab CE** | [01-gitlab-setup.md](01-gitlab-setup.md) | `http://<UBUNTU_IP>:8929` | `https://student100-gitlab.devopsatolyesi.com` | ~3.5 GB | `docker compose -f infra/gitlab/docker-compose.yml up -d` |
| **SonarQube** | [03-sonarqube-setup.md](03-sonarqube-setup.md) | `http://<UBUNTU_IP>:19000` | `https://student100-sonarqube.devopsatolyesi.com` | ~2.0 GB | `docker compose -f infra/sonarqube/docker-compose.yml up -d` |
| **Jenkins** | [04-jenkins-setup.md](04-jenkins-setup.md) | `http://<UBUNTU_IP>:18080` | `https://student100-jenkins.devopsatolyesi.com` | ~1.0 GB | `docker compose -f infra/jenkins/docker-compose.yml up -d` |
| **Nginx Proxy** | [05-nginx-ssl-setup.md](05-nginx-ssl-setup.md) | - | `80/443 (Edge)` | ~100 MB | `sudo bash infra/nginx/setup-ssl-edge.sh student100` |

---

## ⚡ Kurumsal DNS ve SSL Aktivasyonu (student100)

Eğer eğitim başlangıcında size bir öğrenci kodu (örneğin `student100`) ve alan adı tahsis edildiyse, Nginx Edge ve Wildcard Origin SSL sertifikasını tek komutla aktifleştirebilirsiniz:

```bash
cd ~/novashop
sudo bash infra/nginx/setup-ssl-edge.sh student100
```

Bu komuttan sonra yukarıdaki tabloda yer alan tüm `https://student100-*.devopsatolyesi.com` adresleri yeşil kilit ve Cloudflare güvencesiyle yayına başlayacaktır.

---

## 🛑 Kaynak Tasarrufu Pratiği (Start / Stop)

Laboratuvar sanal makinenizin RAM sınırlarını zorlamamak için işiniz biten araçları durdurun:

```bash
# Servisi durdurma (Veriler volume'de kalır):
cd ~/novashop/infra/<servis_adi> && docker compose stop

# Servisi yeniden başlatma:
cd ~/novashop/infra/<servis_adi> && docker compose start
```
