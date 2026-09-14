# 08 — CI/CD Entegrasyonu: Harbor Health, Jenkins SonarQube ve Docker Soketi

## 1. Problem: Harbor Doğrulama Betiğinde 404 Not Found Hatası

### Semptom
LAB-07 ve LAB-08 laboratuvarlarında Harbor doğrulama betiği (`verify-lab-07.sh` veya `verify-tools.sh`) çalıştırıldığında Harbor sağlık kontrolü 404 hatası veriyordu:
```text
HTTP/1.1 404 Not Found
Harbor API health check failed!
```

### Kök Neden
Eski Harbor sürümlerinde sağlık kontrolü için `/api/v2.0/ping` kullanılıyordu. Güncel Harbor v2.8+ sürümlerinde bu endpoint kaldırılmış veya `/api/v2.0/systeminfo` ya da `/api/v2.0/health` ile değiştirilmiştir.

### Çözüm
Doğrulama betiğindeki endpoint `/api/v2.0/systeminfo` olarak güncellendi:
```bash
# Harbor sistem durumunu sorgulama
curl -s -u "admin:${HARBOR_ADMIN_PASSWORD}" "http://localhost:18082/api/v2.0/systeminfo" | jq '.harbor_version'
```

---

## 2. Problem: Jenkins Pipeline "withSonarQubeEnv: No such DSL method" Hatası

### Semptom
Jenkins üzerinde `Jenkinsfile` çalıştırıldığında analiz aşamasında pipeline çöküyordu:
```text
java.lang.NoSuchMethodError: No such DSL method 'withSonarQubeEnv' found among steps
```

### Kök Neden
Jenkins Controller başlatıldığında standart eklentiler kurulmuş ancak `SonarQube Scanner for Jenkins` (`sonar`) eklentisi eksik kalmıştı. Jenkinsfile içindeki `withSonarQubeEnv` adımı bu eklentiye bağımlıdır.

### Çözüm
1. Jenkins CLI veya REST API üzerinden `sonar` eklentisi otomatik olarak kuruldu:
   ```bash
   jenkins-plugin-cli --plugins sonar:latest
   ```
2. Jenkins **Manage Jenkins > System** menüsünden SonarQube sunucusu `NovaShop-SonarQube` adı ve erişim token'ı ile yapılandırıldı.

---

## 3. Problem: Jenkins ve GitLab Runner Docker Soket İzinleri (`permission denied`)

### Semptom
CI pipeline adımlarında `docker build` veya `docker push` komutu çalıştırıldığında şu hata alınıyordu:
```text
Got permission denied while trying to connect to the Docker daemon socket at unix:///var/run/docker.sock
```

### Kök Neden
`/var/run/docker.sock` soket dosyası varsayılan olarak `root:docker` mülkiyetindedir ve `0660` izinlerine sahiptir. Jenkins veya GitLab Runner ajanı konteyner içinde `jenkins` kullanıcısı (UID 1000) ile çalıştığında bu sokete yazma hakkı bulunmamaktadır.

### Çözüm
1. **Grup Eşleme Yaklaşımı (En Güvenli):** Host üzerindeki `docker` grubunun GID'si tespit edilip Jenkins konteynerine grup olarak bağlandı (`--group-add`).
2. **Lab Ortamında Hızlı Çözüm:**
   ```bash
   sudo chmod 666 /var/run/docker.sock
   ```
   *Not:* Üretim ortamlarında Docker soketini `666` yapmak yerine her zaman rootless Docker veya özel TLS soketi kullanılmalıdır.
