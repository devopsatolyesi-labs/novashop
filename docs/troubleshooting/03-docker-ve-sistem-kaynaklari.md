# 03 — Docker Kaynak Yönetimi, RAM Bütçesi ve Servis Dayanıklılığı

Bu doküman; GitLab CE, SonarQube, Jenkins, Harbor ve Kind Kubernetes kümesinin tek bir 16GB RAM'li sanal makinede çökmeden bir arada işletilmesini açıklar.

---

## 1. Karşılaşılan Sorunlar ve Hata Belirtileri

### Senaryo A: OOMKilled (Exit Code 137)
- **Hata Çıktısı:**
  ```text
  docker ps -a
  STATUS: Exited (137) 2 minutes ago
  ```
- **Kök Neden:** GitLab (~3.8 GB), SonarQube (~2.4 GB), Jenkins (~800 MB) ve Kind Cluster (~2 GB) aynı anda yüksek yük aldığında Linux OOM Killer mekanizması en çok RAM tüketen süreci aniden sonlandırır.

### Senaryo B: Port Çakışmaları (`Address already in use`)
- **Hata Çıktısı:** `driver failed programming external connectivity on endpoint ...: bind: address already in use`
- **Kök Neden:** Jenkins'in varsayılan 8080 portu ile Argo CD veya NovaShop UI portunun aynı host portuna bağlanmaya çalışılması.

---

## 2. Adım Adım Kodla Çözüm

### 1. Port Haritasının Standartlaştırılması
Tüm servisler benzersiz host portlarına bağlanmıştır:
- **GitLab CE:** Web: `8929`, SSH: `2224`
- **Harbor Registry:** Nginx: `18082`
- **Jenkins Controller:** Web: `18080`, Agent: `50000`
- **SonarQube Server:** Web: `19000`
- **Argo CD Server:** Web: `8080` (Port-forward)
- **NovaShop UI (Docker):** Web: `8888`
- **NovaShop UI (Kind K8s):** NodePort: `30080`

### 2. Java JVM Heap Bellek Optimizasyonu
Java tabanlı süreçlerde JVM'in host RAM'inin tamamını istemesini engellemek için `MaxRAMPercentage` atanır:
```yaml
environment:
  - JAVA_TOOL_OPTIONS=-XX:MaxRAMPercentage=75.0 -XX:+UseG1GC
```

### 3. Kalıcı Systemd Arka Plan Servisleri
Geçici SSH oturumuna bağlı port-forward komutları yerine sistem seviyesinde servis tanımlanır:
`/etc/systemd/system/argocd-portforward.service`
```ini
[Unit]
Description=Argo CD Port Forward Service
After=network.target

[Service]
Type=simple
User=root
ExecStart=/usr/local/bin/kubectl port-forward --address 0.0.0.0 svc/argocd-server -n argocd 8080:443
Restart=always
RestartSec=5

[Install]
WantedBy=multi-user.target
```
Servisi etkinleştirme:
```bash
sudo systemctl daemon-reload
sudo systemctl enable --now argocd-portforward.service
```

---

## 3. Doğrulama Komutları

```bash
# Bellek durumunu anlık kontrol et:
free -h
sudo docker stats --no-stream --format "table {{.Name}}	{{.CPUPerc}}	{{.MemUsage}}	{{.MemPerc}}"
```
