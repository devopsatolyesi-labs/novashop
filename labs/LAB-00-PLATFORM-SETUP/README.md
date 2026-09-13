# LAB-00 — Platform Kurulumu ve DevOps Araçları Hazırlığı

Bu modül, ilerleyen lablarda kullanacağımız kurumsal DevOps araçlarının (**GitLab CE, Harbor OCI Registry, SonarQube, Jenkins ve Nginx Reverse Proxy**) Ubuntu sunucusu üzerinde sıfırdan kurulmasını ve yapılandırılmasını kapsar.

---

## 🎯 Neden Bu Modül Var?

1. **Bağımsızlık:** Herhangi bir laba (örneğin CI/CD veya DevSecOps) doğrudan atlamak istediğinizde, kurulum adımlarını geçmiş labların içinde aramak zorunda kalmazsınız.
2. **Kaynak Tasarrufu:** Ubuntu sunucunuzun RAM belleğini verimli kullanmak için, yalnızca o an ihtiyacınız olan aracı tek bir komutla ayağa kaldırabilirsiniz.
3. **Çift Erişim Modeli:** Kurulan her araç iki yöntemle de erişilebilir:
   * **Model A (Doğrudan IP:Port):** `http://<UBUNTU_IP>:<PORT>` (DNS ve SSL yapılandırması gerektirmez).
   * **Model B (Kurumsal DNS + SSL):** `https://studentXX-<tool>.devopsatolyesi.com` (Nginx + Cloudflare Wildcard SSL).

---

## 🧭 Araçlar ve Port Haritası

| Araç | Kurulum Rehberi | Dahili Port | Doğrudan IP Erişimi | DNS + SSL Erişimi | Hızlı Başlatma Komutu |
| :--- | :--- | :---: | :--- | :--- | :--- |
| **GitLab CE** | [01-gitlab-setup.md](file:///labs/LAB-00-PLATFORM-SETUP/01-gitlab-setup.md) | `8929` | `http://<UBUNTU_IP>:8929` | `https://studentXX-gitlab.devopsatolyesi.com` | `docker compose -f infra/gitlab/docker-compose.yml up -d` |
| **Harbor Registry** | [02-harbor-setup.md](file:///labs/LAB-00-PLATFORM-SETUP/02-harbor-setup.md) | `18082` | `http://<UBUNTU_IP>:18082` | `https://studentXX-harbor.devopsatolyesi.com` | `sudo bash infra/harbor/install_harbor.sh` |
| **SonarQube** | [03-sonarqube-setup.md](file:///labs/LAB-00-PLATFORM-SETUP/03-sonarqube-setup.md) | `19000` | `http://<UBUNTU_IP>:19000` | `https://studentXX-sonarqube.devopsatolyesi.com` | `docker compose -f infra/sonarqube/docker-compose.yml up -d` |
| **Jenkins** | [04-jenkins-setup.md](file:///labs/LAB-00-PLATFORM-SETUP/04-jenkins-setup.md) | `18080` | `http://<UBUNTU_IP>:18080` | `https://studentXX-jenkins.devopsatolyesi.com` | `docker compose -f infra/jenkins/docker-compose.yml up -d` |
| **Nginx Proxy** | [05-nginx-ssl-setup.md](file:///labs/LAB-00-PLATFORM-SETUP/05-nginx-ssl-setup.md) | `80/443` | `http://<UBUNTU_IP>` | `https://studentXX-*.devopsatolyesi.com` | `sudo systemctl restart nginx` |

---

## ⚡ Hızlı Başlangıç (Fast-Track)

İlgili laba başlamadan önce ihtiyaç duyduğunuz aracın altındaki rehbere tıklayarak veya `infra/` dizinindeki compose dosyalarını kullanarak aracı saniyeler içinde başlatabilirsiniz.
