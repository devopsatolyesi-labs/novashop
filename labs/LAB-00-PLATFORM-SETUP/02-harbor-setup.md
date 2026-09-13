# Platform Hazırlık 02 — Harbor OCI Registry ve Trivy Kurulumu

Harbor; kurumsal ölçekte konteyner imajlarını depolamak, imzalamak ve Trivy tarayıcısı ile zafiyet analizi yapmak için kullanılan açık kaynaklı bir Registry platformudur.

---

## 1. Kurulum Scriptini Çalıştırma

`infra/harbor/install_harbor.sh` scripti Harbor'ın en güncel stabil sürümünü indirir, HTTP portunu **18082** olarak ayarlar ve **Trivy** güvenlik tarayıcısını etkinleştirerek kurar:

```bash
cd ~/novashop
bash infra/harbor/install_harbor.sh
```

---

## 2. Web Arayüzüne Erişim ve Giriş

### Model A: Doğrudan IP ile Erişim (DNS'siz)
```text
http://<UBUNTU_IP>:18082
```

### Model B: Kurumsal DNS ve SSL ile Erişim
```text
https://studentXX-harbor.devopsatolyesi.com
```

**Varsayılan Giriş Bilgileri:**
* **Kullanıcı:** `admin`
* **Şifre:** `Harbor12345`

---

## 3. İlk Projeyi (novashop) Oluşturma

1. Harbor paneline giriş yapın.
2. Sol menüden **Projects** sekmesine tıklayın.
3. **+ New Project** butonuna basın:
   * **Project Name:** `novashop`
   * **Access Level:** Public (işaretleyin veya private bırakıp robot hesabı açın)
4. **OK** butonuna basarak projeyi kaydedin.

---

## 4. Docker CLI ile Harbor'a Giriş Yapma

Docker daemon'ın güvensiz (HTTP) registry olarak Harbor'ı kabul etmesi için `/etc/docker/daemon.json` dosyasına ekleme yapın (Doğrudan IP kullanıyorsanız):

```bash
sudo mkdir -p /etc/docker
cat << 'JSON' | sudo tee /etc/docker/daemon.json
{
  "insecure-registries": ["<UBUNTU_IP>:18082"]
}
JSON

sudo systemctl restart docker
docker login <UBUNTU_IP>:18082 -u admin -p Harbor12345
```
