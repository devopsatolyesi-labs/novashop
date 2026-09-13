# Platform Hazırlık 03 — SonarQube ve PostgreSQL Kurulumu

SonarQube; statik kod analizi (SAST), kod kokuları (code smells), güvenlik açıkları ve test kapsamını (coverage) ölçmek için kurulan platformdur.

---

## 1. Çekirdek (Kernel) Ayarı

SonarQube'un dahili Elasticsearch motoru Linux'ta vm.max_map_count değerinin yüksek olmasını gerektirir. Ubuntu sunucunuzda şu komutu çalıştırın:

```bash
sudo sysctl -w vm.max_map_count=524288
echo "vm.max_map_count=524288" | sudo tee -a /etc/sysctl.conf
```

---

## 2. Kurulum ve Başlatma

PostgreSQL 15 ve SonarQube LTS içeren compose dosyasını başlatın:

```bash
cd ~/novashop
docker compose -f infra/sonarqube/docker-compose.yml up -d
```

Durumu kontrol etmek için:
```bash
docker ps --filter "name=sonarqube"
```

---

## 3. Web Arayüzüne Erişim ve İlk Giriş

* **Dahili / Host Portu:** `19000`

### Model A: Doğrudan IP ile Erişim
```text
http://<UBUNTU_IP>:19000
```

### Model B: Kurumsal DNS ve SSL ile Erişim
```text
https://studentXX-sonarqube.devopsatolyesi.com
```

**Varsayılan Giriş:**
* **Kullanıcı:** `admin`
* **Şifre:** `admin`

*(İlk girişte sistem sizden yeni ve güçlü bir şifre belirlemenizi isteyecektir).*
