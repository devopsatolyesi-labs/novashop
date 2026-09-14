# NovaShop DevOps Platform — Eğitmen ve Operasyon Troubleshooting Rehberi

Bu dizin, NovaShop DevOps platformunun geliştirilmesi, test edilmesi, öğrencilere sunulması ve laboratuvarların (LAB-01 ile LAB-12 arası) yürütülmesi sırasında karşılaşılan tüm teknik sorunları, hata çıktılarını, kök neden analizlerini (Root Cause Analysis) ve uygulanan kesin çözümleri konu konu detaylandırmaktadır.

---

## 📚 Konu Fihristi

| No | Konu Başlığı | İlgili Lab / Alan | Dosya Bağlantısı |
|:---|:---|:---|:---|
| **01** | **Port Çakışmaları ve Servis İzolasyonu** | Genel, LAB-03, LAB-06, LAB-10 | [01-port-conflicts-and-service-isolation.md](./01-port-conflicts-and-service-isolation.md) |
| **02** | **cAdvisor, containerd Snapshotter ve OOMKilled Hataları** | LAB-10 (Observability) | [02-cadvisor-cgroupsv2-and-oom-issues.md](./02-cadvisor-cgroupsv2-and-oom-issues.md) |
| **03** | **Elasticsearch Disk Watermark ve Cluster Health Sorunları** | LAB-11 (Log Analitiği / ELK) | [03-elasticsearch-disk-watermark-and-cluster-health.md](./03-elasticsearch-disk-watermark-and-cluster-health.md) |
| **04** | **Fluent Bit, Inotify Limitleri ve Kubernetes Pod Logları** | LAB-11 (Log Dağıtımı) | [04-fluentbit-inotify-limits-and-k8s-logs.md](./04-fluentbit-inotify-limits-and-k8s-logs.md) |
| **05** | **Argo CD GitOps NodePort Çakışması ve Sync Degradation** | LAB-09 (GitOps) | [05-argocd-gitops-nodeport-and-sync-degradation.md](./05-argocd-gitops-nodeport-and-sync-degradation.md) |
| **06** | **Nginx Edge Reverse Proxy, Çapraz Yönlendirme ve WebSocket İzolasyonu** | Altyapı / Nginx Edge Proxy | [06-nginx-reverse-proxy-cross-routing-and-websockets.md](./06-nginx-reverse-proxy-cross-routing-and-websockets.md) |
| **07** | **Cloudflare DNS Yönetimi ve Subdomain Fallback Stratejisi** | Altyapı / DNS & SSL | [07-cloudflare-dns-troubleshooting-and-subdomain-fallbacks.md](./07-cloudflare-dns-troubleshooting-and-subdomain-fallbacks.md) |
| **08** | **CI/CD Entegrasyonu: Harbor Health, Jenkins SonarQube ve Docker Soketi** | LAB-07, LAB-08 (CI/CD) | [08-cicd-pipeline-harbor-jenkins-sonarqube-integration.md](./08-cicd-pipeline-harbor-jenkins-sonarqube-integration.md) |

---

## 🛠 Hızlı Müdahale Araç Seti (Diagnostic Cheat-Sheet)

Tek bir komutla sunucudaki tüm sistem bileşenlerinin sağlık durumunu denetlemek için:

```bash
# 1. Konteyner Durumları
sudo docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"

# 2. Kind Kubernetes Düğümleri ve Podları
kubectl get nodes -o wide
kubectl get pods -A

# 3. Nginx Yapılandırma ve Servis Durumu
sudo nginx -t && sudo systemctl status nginx --no-pager

# 4. Bellek ve Disk Durumu
free -h
df -h /
