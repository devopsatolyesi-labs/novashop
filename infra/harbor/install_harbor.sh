#!/usr/bin/env bash
set -euo pipefail

HARBOR_VERSION="v2.10.0"
INSTALL_DIR="/opt/harbor"

echo "==> Harbor ${HARBOR_VERSION} İndiriliyor..."
sudo mkdir -p "${INSTALL_DIR}"
cd /tmp
if [ ! -f "harbor-online-installer-${HARBOR_VERSION}.tgz" ]; then
    curl -sSLo "harbor-online-installer-${HARBOR_VERSION}.tgz" "https://github.com/goharbor/harbor/releases/download/${HARBOR_VERSION}/harbor-online-installer-${HARBOR_VERSION}.tgz"
fi
sudo tar -xzf "harbor-online-installer-${HARBOR_VERSION}.tgz" -C /opt/

echo "==> Harbor Yapılandırması Hazırlanıyor..."
sudo cp /opt/harbor/harbor.yml.tmpl /opt/harbor/harbor.yml

# HTTP Portunu 18082 yapalım (Nginx 80/443 ile çakışmasın)
# HTTPS bloğunu devre dışı bırakalım (SSL'i Nginx Reverse Proxy çözecek)
sudo sed -i 's/port: 80/port: 18082/' /opt/harbor/harbor.yml
sudo sed -i 's/^https:/#https:/' /opt/harbor/harbor.yml
sudo sed -i 's/^  port: 443/#  port: 443/' /opt/harbor/harbor.yml
sudo sed -i 's/^  certificate:/#  certificate:/' /opt/harbor/harbor.yml
sudo sed -i 's/^  private_key:/#  private_key:/' /opt/harbor/harbor.yml

echo "==> Harbor Kurulumu Başlatılıyor (Trivy Scanner Dahil)..."
cd /opt/harbor
sudo ./install.sh --with-trivy

echo "==> Harbor başarıyla kuruldu ve başlatıldı!"
echo "Erişim (Doğrudan IP): http://<UBUNTU_IP>:18082"
echo "Kullanıcı: admin / Şifre: Harbor12345"
