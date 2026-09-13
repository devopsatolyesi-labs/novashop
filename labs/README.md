# NovaShop DevOps, Cloud & DevSecOps Labs

NovaShop e-ticaret platformu üzerinde adım adım uygulanan, kurumsal standartlara uygun uygulamalı laboratuvarlar serisi.

Tüm laboratuvarlar **Ubuntu sunucusu** üzerinde koşar ve iki erişim modelini (`Doğrudan IP:Port` ve `Kurumsal DNS+SSL`) destekler.

---

## 🛠️ Platform Hazırlık Laboratuvarı

| Laboratuvar | Başlık | Kapsam / Kurulan Araçlar | Rehber Bağlantısı |
| :--- | :--- | :--- | :--- |
| **LAB-00** | [Platform Setup & Infra](LAB-00-PLATFORM-SETUP/README.md) | GitLab CE, Harbor Registry, SonarQube, Jenkins, Nginx Proxy | [LAB-00 Rehberi](LAB-00-PLATFORM-SETUP/README.md) |

---

## ⭐ Çekirdek ve Zorunlu Laboratuvarlar (Core Track)

DevOps mühendisliği eğitiminin temel omurgasını oluşturan, mutlaka tamamlanması gereken çekirdek laboratuvarlar:

| Laboratuvar | Başlık | Kapsam / Ana Konular | Rehber Bağlantısı |
| :--- | :--- | :--- | :--- |
| **\* [LAB-01](LAB-01/README.md)** | Git & GitHub Temelleri | Branch yönetimi, PR, izole merge conflict çözümü (`lab-01/products.json`), PAT yapılandırması | [LAB-01 Rehberi](LAB-01/README.md) |
| **\* [LAB-03](LAB-03/README.md)** | Docker & Docker Compose | Multi-stage build (Java 21), non-root appuser güvenliği, Compose overlay (`starter.secure.yml`) | [LAB-03 Rehberi](LAB-03/README.md) |
| **\* [LAB-06](LAB-06/README.md)** | Kubernetes Core & Helm | Kind K8s kümesi, Pods, Services, Traefik Ingress, Helm Chart mikroservis dağıtımı | [LAB-06 Rehberi](LAB-06/README.md) |
| **\* [LAB-07](LAB-07/README.md)** | Kurumsal CI/CD Hattı | GitLab CI, Jenkins, Docker-in-Docker derleme, Harbor Private Registry & Immutable Tags | [LAB-07 Rehberi](LAB-07/README.md) |
| **\* [LAB-08](LAB-08/README.md)** | DevSecOps Güvenlik Kapıları | SonarQube SAST, Trivy imaj ve dosya taraması, Secret scanning, CycloneDX SBOM üretimi | [LAB-08 Rehberi](LAB-08/README.md) |
| **\* [LAB-10](LAB-10/README.md)** | Observability & İzleme | Prometheus metrikleri, Grafana panoları, OpenTelemetry / Jaeger trace, SLO yönetimi | [LAB-10 Rehberi](LAB-10/README.md) |

---

## 🚀 İleri Seviye & Bulut Laboratuvarları (Bonus Track)

Kurumsal bulut mimarileri (AWS), GitOps ve merkezi loglama konularında uzmanlaşmak isteyenler için modüler ileri seviye laboratuvarlar:

| Laboratuvar | Başlık | Kapsam / Ana Konular | Rehber Bağlantısı |
| :--- | :--- | :--- | :--- |
| **[LAB-02](LAB-02/README.md)** | AWS Temel Altyapı | VPC, EC2 Web, Multi-AZ RDS MySQL, Güvenlik Grupları, Terraform IaC | [LAB-02 Rehberi](LAB-02/README.md) |
| **[LAB-04](LAB-04/README.md)** | AWS 3-Tier Production | Production compose, Nginx reverse proxy, TLS, CloudWatch loglama | [LAB-04 Rehberi](LAB-04/README.md) |
| **[LAB-05](LAB-05/README.md)** | GitHub Actions CI/CD | AWS OIDC, ECR imaj dağıtımı, automated release, rollback mekanizması | [LAB-05 Rehberi](LAB-05/README.md) |
| **[LAB-09](LAB-09/README.md)** | GitOps & Argo CD | Declarative GitOps, continuous reconciliation, self-healing, automated sync | [LAB-09 Rehberi](LAB-09/README.md) |
| **[LAB-11](LAB-11/README.md)** | Merkezi Loglama (EFK) | Fluent Bit, Elasticsearch, Kibana log analitiği ve trace correlation | [LAB-11 Rehberi](LAB-11/README.md) |
| **[LAB-12](LAB-12/README.md)** | Terraform IaC Enterprise | Modüler Terraform, remote S3 state, dynamoDB locking, cloud-init otomasyonu | [LAB-12 Rehberi](LAB-12/README.md) |
| **[LAB-13](LAB-13/README.md)** | Amazon EKS Enterprise | Kurumsal AWS EKS kümesi, IRSA, AWS Load Balancer Controller, ADOT | [LAB-13 Rehberi](LAB-13/README.md) |
| **[LAB-14](LAB-14/README.md)** | AWS ECS & Fargate | Serverless container mimarisi, ALB, ECS Task Definition, GitHub Actions | [LAB-14 Rehberi](LAB-14/README.md) |

---

> [!NOTE]
> Laboratuvar dizinlerindeki tüm yönergeler, sunucunuzdaki port ve IP durumuna göre test edilmiş ve doğrulanmıştır.
