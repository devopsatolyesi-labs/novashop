# Platform Hazırlık 02 — Harbor OCI Registry ve Trivy Kurulumu

Harbor; kurumsal ölçekte konteyner imajlarını depolamak, güvenlik açıklarını (Trivy ile) taramak ve imaj yaşam döngüsünü yönetmek için kullanılan kurumsal düzeyde bir açık kaynak OCI Registry platformudur.

Bu rehber, sunucunuzda `/opt/harbor` veya Harbor bileşenleri **hiç bulunmasa bile** sıfırdan adım adım kurulum yapmanızı sağlar.

---

## 🧭 Genel Bakış ve Port Yapılandırması

* **Erişim Modeli:** HTTP (SSL ve alan adı zorunluluğu olmadan doğrudan IP ile çalışır)
* **Harbor Web & Registry Portu:** `18082` (Nginx 80/443 portlarıyla çakışmaz)
* **Dahili Güvenlik Tarayıcısı:** Trivy Scanner etkin
* **Varsayılan Giriş Bilgileri:**
  * **Kullanıcı:** `admin`
  * **Şifre:** `Harbor12345`

---

## 🛠️ Ön Koşul: Docker ve Docker Compose Kontrolü

Sıfır bir Ubuntu makinesinde Docker Engine ve Docker Compose v2 eklentisinin kurulu olduğundan emin olun:

```bash
# Docker ve Compose kurulu değilse:
sudo apt-get update
sudo apt-get install -y ca-certificates curl docker.io docker-compose-plugin
sudo usermod -aG docker $USER
```

Kurulumu doğrulayın:
```bash
docker --version
docker compose version
```

---

## 📋 Ana Yöntem: Adım Adım Manuel Kurulum

### Adım 1: Kurulum Dizinini Oluşturma ve Paketi İndirme

Harbor kurulum dosyalarını `/opt/harbor` dizinine açacağız:

```bash
# 1. Kurulum dizinini oluşturun
sudo mkdir -p /opt/harbor

# 2. Geçici dizine geçip Harbor Online Installer paketini indirin
cd /tmp
curl -fSLo harbor-online-installer-v2.10.0.tgz \
  https://github.com/goharbor/harbor/releases/download/v2.10.0/harbor-online-installer-v2.10.0.tgz

# 3. Paketi /opt dizinine açın (içerik /opt/harbor olarak açılır)
sudo tar -xzf harbor-online-installer-v2.10.0.tgz -C /opt/
cd /opt/harbor
```

---

### Adım 2: Yapılandırma Dosyasını (`harbor.yml`) Hazırlama

Harbor'ı SSL ve DNS karmaşası olmadan, doğrudan sunucu IP'si ve `18082` HTTP portuyla çalışacak şekilde ayarlayın:

1. Örnek şablonu kopyalayın:
   ```bash
   sudo cp /opt/harbor/harbor.yml.tmpl /opt/harbor/harbor.yml
   ```

2. Sunucu yerel IP adresinizi öğrenin:
   ```bash
   LOCAL_IP=$(hostname -I | awk '{print $1}')
   echo "Sunucu IP: $LOCAL_IP"
   ```

3. `harbor.yml` dosyasını HTTP moduna getirin (HTTPS bloğunu kapatın ve portu 18082 yapın):
   ```bash
   # Hostname ve port güncellemesi
   sudo sed -i "s/hostname: reg.mydomain.com/hostname: ${LOCAL_IP}/" /opt/harbor/harbor.yml
   sudo sed -i 's/port: 80/port: 18082/' /opt/harbor/harbor.yml

   # HTTPS bloğunu devre dışı bırakma (Sertifika hatası vermemesi için)
   sudo sed -i 's/^https:/#https:/' /opt/harbor/harbor.yml
   sudo sed -i 's/^  port: 443/#  port: 443/' /opt/harbor/harbor.yml
   sudo sed -i 's/^  certificate:/#  certificate:/' /opt/harbor/harbor.yml
   sudo sed -i 's/^  private_key:/#  private_key:/' /opt/harbor/harbor.yml
   ```

---

### Adım 3: Docker Daemon Güvensiz Registry (Insecure Registry) Ayarı

Harbor SSL olmadan (HTTP) çalıştığı için Docker daemon'ın bu porta güvensiz erişimine izin verilmelidir:

```bash
sudo mkdir -p /etc/docker
cat << 'DAEMON_EOF' | sudo tee /etc/docker/daemon.json
{
  "insecure-registries": ["${LOCAL_IP}:18082", "127.0.0.1:18082", "localhost:18082"]
}
DAEMON_EOF

# Docker servisini yeniden başlatın
sudo systemctl restart docker
```

---

### Adım 4: Harbor Kurulumunu Başlatma (Trivy Dahil)

Kurulum betiğini Trivy zafiyet tarayıcısı bayrağı ile çalıştırın:

```bash
cd /opt/harbor
sudo ./install.sh --with-trivy
```

*Açıklama:* Bu işlem Harbor imajlarını çeker, konfigürasyonu üretir ve tüm servisleri (`harbor-core`, `harbor-db`, `registry`, `trivy-adapter`, `nginx`) Docker konteyneri olarak ayağa kaldırır.

**Konteynerlerin Durumunu Kontrol Etme:**
```bash
cd /opt/harbor
sudo docker compose ps
```
*Beklenen çıktı:* Tüm Harbor konteynerleri `Up` (healthy) durumunda olmalıdır.

---

### Adım 5: Web Arayüzüne Giriş ve İlk Projeyi Açma

1. Tarayıcınızdan web arayüzünü açın:
   ```text
   http://<UBUNTU_IP>:18082
   ```
2. Giriş yapın:
   * **Username:** `admin`
   * **Password:** `Harbor12345`

3. NovaShop projeleri için isim alanı oluşturun:
   * Sol menüden **Projects** sekmesine tıklayın.
   * **+ New Project** butonuna basın.
   * **Project Name:** `novashop` yazın.
   * **Access Level:** **Public** kutucuğunu işaretleyin (Böylece Kubernetes ve Kind kümesi imaj çekerken k8s secret gerektirmez).
   * **OK** butonuna basarak kaydedin.

---

### Adım 6: Docker CLI ile Giriş ve Test

Sunucu terminalinden Harbor'a giriş yapın ve test imajı yükleyin:

```bash
# 1. Harbor'a giriş yapın
docker login ${LOCAL_IP}:18082 -u admin -p Harbor12345

# 2. Örnek bir hafif imaj indirin ve etiketleyin
docker pull alpine:latest
docker tag alpine:latest ${LOCAL_IP}:18082/novashop/alpine:test

# 3. Harbor'a gönderin (push)
docker push ${LOCAL_IP}:18082/novashop/alpine:test
```

*Beklenen çıktı:* İmaj katmanları başarıyla `Pushed` edilmeli ve Harbor web panelinde `novashop/alpine` olarak görünmelidir.

---

## ⚡ Alternatif Yöntem: Tek Komutla Hızlı Kurulum (Fast-Track)

Yukarıdaki tüm adımları (dizin açma, indirme, IP tespiti, harbor.yml oluşturma, daemon.json güncelleme ve Trivy ile kurulum) tek bir komutla tamamlamak isterseniz:

```bash
cd ~/novashop
sudo bash infra/harbor/install_harbor.sh
```

---

## 🛑 Servisi Durdurma ve Başlatma (RAM Tasarrufu)

Harbor arka planda 8-9 adet konteyner çalıştırır (~1.5 GB RAM). İhtiyaç duymadığınız lablarda RAM'i boşa çıkarmak için:

```bash
# Harbor'ı durdurun (Verileriniz /data altında güvenle korunur)
cd /opt/harbor && sudo docker compose stop

# Tekrar ihtiyaç duyduğunuzda başlatın:
cd /opt/harbor && sudo docker compose start
```
