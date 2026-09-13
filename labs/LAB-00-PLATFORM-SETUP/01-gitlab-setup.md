# Platform Hazırlık 01 — GitLab CE Kurulumu ve Yapılandırması

GitLab Community Edition (CE), kurumsal Git sürüm kontrolü ve GitLab CI/CD boru hatlarını çalıştırmak için Ubuntu sunucumuzda Docker konteyneri olarak yapılandırılır.

---

## 1. Ön Hazırlık ve Port Yapılandırması

Ubuntu sunucusunda port 80 ve 443 genel Nginx Reverse Proxy'ye ayrılmıştır. Bu nedenle GitLab:
* **Web Arayüzü:** `8929` portuna eşlenir.
* **SSH Portu:** `2224` portuna eşlenir (Host 22 portuyla çakışmaz).

---

## 2. Kurulum ve Başlatma

`infra/gitlab/` dizinindeki optimize edilmiş compose dosyasını kullanarak başlatın:

```bash
cd ~/novashop
docker compose -f infra/gitlab/docker-compose.yml up -d
```

> [!NOTE]
> GitLab ilk başlatıldığında veritabanı şemalarını ve yapılandırmayı tamamlaması **2-3 dakika** sürebilir. Durumu izlemek için:
> ```bash
> docker logs -f gitlab-ce
> ```

---

## 3. İlk Yönetici (root) Şifresini Alma

GitLab başladığında rastgele bir root şifresi üretir ve 24 saat boyunca saklar:

```bash
docker exec -it gitlab-ce grep 'Password:' /etc/gitlab/initial_root_password
```

**Giriş Bilgileri:**
* **Kullanıcı:** `root`
* **Şifre:** Yukarıdaki komutla dönen parola

---

## 4. Web Arayüzüne Erişim

### Model A: Doğrudan IP ile Erişim (DNS'siz)
Tarayıcınızdan şu adresi açın:
```text
http://<UBUNTU_IP>:8929
```

### Model B: Kurumsal DNS ve SSL ile Erişim
Eğer eğitmen/öğrenci DNS ve Nginx yapılandırmasını tamamladıysanız:
```text
https://studentXX-gitlab.devopsatolyesi.com
```

---

## 5. Servisi Durdurma (Kaynak Tasarrufu İçin)
Lab bittiğinde veya başka bir araca geçildiğinde RAM tasarrufu için:
```bash
docker compose -f infra/gitlab/docker-compose.yml down
```
*(Verileriniz volumes üzerinde güvenle saklanır, veri kaybı yaşanmaz).*
