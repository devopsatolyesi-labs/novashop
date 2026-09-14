# NovaShop DevOps & Cloud Masterclass — Eğitmen Ders Anlatım ve Rehber Kitapçığı

---

## 🎯 Kitapçığın Amacı ve Kullanım Kılavuzu

Bu kitapçık, **NovaShop DevOps, Cloud ve DevSecOps** eğitim serisini yürüten eğitmenler için hazırlanmış kapsamlı bir rehberdir. 

Her laboratuvar için eğitmenin ders sırasında:
1. **Sahne Kurulumu (Giriş Hikayesi):** Derse başlarken öğrencilerin ilgisini çekecek "Neden buradayız?" sorusunun yanıtı ve gerçek hayat vaka analizi (War Story),
2. **Mimari Gerekçe (Rationale):** Neden bu aracı seçtik? Alternatifleri nelerdir?
3. **Öğrencilere Sorulacak Sorular (Soru - Cevap):** Dersi interaktif tutacak kilit sorular ve eğitmenin açıklaması,
4. **Production & Enterprise Best Practices:** Kurumsal şirketlerde bu iş nasıl yapılır?
5. **Sık Karşılaşılan Öğrenci Hataları ve Anında Çözümler (Gotchas):** Öğrenci takıldığında eğitmenin uygulayacağı reçeteler,
6. **İş Mülakatı Tüyoları:** Şirketlerin adaylarda aradığı kritik cevaplar yer almaktadır.

---

## 🗺️ Laboratuvar Bazlı Eğitmen Rehberi

---

### LAB-00: Platform Kurulumu ve DevOps Araçları

#### 1. Eğitmenin Giriş Konuşması (Sahne Kurulumu)
> *"Arkadaşlar, kurumsal bir şirkete DevOps mühendisi olarak girdiğiniz ilk gün size boş bir Linux sunucusu veya cloud hesabı verirler ve 'Hadi ortamı kur' derler. Bugün yapacağımız şey, modern bir teknoloji şirketinin ihtiyaç duyduğu tüm omurgayı (GitLab, Harbor, SonarQube, Jenkins, Nginx Edge) sıfırdan ve birbiriyle çakışmadan ayağa kaldırmak. Bu laboratuvar bittiğinde elinizde tam teşekküllü bir 'DevOps Veri Merkezi' olacak."*

#### 2. Mimari Kararlar ve Rationale
* **Neden Port Çakışmalarını Önlemek İçin 18080/18082/19000 Seçtik?**
  * Standart portlar (80, 8080, 9000) prodüksiyon ortamında veya aynı sunucuda başka uygulamalar tarafından kapılabilir. Cockpit 9090 portunu dinler, Jenkins varsayılan 8080'dedir. Her servise benzersiz, 10000+ yüksek portlar atayarak çakışmaları sıfıra indirdik.
* **Neden Nginx Reverse Proxy (Edge)?**
  * Geliştiricilerin `IP:18082` gibi ezberlemesi zor portlar yerine `harbor.devopsatolyesi.com` gibi standart SSL'li kurumsal alan adlarıyla çalışmasını sağlamak.

#### 3. Öğrencilere Sorulacak Sorular
* **Soru:** *"Bir sunucuda `docker compose up -d` dediğimizde RAM anında tükenirse ilk bakacağımız yer neresidir?"*
  * **Beklenen Cevap:** `docker stats` ve `dmesg -T | grep -i oom` komutları. Konteyner bazlı bellek sınırları (`limits.memory`) belirlenmediğinde tek bir Java/GitLab süreci tüm sunucuyu kilitleyebilir.
* **Soru:** *"Neden hem doğrudan IP:Port (Model A) hem de Nginx SSL (Model B) desteği tasarladık?"*
  * **Beklenen Cevap:** Yüksek erişilebilirlik ve arıza toleransı (Fallback). Eğer DNS veya SSL sağlayıcısında kesinti olursa, doğrudan IP üzerinden operasyon asla durmaz.

#### 4. Production & Gerçek Hayat Best Practices
* Gerçek hayatta GitLab, SonarQube, Jenkins gibi araçlar tek bir sanal makinede değil; AWS üzerinde yönetilen servisler (EKS, RDS, S3) veya izole VM'ler üzerinde küme (Cluster) olarak çalışır.
* Veritabanları konteyner içinde değil, AWS RDS Multi-AZ veya Cloud SQL üzerinde barındırılır.

#### 5. Sık Yapılan Hatalar ve Çözümler
* **Hata:** GitLab ayağa kalkarken `502 Whoops, GitLab is taking too much time to respond`.
  * **Eğitmen Müdahalesi:** Öğrenciye panik yapmamasını söyleyin. GitLab 15'ten fazla alt servis (Puma, Sidekiq, Redis, Gitaly) başlatır ve ilk açılış 2-3 dakika sürer. `docker logs -f gitlab-ce` ile Puma'nın hazır oluşunu gösterin.

---

### LAB-01: Git Temelleri, GitHub ve Kontrollü Merge Conflict Çözümü

#### 1. Eğitmenin Giriş Konuşması (Sahne Kurulumu)
> *"Yazılım dünyasında en çok korkulan şeylerden biri 'Merge Conflict'tir. Birçok junior mühendis conflict çıktığında panikleyip branch'ini siler. Bugün bir e-ticaret sitesinin ürün kataloğunda (`products.json`) bilerek aynı satırı iki farklı branch'te değiştireceğiz ve conflict'i ameliyat gibi adım adım hem terminalde hem GitHub'da çözeceğiz."*

#### 2. Mimari Kararlar ve Rationale
* **Neden `credential.helper store`?**
  * GitHub 2021'den beri terminal parola kimlik doğrulamasını kapattı. Öğrencinin her push işleminde 40 karakterlik PAT (Personal Access Token) kopyalamaya çalışarak dersten kopmasını engellemek için yerel güvenli saklama kullanılır.

#### 3. Öğrencilere Sorulacak Sorular
* **Soru:** *"Fast-Forward merge ile 3-Way merge arasındaki fark nedir?"*
  * **Beklenen Cevap:** Ana branch'te yeni commit yoksa HEAD doğrudan ileri sarılır (Fast-Forward). Eğer ana branch'te de başka commitler varsa Git yeni bir "Merge Commit" oluşturur (3-Way).
* **Soru:** *"`<<<<<<< HEAD` ve `>>>>>>>` işaretleri ne anlama gelir?"*
  * **Beklenen Cevap:** `HEAD`, şu an bulunduğumuz branch'teki satırları; alttaki kısım ise birleştirmeye çalıştığımız daldaki satırları gösterir. Eşittir (`=======`) çizgisi ise çakışan iki bloğun sınırıdır.

#### 4. Production & Gerçek Hayat Best Practices
* Kurumsal firmalarda `main` branch doğrudan `git push`'a **KESİNLİKLE KAPALIDIR** (Protected Branch).
* Kodlar yalnızca Pull Request / Merge Request ile, en az 1-2 kıdemli mühendisin onayı (Peer Review) ve CI testlerinin yeşil yanması şartıyla merge edilebilir.

#### 5. Sık Yapılan Hatalar ve Çözümler
* **Hata:** `Support for password authentication was removed. Please use a personal access token.`
  * **Eğitmen Müdahalesi:** Öğrencinin GitHub parolası girmeye çalıştığını belirtin. Settings > Developer Settings > Tokens (classic) adımlarını açtırıp `repo` yetkili bir PAT ürettirin.

---

### LAB-02 & LAB-04: AWS Altyapı, Terraform IaC ve 3-Tier Production

#### 1. Eğitmenin Giriş Konuşması (Sahne Kurulumu)
> *"Bir şirkette 'Sunucu çöktü, yeniden kuralım' dendiğinde konsola girip elle butonlara basıyorsanız geçmiş olsun. Cloud mühendisliğinin altın kuralı şudur: 'ClickOps biter, CodeOps başlar'. Bugün Terraform ile bir e-ticaret altyapısını kodla 3 dakikada sıfırdan kurup, 1 dakikada yok edeceğiz."*

#### 2. Mimari Kararlar ve Rationale
* **Neden Veritabanını Private Subnet'e Koyduk?**
  * Güvenliğin ilk kuralı: "Dışarıdan erişilmesine gerek olmayan hiçbir şeyi internete açma (Zero Trust)." RDS'in `PubliclyAccessible: false` olması, hacker'ların veritabanı portunu taramasını imkansız kılar.
* **Neden Web SG -> RDS SG Referansı?**
  * IP adresi vermek yerine Güvenlik Grubu ID'si (`source_security_group_id`) bağlayarak dinamik IP değişimlerinde kuralların bozulmamasını sağladık.

#### 3. Öğrencilere Sorulacak Sorular
* **Soru:** *"Terraform'da `terraform.tfstate` dosyası neden asla Git'e commit edilmemelidir?"*
  * **Beklenen Cevap:** 1. İçinde düz metin şifreler (DB passwords) ve hassas metadata bulunabilir. 2. Takım çalışmasında durum çakışır. Çözüm: AWS S3 + DynamoDB Lock kullanmaktır.
* **Soru:** *"Public Subnet ile Private Subnet arasındaki teknik farkı belirleyen bileşen nedir?"*
  * **Beklenen Cevap:** Route Table'daki `0.0.0.0/0` kuralının bir **Internet Gateway (IGW)**'e mi yoksa bir **NAT Gateway**'e mi baktığıdır.

#### 4. Production & Gerçek Hayat Best Practices
* Gerçek hayatta tek bir EC2 yerine **Auto Scaling Group (ASG)** ve önünde **Application Load Balancer (ALB)** kullanılır.
* Veritabanı Single-AZ değil, felaket anında saniyeler içinde ayağa kalkan **Multi-AZ RDS** veya **Aurora** olarak konumlandırılır.

#### 5. Sık Yapılan Hatalar ve Çözümler
* **Hata:** `Error: RDS Instance already exists` veya `VPC limit exceeded`.
  * **Eğitmen Müdahalesi:** Öğrencinin önceki labdan kalan kaynakları silmediğini gösterin. AWS Console'dan silip `terraform refresh` yaptırın.

---

### LAB-03: Docker ve Docker Compose ile Konteynerleştirme

#### 1. Eğitmenin Giriş Konuşması (Sahne Kurulumu)
> *"'Benim bilgisayarımda çalışıyordu, sunucuda neden çalışmıyor?' mazeretini tarihe gömen teknoloji Docker'dır. Ancak konteyneri çalıştırmak yetmez; 1 GB'lık Java imajını multi-stage build ile nasıl 200 MB'a düşüreceğimizi ve root haklarını bırakıp hacker'lara kapıyı nasıl kapatacağımızı öğreneceğiz."*

#### 2. Mimari Kararlar ve Rationale
* **Neden Multi-Stage Build?**
  * Maven ve JDK derleme araçları sadece jar üretmek içindir. Prodüksiyon ortamında derleyiciye ihtiyaç yoktur; yalnızca hafif JRE (Java Runtime) taşınır.
* **Neden `USER appuser:1000`?**
  * Bir saldırgan uygulamada açık (RCE) bulup konteyner kabuğuna düşerse, host makinede root haklarına sıçrayamasın (Container Escape önlemi).

#### 3. Öğrencilere Sorulacak Sorular
* **Soru:** *"Dockerfile içinde `COPY pom.xml .` adımını neden `COPY src ./src` adımından önce yaparız?"*
  * **Beklenen Cevap:** **Docker Layer Caching.** Kod her değiştiğinde yüzlerce bağımlılığı tekrar internetten indirmemek için `pom.xml` ve bağımlılık katmanı önbelleğe alınır.
* **Soru:** *"`CMD` ile `ENTRYPOINT` arasındaki fark nedir?"*
  * **Beklenen Cevap:** `ENTRYPOINT` konteynerin sabit yürütücüsüdür (`java -jar`). `CMD` ise ona varsayılan argümanları iletir ve `docker run` sırasında kolayca ezilebilir.

#### 4. Production & Gerçek Hayat Best Practices
* Prodüksiyon imajlarında asla `latest` etiketi kullanılmaz; semantik versiyon (`v1.2.3`) veya Git commit SHA (`sha-abc1234`) kullanılır.
* Docker daemon log boyutu sınırlanmalıdır (`max-size: 50m`, `max-file: 3`), aksi halde sunucu diski dolar.

---

### LAB-06: Kubernetes Core ve Helm ile Mikroservis Dağıtımı

#### 1. Eğitmenin Giriş Konuşması (Sahne Kurulumu)
> *"Docker tek bir konteyneri ayağa kaldırır. Peki gece saat 03:00'te o konteyner çökerse ne olur? Veya Black Friday günü sisteme 100 bin kişi girerse? İşte bu soruların cevabı Kubernetes'tir. Bugün bir konteyneri çökerteceğiz ve K8s'in onu gözümüzün önünde birkaç saniyede nasıl yeniden canlandırdığını (Self-Healing) izleyeceğiz."*

#### 2. Mimari Kararlar ve Rationale
* **Neden Kind (Kubernetes in Docker)?**
  * Minikube tek düğümlüdür. Kind ise Docker konteynerlerini birer sanal düğüm (Node) gibi kullanarak öğrenciye gerçek bir **Multi-Node (1 Control-Plane, 2 Worker)** küme deneyimi yaşatır.
* **Neden Helm?**
  * 10 farklı mikroservis için onlarca yaml yazmak yerine değişkenleri `values.yaml` dosyasından besleyip tek komutla (`helm upgrade --install`) ortam yönetimi sağlamak.

#### 3. Öğrencilere Sorulacak Sorular
* **Soru:** *"`livenessProbe` ile `readinessProbe` arasındaki fark nedir? Yanlış yapılandırılırsa ne olur?"*
  * **Beklenen Cevap:** `livenessProbe` çöken pod'u **yeniden başlatır** (Restart). `readinessProbe` ise hazır olmayan pod'a **trafik gitmesini engeller** (Service Endpoint'ten çıkarır). Eğer DB yavaş diye livenessProbe pod'u öldürürse sistem sonsuz restart döngüsüne (CrashLoopBackOff) girer!
* **Soru:** *"Bir Pod'un IP'si sürekli değişirken diğer servisler ona nasıl sabit erişir?"*
  * **Beklenen Cevap:** **Kubernetes Service** bileşeni ve küme içi **CoreDNS** sayesinde (`novashop-ui.novashop.svc.cluster.local`).

#### 4. Sık Yapılan Hatalar ve Çözümler
* **Hata:** `CrashLoopBackOff` veya `ImagePullBackOff`.
  * **Eğitmen Müdahalesi:** `kubectl describe pod <pod-name>` komutunu çalıştırın ve en alttaki **Events** bloğunu okutun. Hatanın imaj adından mı yoksa ortam değişkeninden mi kaynaklandığını adım adım analiz ettirin.

---

### LAB-07 & LAB-08: Kurumsal CI/CD ve DevSecOps (Harbor, SonarQube, Trivy)

#### 1. Eğitmenin Giriş Konuşması (Sahne Kurulumu)
> *"Geleneksel yazılım geliştirmede güvenlik en son akla gelirdi ve güvenlik ekibi yayına 1 gün kala projeyi durdururdu. DevSecOps'un sloganı **Shift-Left**'tir: Güvenliği geliştiricinin ilk commit'ine kadar sola çekmek. Bugün pipeline'ımıza öyle kapılar (Quality Gates) koyacağız ki, kodunda şifre unutan veya kritik CVE barındıran hiçbir geliştirici canlıya çıkamayacak."*

#### 2. Mimari Kararlar ve Rationale
* **Neden Harbor Immutable Tags?**
  * Bir saldırgan veya dikkatsiz geliştirici `v1.0.0` etiketli güvenli bir imajın üzerine aynı etiketle zararlı bir kod basamasın (Image Tampering).
* **Neden Robot Account?**
  * CI/CD boru hattına insan parolası verilmez. Sadece ilgili projeye `push/pull` yetkisi olan, süresi kısıtlanabilir robot token'lar kullanılır.

#### 3. Öğrencilere Sorulacak Sorular
* **Soru:** *"SAST (Static Application Security Testing) ile DAST (Dynamic) arasındaki fark nedir?"*
  * **Beklenen Cevap:** SAST kaynak koda bakarak derleme öncesi açık arar (SonarQube). DAST ise çalışan uygulamaya dışarıdan saldırı simülasyonu yapar (OWASP ZAP).
* **Soru:** *"SBOM (Software Bill of Materials) neden modern siber güvenliğin en kritik şartıdır?"*
  * **Beklenen Cevap:** Log4j krizinde olduğu gibi, sistemlerimizde hangi kütüphanenin hangi versiyonunun çalıştığını saniyeler içinde listeleyip zafiyet analizi yapabilmek için dijital malzeme listesidir.

---

### LAB-09: GitOps ve Argo CD ile Sürekli Dağıtım

#### 1. Eğitmenin Giriş Konuşması (Sahne Kurulumu)
> *"Artık hiç kimse canlı Kubernetes kümesine bağlanıp `kubectl edit` veya `kubectl apply` yapmamalıdır. Canlı küme ile Git reposu arasında bir fark (Drift) oluşursa ne olur? Bugün canlı kümeye girip pod sayısını manuel değiştireceğiz ve Argo CD'nin 'Sen benden habersiz iş yapamazsın' diyerek sistemi saniyeler içinde Git'teki haline nasıl zorla eşitlediğini (Self-Healing) göreceğiz."*

#### 2. Mimari Kararlar ve Rationale
* **Push-based CI/CD vs. Pull-based GitOps:**
  * Jenkins/GitLab'ın K8s cluster'ın admin yetkisine (Kubeconfig) sahip olması güvenlik riskidir (CI sunucusu hacklenirse cluster gider).
  * Argo CD ise kümenin **içinde** yaşar, dışarıya yetki vermez, sadece Git'i dinler (Pull Modeli).

#### 3. Öğrencilere Sorulacak Sorular
* **Soru:** *"Bir geliştirici production pod sayısını 2'den 10'a çıkarmak isterse GitOps dünyasında ne yapar?"*
  * **Beklenen Cevap:** Cluster'a dokunmaz. Git reposundaki `values.yaml` dosyasında `replicaCount: 10` yapar, PR açar. PR merge edildiğinde Argo CD kümede podları otomatik 10'a çıkarır.
* **Soru:** *"Canlı ortamda acil bir hata çıktı, Rollback nasıl yapılır?"*
  * **Beklenen Cevap:** `git revert <commit-id>` yapılarak repo bir önceki commit'e döndürülür. Argo CD otomatik olarak eski kararlı versiyona döner.

---

### LAB-10: Gözlemlenebilirlik (Prometheus, Grafana, SLO ve Tracing)

#### 1. Eğitmenin Giriş Konuşması (Sahne Kurulumu)
> *"Bir müşteriniz sizi arayıp 'Siteniz çok yavaş' dediğinde 'Bende hızlı çalışıyor' diyemezsiniz. Sayılarla konuşmak zorundasınız. Bugün RED metotlarıyla sistemin nabzını tutacağız, SRE prensipleriyle %99.9 SLO hedefi koyacağız ve yapay hata yüküyle alarmlarımızı çaldıracağız."*

#### 2. Mimari Kararlar ve Rationale
* **Prometheus Pull Modeli:**
  * Servislerin tek tek Prometheus'a bağlanıp trafik yaratması yerine, Prometheus merkezi olarak servislerin `/actuator/prometheus` kapısını çalar (Scrape). Servis çökerse Prometheus onun öldüğünü anında anlar (`up == 0`).
* **Bonus Tracing (Jaeger):**
  * Neden log yetmez? 10 mikroservisli bir mimaride istek 3 saniye sürdüyse, hangi mikroservisin beklettiğini loglardan bulmak saatler sürer. Jaeger Waterfall diyagramı darboğazı 1 saniyede gösterir.

#### 3. Öğrencilere Sorulacak Sorular
* **Soru:** *"SLI, SLO ve SLA arasındaki farkı tek bir cümleyle nasıl özetlersiniz?"*
  * **Beklenen Cevap:** **SLI** neyi ölçtüğümüzdür (%99.94), **SLO** mühendislik ekibinin hedefidir (%99.90), **SLA** ise müşteriye verilen hukuki taahhüt ve cezai sınırdır (%99.50).
* **Soru:** *"Hata Bütçesi (Error Budget) bittiğinde ne yapılır?"*
  * **Beklenen Cevap:** Tüm yeni özellik (feature) dağıtımları durdurulur; ekip yalnızca sistem kararlılığı, refactoring ve bugfix çalışır.

---

### LAB-11: Merkezi Loglama (ELK Stack: Elasticsearch, Kibana, Fluent Bit)

#### 1. Eğitmenin Giriş Konuşması (Sahne Kurulumu)
> *"50 tane podumuz ve 10 tane sunucumuz olduğunda, hata ayıklamak için her sunucuya tek tek SSH yapıp `tail -f /var/log/syslog` yapamazsınız. Tüm loglar tek bir havuza akmalıdır. Bugün Ubuntu'daki tüm Docker konteynerlerini, Kubernetes podlarını ve sistem günlüklerini Elasticsearch'e akıtıp, Kibana'da tek bir KQL aramasıyla mikroservis hatasını yakalayacağız."*

#### 2. Mimari Kararlar ve Rationale
* **Neden Fluent Bit?**
  * Logstash Java tabanlıdır ve 1-2 GB RAM ister. Fluent Bit ise C ile yazılmıştır, yalnızca 20 MB RAM tüketir; konteyner loglarını zenginleştirip doğrudan Elasticsearch'e basar.
* **Neden `trace_id` Korelasyonu?**
  * Kullanıcı arayüzünde oluşan bir hatanın logunu arattığımızda, arka plandaki Checkout ve DB loglarını tek bir ekranda kronolojik sırayla görebilmek için.

#### 3. Öğrencilere Sorulacak Sorular
* **Soru:** *"Elasticsearch'te `keyword` ile `text` veri tipleri arasındaki fark nedir?"*
  * **Beklenen Cevap:** `keyword` filtreleme ve tam eşleşme için kullanılır (`level: "ERROR"`). `text` ise cümle içindeki serbest metin araması için parçalanır (Inverted index).
* **Soru:** *"Kibana'da Discover ekranı boş görünüyorsa ilk kontrol edilecek şey nedir?"*
  * **Beklenen Cevap:** 1. Sağ üstteki **Time Filter** (Varsayılan 15 dakika olabilir, genişletilmeli). 2. İlgili indeksi kapsayan bir **Data View (Index Pattern)** tanımlanmış mı?

---

## 💼 Genel DevOps Mülakat Soruları ve Öğrenciye Kazandırılacak Cevap Kalıpları

Eğitmen, ders aralarında öğrencileri mülakatlara hazırlamak için şu soruları tartışmaya açmalıdır:

1. **"Prodüksiyon ortamında Kubernetes Pod'unuz CrashLoopBackOff veriyor. Adım adım nasıl debug edersiniz?"**
   * *Junior Cevap:* "Pod'u silip tekrar başlatırım."
   * *Senior / İstenen Cevap:*
     1. `kubectl describe pod <pod_name>` ile Events sekmesinde OOMKilled mi, LivenessProbe hatası mı bakarım.
     2. `kubectl logs <pod_name> --previous` ile çökmeden hemen önceki uygulama stacktrace'ini incelerim.
     3. ConfigMap / Secret ortam değişkenlerinin eksiksiz bağlandığını doğrularım.

2. **"Bir CI/CD pipeline'ı tasarlarken güvenliği nasıl sağlarsınız?"**
   * *İstenen Cevap:*
     * Kod seviyesinde secret taraması (Gitleaks),
     * Statik kod analizi (SonarQube Quality Gate),
     * Bağımlılık ve imaj taraması (Trivy),
     * Registry tarafında değiştirilemez etiketler (Immutable tags) ve imaj imzalama (Cosign),
     * Prodüksiyona çıkışta GitOps (Argo CD) prensipleri.

3. **"Prometheus varken neden ELK Stack kullanıyoruz?"**
   * *İstenen Cevap:*
     * Prometheus **sayısal metrikleri** (CPU, RAM, RPS, Gecikme) toplar; sistemde bir anormallik olduğunu söyler (*"Yangın var!"*).
     * ELK Stack ise **olayın metin kaydını (Log)** tutar; yangının neden ve nerede çıktığını söyler (*"Hangi kullanıcı, hangi parametreyle, hangi satırda NullPointerException aldı"*). Biri diğerinin alternatifi değil, tamamlayıcısıdır.
