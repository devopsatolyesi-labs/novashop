# 05 — Jenkins İlk Kurulum Sihirbazı (Setup Wizard) Bypass ve Kimlik Doğrulama

Bu doküman; Jenkins Controller'ın açılış sihirbazına takılmadan doğrudan hazır (Dashboard) olarak ayağa kalkmasını ve parola yönetimini açıklar.

---

## 1. Karşılaşılan Sorunlar ve Hata Belirtileri

### Senaryo A: Unlock Jenkins ve Setup Wizard Ekranında Takılma
- **Hata Belirtisi:** Tarayıcıda `Unlock Jenkins` veya `Customize Jenkins / Install suggested plugins` ekranının açılması; otomasyon sürecinin insan müdahalesi beklemesi.
- **Kök Neden:** Jenkins konteyneri ilk kez başlatıldığında kurulum sihirbazının tamamlandığına dair işaretleme dosyaları oluşturulmamıştır.

### Senaryo B: initialAdminPassword Dosyası ve Rastgele Parola
- **Hata:** Otomasyon betiklerinin her kurulumda değişen 32 karakterlik rastgele hex parola ile çalışmak zorunda kalması.

### Senaryo C: REST API'de 403 No Valid Crumb Hatası
- **Hata Çıktısı:** `HTTP ERROR 403 No valid crumb was included in the request`
- **Kök Neden:** Jenkins varsayılan olarak CSRF koruması uygular. Crumb token göndermeyen istekleri reddeder.

---

## 2. Adım Adım Kodla Çözüm

### 1. Setup Wizard'ı Kodla Devreden Çıkarma
İki adımda sihirbaz tamamen kapatılır:
1. Docker Compose içine JVM bayrağı eklenir:
   ```yaml
   environment:
     - JAVA_OPTS=-Djenkins.install.runSetupWizard=false
   ```
2. Jenkins veri dizinine kurulu sürüm dosyaları yazılır:
   ```bash
   JENKINS_VER="2.541.3"
   echo "$JENKINS_VER" | sudo tee /var/lib/docker/volumes/jenkins_jenkins_home/_data/jenkins.install.UpgradeWizard.state
   echo "$JENKINS_VER" | sudo tee /var/lib/docker/volumes/jenkins_jenkins_home/_data/jenkins.install.InstallUtil.lastExecVersion
   ```

### 2. Standart Yönetici Şifresi Atama (BCrypt)
Jenkins kullanıcısının `config.xml` dosyasındaki şifre alanına doğrudan bcrypt hash yazılır:
```bash
# 1. WebSalla454!! için jbcrypt uyumlu hash üret
HASH=$(python3 -c "import bcrypt; print('#jbcrypt:' + bcrypt.hashpw(b'WebSalla454!!', bcrypt.gensalt(rounds=10, prefix=b'2a')).decode())")

# 2. admin kullanıcısının config.xml dosyasını güncelle
sudo sed -i "s|<passwordHash>.*</passwordHash>|<passwordHash>${HASH}</passwordHash>|"   /var/lib/docker/volumes/jenkins_jenkins_home/_data/users/admin_*/config.xml

# 3. Jenkins servisini yeniden başlat
sudo docker restart jenkins
```

### 3. Crumb Destekli REST API Çağrısı
Otomasyon scriptlerinde crumb alma ve kullanma şablonu:
```bash
CRUMB=$(curl -s -c /tmp/jk_cookie.txt -u "admin:WebSalla454!!" "http://127.0.0.1:18080/crumbIssuer/api/json" | grep -o '"crumb":"[^"]*"' | cut -d: -f2 | tr -d ")

curl -s -b /tmp/jk_cookie.txt -u "admin:WebSalla454!!" -H "Jenkins-Crumb: $CRUMB"   http://127.0.0.1:18080/api/json
```

---

## 3. Doğrulama Komutları

```bash
# 1. Sayfa başlığının Dashboard olduğunu doğrula:
curl -s -L -u "admin:WebSalla454!!" http://127.0.0.1:18080/ | grep -i "<title>"
```
*Beklenen Sonuç:* `<title>Dashboard - Jenkins</title>`.
