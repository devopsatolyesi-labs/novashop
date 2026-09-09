-- NovaShop DevOps Store — Catalog Database Schema & Seed Data
-- Altyapı Katmanı: AWS RDS MySQL / MariaDB (Private Subnet)
-- Lab: LAB-02-AWS-BASICS

CREATE DATABASE IF NOT EXISTS catalogdb
  CHARACTER SET utf8mb4
  COLLATE utf8mb4_unicode_ci;

USE catalogdb;

-- 1. Tablo: tags
CREATE TABLE IF NOT EXISTS tags (
    name VARCHAR(191) NOT NULL PRIMARY KEY,
    display_name VARCHAR(255) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 2. Tablo: products
CREATE TABLE IF NOT EXISTS products (
    id VARCHAR(191) NOT NULL PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    description TEXT NOT NULL,
    price INT NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 3. Tablo: product_tags (Many-to-Many İlişki Tablosu)
CREATE TABLE IF NOT EXISTS product_tags (
    product_id VARCHAR(191) NOT NULL,
    tag_name VARCHAR(191) NOT NULL,
    PRIMARY KEY (product_id, tag_name),
    CONSTRAINT fk_product_tags_product FOREIGN KEY (product_id) REFERENCES products(id) ON DELETE CASCADE,
    CONSTRAINT fk_product_tags_tag FOREIGN KEY (tag_name) REFERENCES tags(name) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 4. Başlangıç Etiketleri (Seed Tags)
INSERT INTO tags (name, display_name) VALUES
('accessories', 'Aksesuarlar'),
('clothing', 'Giyim & Tekstil'),
('food', 'Gıda & Atıştırmalık'),
('vehicles', 'Ulaşım & Mobilite')
ON DUPLICATE KEY UPDATE display_name=VALUES(display_name);

-- 5. NovaShop Ürünleri (Seed Products - 12 Ürün)
INSERT INTO products (id, name, description, price) VALUES
('cc789f85-1476-452a-8100-9e74502198e0', 'Kubernetes Cluster Mug', 'Yüksek dayanıklı seramik kahve kupası. Düğüm arızalarında otomatik kahve podu yeniden başlatma özelliği içerir. 350ml kapasite ve bulaşık makinesinde yıkanabilir.', 45),
('87e89b11-d319-446d-b9be-50adcca5224a', 'Docker Container Hoodie', 'Her ortamda tutarlı çalışan, soğuk hava dalgalarını izole eden %100 pamuklu DevOps kapüşonlu sweatshirt. Hafif, nefes alabilir ve cepleri fermuarlıdır.', 120),
('4f18544b-70a5-4352-8e19-0d070f46745d', 'CI/CD Pipeline Sneakers', 'Hatasız derleme ve hızlı dağıtım için tasarlanmış ergonomik yürüyüş ayakkabısı. Dağıtım döngülerinde maksimum konfor ve zemin tutuşu sağlar.', 180),
('79bce3f3-935f-4912-8c62-0d2f3e059405', 'DevOps Engineer Bowtie', 'Sprint incelemeleri ve mimari sunumlar için akıllı papyon. Mikrofon ve gürültü önleme filtresiyle entegre toplantı hazır görünümü sunar.', 60),
('d27cf49f-b689-4a75-a249-d373e0330bb5', 'Terraform Cloud Pen', 'Altyapıyı kod olarak not almak için tasarlanmış metal tükenmez kalem. Hızlı kuruyan mürekkep ve değişken tanımlama desteğiyle birlikte gelir.', 35),
('1ca35e86-4b4c-4124-b6b5-076ba4134d0d', 'Git Merge Sunglasses', 'Conflict çözümlerinde parlak ekran ışığını süzen UV korumalı şık güneş gözlüğü. Mat siyah çerçeve ve polarize camlar.', 95),
('631a3db5-ac07-492c-a994-8cd56923c112', 'Prometheus Metric Cup', 'RED/USE metriklerini izlerken sıcaklığı sabit tutan vakumlu çelik termos. 12 saat sıcak ve 24 saat soğuk tutma kapasitesi.', 50),
('8757729a-c518-4356-8694-9e795a9b3237', 'Argo CD GitOps Candy', 'Dağıtım senkronizasyonu sırasında stresi azaltan nane aromalı ferahlatıcı şekerler. %100 doğal meyve aroması.', 15),
('d4edfedb-dbe9-4dd9-aae8-009489394955', 'Ansible Playbook Spinner', 'Uzun süren idempotency kontrolleri sırasında odağı artıran rulmanlı masaüstü stres çarkı. Dengeli ağırlık dağılımı.', 25),
('a1258cd2-176c-4507-ade6-746dab5ad625', 'AWS Cloud Roadster', 'Multi-AZ yedeklilik ile çalışan premium elektrikli araç modeli. Düşük gecikme süreli ivmelenme ve otomatik rota optimizasyonu.', 45000),
('d3104128-1d14-4465-99d3-8ab9267c687b', 'Cloud-Native SkyCycle', 'Hibrit elektrikli kentsel ulaşım aracı. Yüksek verimli batarya, GPS takip ve hafif karbon fiber gövde.', 8500),
('d77f9ae6-e9a8-4a3e-86bd-b72af75cbc49', 'Zero Trust Phantom Cruiser', 'Şifreli telemetri ve çok katmanlı savunma sistemine sahip otonom elektrikli scooter. Şehir içi çevik ulaşım.', 3200)
ON DUPLICATE KEY UPDATE name=VALUES(name), description=VALUES(description), price=VALUES(price);

-- 6. Ürün - Etiket Eşleştirmeleri (Seed Product Tags)
INSERT INTO product_tags (product_id, tag_name) VALUES
('cc789f85-1476-452a-8100-9e74502198e0', 'accessories'),
('87e89b11-d319-446d-b9be-50adcca5224a', 'clothing'),
('4f18544b-70a5-4352-8e19-0d070f46745d', 'clothing'),
('79bce3f3-935f-4912-8c62-0d2f3e059405', 'clothing'),
('d27cf49f-b689-4a75-a249-d373e0330bb5', 'accessories'),
('1ca35e86-4b4c-4124-b6b5-076ba4134d0d', 'accessories'),
('631a3db5-ac07-492c-a994-8cd56923c112', 'accessories'),
('8757729a-c518-4356-8694-9e795a9b3237', 'food'),
('d4edfedb-dbe9-4dd9-aae8-009489394955', 'accessories'),
('a1258cd2-176c-4507-ade6-746dab5ad625', 'vehicles'),
('d3104128-1d14-4465-99d3-8ab9267c687b', 'vehicles'),
('d77f9ae6-e9a8-4a3e-86bd-b72af75cbc49', 'vehicles')
ON DUPLICATE KEY UPDATE tag_name=VALUES(tag_name);

-- 7. Doğrulama Sorguları (Verification Queries)
SELECT COUNT(*) AS total_products FROM products;
SELECT p.name, t.display_name, p.price 
FROM products p 
JOIN product_tags pt ON p.id = pt.product_id 
JOIN tags t ON pt.tag_name = t.name 
LIMIT 5;
