# 01 — Port Çakışmaları ve Servis İzolasyonu

## 1. Problem: Cockpit Web Arayüzü ile Prometheus Port 9090 Çakışması

### Semptom
Sistemde Cockpit Web Terminal servisi (`systemd cockpit.socket`) aktifken, LAB-10 Observability stack'i ayağa kaldırıldığında Prometheus konteyneri başlatılamıyor veya `Bind for 0.0.0.0:9090 failed: port is already allocated` hatası veriyordu:
```text
Error response from daemon: driver failed programming external connectivity on endpoint novashop-prometheus: 
Error starting userland proxy: listen tcp4 0.0.0.0:9090: bind: address already in use
```

### Kök Neden
Ubuntu sunucu üzerinde `cockpit.service` ve `cockpit.socket` varsayılan olarak `9090` portunda TLS ile dinleme yapar. Prometheus'un da endüstri standardı varsayılan portu `9090`'dır. Aynı host üzerinde her ikisi de `0.0.0.0:9090` dinlemeye çalıştığında işletim sistemi seviyesinde soket çakışması yaşanmıştır.

### Çözüm
1. Prometheus'un host üzerindeki dinleme portu `9091` olarak değiştirildi:
   `deploy/observability/docker-compose.observability.yml`:
   ```yaml
   services:
     prometheus:
       image: prom/prometheus:v2.51.0
       ports:
         - "9091:9090"
   ```
2. Nginx edge proxy üzerinde Prometheus upstream hedefi `http://127.0.0.1:9091` olarak güncellendi.
3. Cockpit ise `https://127.0.0.1:9090` adresinde güvenle çalışmaya devam etti.

---

## 2. Problem: Docker Compose (LAB-03) ile Kubernetes NodePort (LAB-06/09) İzolasyonu

### Semptom
Öğrenciler hem Docker Compose tabanlı mikroservisleri (`novashop-ui`, `novashop-catalog`) hem de Kind Kubernetes üzerindeki podları aynı sunucuda çalıştırdığında, her iki platform da aynı servis isimlerini veya portları bağlamaya çalıştığında karışıklık oluşuyordu.

### Kök Neden
- Docker Compose mimarisinde UI servisi host üzerinde `:8888` portuna bağlanmıştı.
- Kubernetes Kind kümesinde NodePort servisi host üzerinde `:30080` portuna eşlenmişti.
- Hostname veya reverse proxy yönlendirmesi net ayrılmadığında kullanıcılar Compose mu yoksa K8s mi kullandıklarını ayırt edemiyordu.

### Çözüm
1. İki çalışma ortamı Nginx üzerinde alan adları ile tamamen ayrıştırıldı:
   - `student100-novashop.devopsatolyesi.com` -> Docker Compose UI (`http://127.0.0.1:8888`)
   - `student100-kind.devopsatolyesi.com` -> Kind Kubernetes NodePort (`http://127.0.0.1:30080`)
2. Port çakışmasını engellemek için tüm araç servislerine sabit yüksek port blokları atandı:
   - GitLab CE: `:8929`
   - Harbor Core: `:18082`
   - Jenkins Controller: `:18080`
   - SonarQube: `:19000`
   - Kibana: `:5601`
   - Elasticsearch: `:9200`
   - Prometheus: `:9091`
   - Grafana: `:3000`
   - Jaeger: `:16686`
   - cAdvisor: `:8081`
