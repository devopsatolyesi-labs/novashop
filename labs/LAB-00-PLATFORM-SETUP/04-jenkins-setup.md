# Platform Hazırlık 04 — Jenkins Controller Kurulumu

Jenkins; klasik ve yaygın boru hattı otomasyonlarını gerçekleştirmek ve Docker-in-Docker işlerini koşturmak için kullanılır.

---

## 1. Kurulum ve Başlatma

`infra/jenkins/docker-compose.yml` dosyası host'un Docker soketini (`/var/run/docker.sock`) bağlayarak Jenkins'in doğrudan Docker imajları oluşturmasını sağlar:

```bash
cd ~/novashop
docker compose -f infra/jenkins/docker-compose.yml up -d
```

---

## 2. İlk Yönetici (Admin) Şifresini Alma

Jenkins ilk kurulumda konsola ve bir dosyaya tek kullanımlık güvenlik şifresi yazar:

```bash
docker exec -it jenkins cat /var/jenkins_home/secrets/initialAdminPassword
```

---

## 3. Web Arayüzüne Erişim

* **Host Portu:** `18080` (Agent Portu: `50000`)

### Model A: Doğrudan IP ile Erişim
```text
http://<UBUNTU_IP>:18080
```

### Model B: Kurumsal DNS ve SSL ile Erişim
```text
https://studentXX-jenkins.devopsatolyesi.com
```

Şifreyi yapıştırıp **Install Suggested Plugins** seçeneği ile temel eklentileri yükleyin.
