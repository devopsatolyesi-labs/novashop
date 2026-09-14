# 03 — Elasticsearch Disk Watermark ve Cluster Health Sorunları

## 1. Problem: Elasticsearch İndekslerinin Kilitlenmesi (`read_only_allow_delete: true`)

### Semptom
Fluent Bit veya Logstash log gönderirken Elasticsearch `429 Too Many Requests` veya `403 Forbidden` döndürüyor:
```text
[warn] [output:elasticsearch:elasticsearch.0] error: 403 - {"type":"cluster_block_exception",
"reason":"index [novashop-logs-2026.09.14] blocked by: [TOO_MANY_REQUESTS/12/disk usage exceeded flood-stage watermark, index has read-only-allow-delete blocks];"}
```
Kibana üzerinde hiçbir yeni log görüntülenemiyor.

### Kök Neden
Elasticsearch, veri bozulmasını önlemek amacıyla disk doluluğunu izler:
- **Low Watermark (%85):** Yeni shard tahsisini durdurur.
- **High Watermark (%90):** Shard'ları başka düğümlere taşımaya çalışır.
- **Flood Stage Watermark (%95):** Tüm indeksleri otomatik olarak salt-okunur (`read_only_allow_delete: true`) moda geçirir ve yazma işlemlerini tamamen engeller.
Çok sayıda Docker imajı ve log biriktiğinde sunucu disk kullanımı %90'ı aştığı için küme kendini kilitlemiştir.

### Çözüm
1. **Disk Temizliği:**
   Gereksiz Docker imajları ve build cache temizlendi:
   ```bash
   sudo docker system prune -af --volumes
   ```
2. **Elasticsearch Watermark Limitlerinin Yeniden Yapılandırılması:**
   Lab ve eğitim ortamlarına uygun esnek eşikler belirlendi:
   ```bash
   curl -X PUT "http://127.0.0.1:9200/_cluster/settings" -H "Content-Type: application/json" -d '{
     "persistent": {
       "cluster.routing.allocation.disk.watermark.low": "90%",
       "cluster.routing.allocation.disk.watermark.high": "95%",
       "cluster.routing.allocation.disk.watermark.flood_stage": "97%"
     }
   }'
   ```
3. **Kilitli İndekslerin Salt-Okunur Kilidinin Kaldırılması:**
   ```bash
   curl -X PUT "http://127.0.0.1:9200/_all/_settings" -H "Content-Type: application/json" -d '{
     "index.blocks.read_only_allow_delete": null
   }'
   ```

---

## 2. Problem: Tek Düğümlü (Single-Node) Kümelerde Cluster Health "Yellow" Durumu

### Semptom
`curl http://127.0.0.1:9200/_cluster/health` sorgusunda küme durumu `yellow` olarak kalıyor ve `unassigned_shards` sayısı artıyordu:
```json
{
  "cluster_name": "docker-cluster",
  "status": "yellow",
  "number_of_nodes": 1,
  "unassigned_shards": 15
}
```

### Kök Neden
Elasticsearch varsayılan olarak her indeks için 1 primary ve 1 replica shard (`number_of_replicas: 1`) oluşturur. Tek düğümlü (single-node) ortamlarda kural gereği replica shard birincil shard ile aynı düğüme yerleştirilemez; bu nedenle replica shard'lar `UNASSIGNED` olarak bekler ve küme sağlığı sarıya (Yellow) düşer.

### Çözüm
1. Mevcut tüm indekslerin replica sayısı `0` olarak ayarlandı:
   ```bash
   curl -X PUT "http://127.0.0.1:9200/_all/_settings" -H "Content-Type: application/json" -d '{
     "index": {
       "number_of_replicas": 0
     }
   }'
   ```
2. Gelecekte oluşturulacak tüm indeksler için varsayılan şablon tanımlandı:
   ```bash
   curl -X PUT "http://127.0.0.1:9200/_template/default_single_node" -H "Content-Type: application/json" -d '{
     "index_patterns": ["*"],
     "settings": {
       "number_of_replicas": 0
     }
   }'
   ```
   *Sonuç:* Küme sağlığı anında `%100 active shards` ve **`GREEN`** durumuna geçti.
