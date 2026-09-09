# NovaShop DevOps Store — Merkezi Sorun Giderme Kılavuzu (Master Troubleshooting Guide)

Bu kılavuz; NovaShop laboratuvarları ve dağıtım süreçleri boyunca karşılaşılabilecek en yaygın hata belirtilerini, kök nedenlerini, teşhis komutlarını ve güvenli çözüm yollarını tek bir merkezi referansta toplar.

---

## 1. Hızlı Sorun Arama Matrisi

| Kategori | Hata Belirtisi | Muhtemel Kök Neden | Hızlı Teşhis Komutu |
|---|---|---|---|
| **Git** | `CONFLICT (content): Merge conflict in ...` | İki branch'in aynı dosyadaki aynı satırları farklı değiştirmesi | `git status`, `git diff` |
| **Git** | `fatal: refusing to merge unrelated histories` | Birbirinden bağımsız başlatılmış iki git reposunun birleştirilmeye çalışılması | `git log --oneline --graph` |
| **AWS / SSH** | `Connection timed out` (Port 22) | Öğrencinin genel internet IP'sinin değişmesi veya SG kuralının eksikliği | `curl -s https://checkip.amazonaws.com` |
| **AWS / SSH** | `Permissions 0644 for 'key.pem' are too open` | SSH özel anahtarının aşırı izinlere sahip olması | `ls -l <KEY_PATH>` |
| **AWS / RDS** | `nc: connect to ... port 3306 timed out` | RDS SG'de EC2 SG kaynak kuralının eksik olması veya yanlış subnet | `aws ec2 describe-security-groups` |
| **AWS / RDS** | `SSL connection error: certificate verify failed` | CA bundle dosyasının eksikliği veya hostname uyumsuzluğu | `openssl x509 -in /etc/ssl/certs/rds-ca-bundle.pem -text` |
| **Docker** | `bind: address already in use 8888` | Portun başka bir yerel süreç veya konteyner tarafından tutulması | `lsof -i :8888` veya `docker ps` |
| **Docker** | `Exited (137)` / `OOMKilled` | Konteynerin verilen bellek sınırını (RAM limit) aşması | `docker inspect <NAME> --format '{{.State.OOMKilled}}'` |
| **Docker** | `Read-only file system` | Salt-okunur kök dosya sistemine geçici dizin (`/tmp`) tanımlanmaması | `docker logs <NAME> \| grep -i "read-only"` |
| **K8s** | `CrashLoopBackOff` | Konteynerin başlama aşamasında istisna fırlatması veya JVM OOM | `kubectl logs <POD> --previous`, `kubectl describe pod <POD>` |
| **K8s** | `0/1 nodes available: Insufficient memory` | Kind kümesindeki worker düğümlerinin toplam RAM kapasitesinin dolması | `kubectl describe nodes \| grep -A 5 "Allocated resources"` |
| **K8s** | `Readiness probe failed: HTTP probe status 503` | `initialDelaySeconds` süresinin uygulamanın başlama süresinden kısa olması | `kubectl describe pod <POD> \| grep -A 5 "Readiness"` |
| **Argo CD** | `ComparisonError: repository not found` | Git repo URL'sinin hatalı olması veya erişim yetkisinin eksikliği | `kubectl describe app <APP> -n argocd` |
| **Argo CD** | `OutOfSync` (Sarı Durum) | Kümede manuel değişiklik yapılması (Drift) veya senkronizasyon kuralı | `argocd app diff <APP>` |
| **CI/CD** | `409 Conflict: Tag already exists` | Harbor üzerinde Immutable Tag koruması olan bir etiketin üzerine yazma denemesi | Pipeline logları |
| **CI/CD** | `AssumeRoleWithWebIdentity: AccessDenied` | GitHub Actions OIDC Trust Policy'de repo adı veya condition uyuşmazlığı | `aws iam get-role --role-name <ROLE>` |

---

## 2. Kategori Bazlı Detaylı Teşhis ve Çözümler

### 1. Git ve GitHub Sorunları

#### Senaryo: `Merge Conflict` Durumu
- **Belirti:** `git merge feature-branding` komutundan sonra terminalde `Automatic merge failed; fix conflicts and then commit the result` uyarısı.
- **Teşhis:**
  ```bash
  git status
  ```
  Çıktıda `both modified:` olarak listelenen dosyalar çakışan dosyalardır.
- **Güvenli Çözüm:**
  1. İlgili dosyayı açın ve `<<<<<<< HEAD`, `=======`, `>>>>>>>` işaretlerini bulun.
  2. Ekip kararına göre doğru kod bloğunu seçip konflikt işaretlerini silin.
  3. Değişikliği ekleyip merge işlemini tamamlayın:
     ```bash
     git add <DOSYA_YOLU>
     git commit -m "fix(merge): resolve conflict in <DOSYA>"
     ```

---

### 2. AWS ve Ağ Güvenliği Sorunları

#### Senaryo: EC2'ye SSH ile Bağlanırken Zaman Aşımı (`Operation timed out`)
- **Belirti:** `ssh -i key.pem ubuntu@<IP>` komutu yanıt vermiyor.
- **Muhtemel Neden:** Öğrencinin internet servis sağlayıcısı (ISS) dinamik IP değiştirmiştir ve Güvenlik Grubundaki kural eski IP'de kalmıştır.
- **Teşhis:**
  ```bash
  MY_CURRENT_IP=$(curl -s https://checkip.amazonaws.com)
  echo "Guncel IP: $MY_CURRENT_IP"
  ```
- **Güvenli Çözüm:**
  AWS CLI ile Security Group kuralını güncelleyin:
  ```bash
  aws ec2 authorize-security-group-ingress \
    --group-id <WEB_SG_ID> \
    --protocol tcp --port 22 \
    --cidr ${MY_CURRENT_IP}/32 \
    --region <AWS_REGION>
  ```

#### Senaryo: EC2'den Private RDS'e Bağlantı Kurulamıyor
- **Belirti:** `mysql -h <RDS_ENDPOINT> -u novashop -p` komutu `Can't connect to MySQL server` veya zaman aşımı veriyor.
- **Teşhis:**
  1. Port düzeyinde erişim testi yapın:
     ```bash
     nc -zv -w 5 <RDS_ENDPOINT> 3306
     ```
  2. Eğer başarısızsa RDS Güvenlik Grubunun gelen kurallarını inceleyin:
     ```bash
     aws ec2 describe-security-groups --group-ids <RDS_SG_ID>
     ```
- **Güvenli Çözüm:** RDS Güvenlik Grubunda (inbound) TCP 3306 portuna kaynak olarak `novashop-web-sg` Security Group kimliğini atayın (`0.0.0.0/0` asla verilmez).

---

### 3. Konteyner ve Docker Compose Sorunları

#### Senaryo: Konteyner Çökmesi (`Exit Code 137` / `OOMKilled`)
- **Belirti:** `docker ps -a` komutunda konteynerin durduğu ve çıkış kodunun `137` olduğu görülür.
- **Kök Neden:** İşletim sisteminin OOM Killer mekanizması, konteyner tahsis edilen RAM tavanını aştığı için süreci öldürmüştür.
- **Teşhis:**
  ```bash
  docker inspect <CONTAINER_NAME> --format '{{json .State}}' | grep -i oom
  ```
- **Güvenli Çözüm:**
  1. Konteyner bellek sınırını yükseltin (örn. `512M` -> `768M`).
  2. Java uygulamalarında JVM heap sınırını container sınırının %75'i ile sınırlandırın:
     ```bash
     -e JAVA_TOOL_OPTIONS="-XX:MaxRAMPercentage=75.0"
     ```

---

### 4. Kubernetes ve Helm Sorunları

#### Senaryo: Pod'ların `CrashLoopBackOff` Durumuna Geçmesi
- **Belirti:** Pod `Running` durumuna geçemiyor, sürekli yeniden başlıyor.
- **Teşhis:**
  ```bash
  # Çöken konteynerin son hata loglarını oku
  kubectl logs <POD_NAME> -n novashop --previous

  # Pod olaylarını incele
  kubectl describe pod <POD_NAME> -n novashop
  ```
- **Güvenli Çözüm:** Loglardaki `Exception` veya yapılandırma hatasını giderin; gerekirse ConfigMap/Secret değerlerini güncelleyip pod'u yeniden başlatın.

---

### 5. GitOps ve Argo CD Sorunları

#### Senaryo: Canlı Durum ile Git Arasında Sapma (Configuration Drift)
- **Belirti:** Argo CD panelinde uygulama `OutOfSync` durumunda sarı renkle işaretlenir.
- **Teşhis:**
  ```bash
  argocd app diff novashop-ui-gitops
  ```
  Komut Git manifestosu ile canlı Kubernetes nesnesi arasındaki farkı yeşil/kırmızı diff olarak gösterir.
- **Güvenli Çözüm:**
  - Eğer değişiklik yetkisiz bir manuel müdahale ise: Argo CD üzerinden `Sync` butonuna basarak Git'teki durumu zorla uygulayın (veya `automated.selfHeal: true` aktif edin).
  - Eğer değişiklik kalıcı olması istenen bir durumsa: Değişikliği Git reposundaki `values.yaml` dosyasına commit edin.

---

## 3. Altın Güvenlik ve Kurtarma Kuralları

1. **Hiçbir zaman `chmod -R 777` veya `docker run --privileged` çalıştırmayın.**
2. **Sorunu çözmek için veritabanı portlarını asla `0.0.0.0/0` ile dışarıya açmayın.**
3. **Loglarda şifre veya secret aramadan önce ekran paylaşımını veya log kaydını maskeleyin.**
4. **Sistem kilitlendiğinde veya bellek tükendiğinde PROFILES.md kurallarına göre bir önceki profili durdurup (`down -v`) kaynakları serbest bırakın.**
