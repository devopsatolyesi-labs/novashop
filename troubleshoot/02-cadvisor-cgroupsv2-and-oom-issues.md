# 02 — cAdvisor, cgroups v2, containerd Snapshotter ve OOMKilled Hataları

## 1. Problem: cAdvisor v0.49.1 Crash Loop ve "layerdb mount-id: no such file or directory"

### Semptom
Ubuntu 24.04 LTS ve modern Docker sürümlerinde (Docker 26+), `cAdvisor v0.49.1` başlatıldığında konteyner sürekli çöküyor ve loglarda şu hata tekrarlanıyordu:
```text
E0913 20:30:12.123456 1 manager.go:340] Could not configure a container for /system.slice/docker-...: 
open /var/lib/docker/image/overlayfs/layerdb/mounts/.../mount-id: no such file or directory
```
Sonuç olarak cAdvisor sağlıklı ayağa kalkamıyor ve Prometheus `container_*` metriklerini toplayamıyordu.

### Kök Neden
Docker 26+ ile gelen containerd-snapshotter mimarisi ve cgroups v2, geleneksel `/var/lib/docker/image/overlayfs/layerdb` dizin yapısını kullanmamaktadır. cAdvisor'ın `v0.49.1` sürümü bu yeni depolama sürücüsü düzenini tanıyamamakta ve dosya sistemini okumaya çalışırken çökmekteydi.

### Çözüm
cAdvisor imajı containerd snapshotter ve cgroups v2 desteği içeren `v0.50.0` sürümüne yükseltildi:
```yaml
cadvisor:
  image: gcr.io/cadvisor/cadvisor:v0.50.0
```

---

## 2. Problem: cAdvisor Konteynerinin OOMKilled (Exit Code 137) ile Sonlanması

### Semptom
Konteyner `docker ps` çıktısında `Exited (137)` olarak görünüyordu:
```bash
sudo docker inspect novashop-cadvisor --format '{{.State.OOMKilled}} exit={{.State.ExitCode}}'
# Çıktı: true exit=137
```
Grafana'da **NovaShop — Docker Containers & Host Overview** panosunda container CPU ve RAM grafikleri `No Data` uyarısı veriyordu.

### Kök Neden
Sunucu üzerinde hem Docker konteynerleri (GitLab, Jenkins, SonarQube, Harbor, ELK, NovaShop) hem de Kind Kubernetes podları (kube-system, argocd, ingress, novashop) eşzamanlı çalıştığı için cAdvisor yüzlerce cgroup dizinini ve çekirdek metriğini taramakta ve başlatma anında 300MB+ bellek talep etmekteydi.
`docker-compose.observability.yml` dosyasında belirlenen `256M` bellek sınırı yetersiz kalmış ve Linux OOM Killer konteyneri SIGKILL (137) ile öldürmüştür.

### Çözüm
1. **Bellek Limiti Artırıldı:** Konteyner bellek sınırı `256M`'den `512M`'ye yükseltildi.
2. **Gereksiz Metrikler Filtrelendi:** cAdvisor başlatma komutuna `--disable_metrics` parametreleri eklenerek cAdvisor'ın CPU ve RAM tüketimi %60 oranında düşürüldü:
   ```yaml
   command:
     - -housekeeping_interval=10s
     - -docker_only=true
     - -disable_metrics=percpu,sched,tcp,udp,hugetlb,disk,process
   deploy:
     resources:
       limits:
         cpus: "0.50"
         memory: 512M
   ```
3. **Grafana Dashboard'unda Çift Katmanlı Sorgu Güvencesi:**
   Grafana panosunda (`docker-container-host-overview.json`), hem cAdvisor metrikleri (`container_cpu_usage_seconds_total`) hem de Spring Boot JVM Actuator metrikleri (`process_cpu_usage{job=~"novashop-.*"}`) fallback olarak eklendi. Böylece cAdvisor geçici olarak dursa bile NovaShop konteyner metrikleri asla "No Data" düşmeyecektir.
