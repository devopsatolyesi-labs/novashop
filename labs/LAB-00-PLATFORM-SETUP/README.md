# LAB-00 — Platform Kurulumu ve DevOps Araçları Hazırlığı

Bu modül, kurumsal DevOps laboratuvarlarında kullanılacak temel platform araçlarının (**GitLab CE, Harbor OCI Registry, SonarQube, Jenkins ve Nginx Reverse Proxy**) sıfır bir Ubuntu sunucusu üzerinde adım adım ve kendi kendine yeten biçimde kurulmasını kapsar.

---

## 🎯 Temel İlkeler ve Yaklaşım

1. **Sıfır Sunucu Varsayımı:** Sunucuda `/opt/harbor` veya benzeri dizinler ya da araçlar önceden kurulu olmak zorunda değildir. Her rehber, sıfır bir sanal makinede baştan sona çalışacak şekilde tasarlanmıştır.
2. **Adım Adım (Manual) Öncelikli Rehber:** Öğrencinin ne yaptığını tam kavraması için yapılandırma dosyaları, portlar, çekirdek parametreleri ve yetkiler açıkça anlatılır.
3. **Hızlı Kurulum (Fast-Track) Seçeneği:** Manuel adımların ardından, acelesi olanlar için tek komutluk script veya compose seçenekleri sunulur.
4. **Sıfır `.env` Hatası:** Yapılandırmalar harici eksik `.env` dosyalarına bağımlı değildir; tüm çevre değişkenleri varsayılan değerlerle gömülüdür.
5. **Bellek (RAM) Yönetimi:** Tüm araçları aynı anda çalıştırmak zorunda değilsiniz. İlgili laba geçildiğinde aracı başlatıp, lab bitiminde durdurarak RAM tasarrufu sağlayabilirsiniz.

---

## 🛠️ Sıfır Sunucu Temel Hazırlığı (Adım 0)

Sıfır bir Ubuntu makinesinde Docker Engine ve Docker Compose v2 eklentisini kurun:

```bash
sudo apt-get update
sudo apt-get install -y ca-certificates curl git docker.io docker-compose-plugin
sudo usermod -aG docker $USER
```

*Not: Kullanıcı grubunu aktif etmek için oturumu kapatıp açabilir veya `newgrp docker` çalıştırabilirsiniz.*

---

## 🧭 DevOps Araçları, Port ve Kaynak Haritası

| Araç | Kurulum Rehberi | Dahili Port | RAM Tüketimi | Hızlı Başlatma Komutu |
| :--- | :--- | :---: | :---: | :--- |
| **Harbor Registry** | [02-harbor-setup.md](file:///labs/LAB-00-PLATFORM-SETUP/02-harbor-setup.md) | `18082` | ~1.5 GB | `sudo bash infra/harbor/install_harbor.sh` |
| **GitLab CE** | [01-gitlab-setup.md](file:///labs/LAB-00-PLATFORM-SETUP/01-gitlab-setup.md) | `8929` | ~3.5 GB | `docker compose -f infra/gitlab/docker-compose.yml up -d` |
| **SonarQube** | [03-sonarqube-setup.md](file:///labs/LAB-00-PLATFORM-SETUP/03-sonarqube-setup.md) | `19000` | ~2.0 GB | `docker compose -f infra/sonarqube/docker-compose.yml up -d` |
| **Jenkins** | [04-jenkins-setup.md](file:///labs/LAB-00-PLATFORM-SETUP/04-jenkins-setup.md) | `18080` | ~1.0 GB | `docker compose -f infra/jenkins/docker-compose.yml up -d` |
| **Nginx Proxy** | [05-nginx-ssl-setup.md](file:///labs/LAB-00-PLATFORM-SETUP/05-nginx-ssl-setup.md) | `80/443` | ~100 MB | `sudo systemctl restart nginx` |

---

## 🌐 Çift Erişim Modeli

Kurulan her bir servis iki yöntemle de erişilebilir şekilde yapılandırılmıştır:

### Model A: Doğrudan IP:Port Erişimi (DNS ve SSL Gerektirmez)
Sunucunun yerel IP adresiyle doğrudan tarayıcıdan bağlanabilirsiniz:
* **Harbor Web:** `http://<UBUNTU_IP>:18082`
* **GitLab Web:** `http://<UBUNTU_IP>:8929`
* **SonarQube:** `http://<UBUNTU_IP>:19000`
* **Jenkins:** `http://<UBUNTU_IP>:18080`

### Model B: Kurumsal DNS ve SSL ile Erişim
Eğer [05-nginx-ssl-setup.md](file:///labs/LAB-00-PLATFORM-SETUP/05-nginx-ssl-setup.md) rehberini uyguladıysanız standart alan adları:
* `https://studentXX-harbor.devopsatolyesi.com`
* `https://studentXX-gitlab.devopsatolyesi.com`
* `https://studentXX-sonarqube.devopsatolyesi.com`
* `https://studentXX-jenkins.devopsatolyesi.com`

---

## 🛑 Kaynak Tasarrufu Pratiği (Start / Stop)

Laboratuvar sanal makinenizin RAM sınırlarını zorlamamak için tamamlanan araçları durdurun:

```bash
# Servisi durdurma (Veriler volume'de kalır):
cd ~/novashop/infra/<servis_adi> && docker compose stop

# Servisi yeniden başlatma:
cd ~/novashop/infra/<servis_adi> && docker compose start
```
