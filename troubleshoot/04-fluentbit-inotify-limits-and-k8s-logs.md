# 04 — Fluent Bit, Inotify Limitleri ve Kubernetes Pod Logları

## 1. Problem: Fluent Bit "inotify cannot add watch: No space left on device"

### Semptom
Fluent Bit `tail` eklentisi ile Kubernetes veya Docker loglarını (`/var/log/pods/*/*/*.log` veya `/var/lib/docker/containers/*/*.log`) izlemeye çalışırken loglarda şu hata oluşur:
```text
[error] [input:tail:tail.0] inotify cannot add watch for file /var/log/pods/...: No space left on device
```
Diskte onlarca gigabayt boş yer olmasına rağmen Fluent Bit yeni log dosyalarını izleyemez ve log akışı durur.

### Kök Neden
Linux çekirdeğindeki `fs.inotify.max_user_watches` parametresi, bir kullanıcının veya sürecin dosya sistemi olaylarını (oluşturma, yazma, silme) dinlemek için kaydedebileceği maksimum dosya/dizin sayısını sınırlar.
Sunucuda onlarca Docker konteyneri ve Kubernetes pod'u çalıştığında binlerce log dosyası ve cgroup izlendiği için varsayılan sınır (genellikle 8192 veya 65536) tükenmektedir. "No space left on device" hatası fiziksel disk alanının değil, çekirdeğin inotify tablo belleğinin dolduğunu belirtir.

### Çözüm
1. **Canlı Sistemde Sınırı Artırma:**
   ```bash
   sudo sysctl -w fs.inotify.max_user_watches=524288
   sudo sysctl -w fs.inotify.max_user_instances=512
   ```
2. **Kalıcı Hale Getirme:**
   `/etc/sysctl.d/99-devops-inotify.conf` dosyası oluşturularak reboot sonrasında da geçerli olması sağlandı:
   ```ini
   fs.inotify.max_user_watches = 524288
   fs.inotify.max_user_instances = 512
   ```
   Uygulamak için: `sudo sysctl --system`.

---

## 2. Problem: Kind Kubernetes Kümesinde Pod Loglarına Host Seviyesinden Erişilememesi

### Semptom
Docker üzerinde çalışan Fluent Bit veya Logstash konteyneri, Kind kümesindeki podların loglarına ulaşamıyordu (`/var/log/pods: No such file or directory`).

### Kök Neden
Kind, Kubernetes düğümlerini Docker konteynerleri içinde çalıştırır (Docker-in-Docker / Containerd-in-Docker). Dolayısıyla Kind düğümünün `/var/log/pods` dizini doğrudan host sunucunun dosya sisteminde değil, Kind konteynerinin kendi katmanında kalır.

### Çözüm
Kind kümesi oluşturulurken `kind-config.yaml` içine host mount tanımları eklendi:
```yaml
nodes:
  - role: control-plane
    extraMounts:
      - hostPath: /var/log/pods
        containerPath: /var/log/pods
      - hostPath: /var/lib/docker/containers
        containerPath: /var/lib/docker/containers
```
Böylece pod logları doğrudan host sunucuya yazılır ve dışarıdaki Fluent Bit veya Filebeat ajanı tarafından sıfır gecikmeyle toplanır.
