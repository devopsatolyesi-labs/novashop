# NovaShop DevOps & Cloud Labs

NovaShop e-ticaret platformu üzerinde adım adım uygulanan 14 kapsamlı DevOps laboratuvarı:

| Laboratuvar | Başlık | Kapsam / Ana Konular | Rehber Bağlantısı |
| :--- | :--- | :--- | :--- |
| **[LAB-01](LAB-01/README.md)** | Git & GitHub Foundations | Branch yönetimi, PR, Merge conflict çözümü, Trunk-Based Dev | [LAB-01 Rehberi](LAB-01/README.md) |
| **[LAB-02](LAB-02/README.md)** | AWS Temel Altyapı (Console & Terraform) | VPC, EC2 Web, Multi-AZ RDS MySQL, Güvenlik Grupları, Terraform IaC | [LAB-02 Rehberi](LAB-02/README.md) |
| **[LAB-03](LAB-03/README.md)** | Docker & Docker Compose | Multi-stage build, container hardening, compose overlays | [LAB-03 Rehberi](LAB-03/README.md) |
| **[LAB-04](LAB-04/README.md)** | AWS 3-Tier Production Architecture | Production compose, Nginx reverse proxy, TLS, CloudWatch | [LAB-04 Rehberi](LAB-04/README.md) |
| **[LAB-05](LAB-05/README.md)** | GitHub Actions CI/CD Pipeline | AWS OIDC, ECR imaj dağıtımı, automated release, rollback | [LAB-05 Rehberi](LAB-05/README.md) |
| **[LAB-06](LAB-06/README.md)** | Kubernetes Core & Helm Deployment | Kind k8s cluster, Pods, Services, Ingress, Helm chart | [LAB-06 Rehberi](LAB-06/README.md) |
| **[LAB-07](LAB-07/README.md)** | Enterprise CI/CD: Jenkins, GitLab, Harbor | On-prem enterprise pipeline, Harbor private registry | [LAB-07 Rehberi](LAB-07/README.md) |
| **[LAB-08](LAB-08/README.md)** | DevSecOps Security Gates | SonarQube, Trivy scan, Gitleaks, SBOM üretimi | [LAB-08 Rehberi](LAB-08/README.md) |
| **[LAB-09](LAB-09/README.md)** | GitOps ile Argo CD Dağıtımı | Declarative GitOps, continuous reconciliation, self-healing | [LAB-09 Rehberi](LAB-09/README.md) |
| **[LAB-10](LAB-10/README.md)** | Observability: Prometheus & Grafana | OpenTelemetry, Prometheus metrics, Grafana dashboards, SLO | [LAB-10 Rehberi](LAB-10/README.md) |
| **[LAB-11](LAB-11/README.md)** | Centralized Logging: EFK Stack | Fluent Bit, Elasticsearch, Kibana log analitiği | [LAB-11 Rehberi](LAB-11/README.md) |
| **[LAB-12](LAB-12/README.md)** | Terraform IaC Enterprise | Modüler Terraform, remote state, cloud-init otomasyonu | [LAB-12 Rehberi](LAB-12/README.md) |
| **[LAB-13](LAB-13/README.md)** | Amazon EKS Enterprise Deployment | AWS EKS, IRSA, AWS Load Balancer Controller, EKS monitoring | [LAB-13 Rehberi](LAB-13/README.md) |
| **[LAB-14](LAB-14/README.md)** | AWS ECS & Fargate Serverless Containers | Serverless container mimarisi, ALB, Task Definition, CI/CD | [LAB-14 Rehberi](LAB-14/README.md) |

---

> [!TIP]
> Her laboratuvar dizini (`labs/LAB-XX/`) kendi kılavuzunu (`README.md`) ve ihtiyaç duyulan modül / script dosyalarını (örneğin [`labs/LAB-02/terraform-basic-infra/`](LAB-02/terraform-basic-infra/)) kendi içinde barındırır.
