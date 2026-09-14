import base64
import subprocess
from PIL import Image

def get_base64(path):
    with open(path, "rb") as f:
        return f"data:image/png;base64,{base64.b64encode(f.read()).decode('utf-8')}"

ec2_b64 = get_base64("/tmp/icon_ec2.png")
rds_b64 = get_base64("/tmp/icon_rds.png")

html_content = f"""<!DOCTYPE html>
<html lang="tr">
<head>
<meta charset="UTF-8">
<style>
  * {{ box-sizing: border-box; margin: 0; padding: 0; font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, "Helvetica Neue", Arial, sans-serif; }}
  body {{
    width: 1540px;
    height: 980px;
    background-color: #ffffff;
    color: #16191f;
    padding: 24px 32px;
    display: flex;
    flex-direction: column;
    justify-content: space-between;
  }}

  /* Header */
  .header {{
    display: flex;
    justify-content: space-between;
    align-items: center;
    border-bottom: 2px solid #eaeded;
    padding-bottom: 14px;
  }}
  .header-left {{
    display: flex;
    align-items: center;
    gap: 16px;
  }}
  .aws-logo-badge {{
    background: #232f3e;
    color: #ff9900;
    font-weight: 900;
    font-size: 17px;
    padding: 7px 16px;
    border-radius: 6px;
    letter-spacing: 1px;
    display: flex;
    align-items: center;
    gap: 6px;
  }}
  .aws-logo-badge span {{ color: #ffffff; font-weight: 500; }}
  .title-block h1 {{
    font-size: 23px;
    font-weight: 800;
    color: #16191f;
    letter-spacing: -0.3px;
  }}
  .title-block p {{
    font-size: 13.5px;
    color: #545b64;
    margin-top: 3px;
  }}
  .header-right {{
    display: flex;
    gap: 10px;
    align-items: center;
  }}
  .badge {{
    padding: 7px 14px;
    border-radius: 6px;
    font-size: 12.5px;
    font-weight: 700;
  }}
  .badge-region {{
    background: #f2f3f3;
    border: 1px solid #d5dbdb;
    color: #16191f;
    display: flex;
    align-items: center;
    gap: 6px;
  }}
  .badge-single-az {{
    background: #e8f5e9;
    border: 1px solid #a5d6a7;
    color: #1b5e20;
  }}

  /* Internet Bar */
  .internet-bar {{
    display: flex;
    flex-direction: column;
    align-items: center;
    justify-content: center;
    margin: 4px 0 2px 0;
    position: relative;
  }}
  .internet-cloud-box {{
    display: flex;
    align-items: center;
    gap: 12px;
    background: #ffffff;
    border: 2px solid #0073bb;
    padding: 8px 30px;
    border-radius: 30px;
    box-shadow: 0 3px 8px rgba(0, 115, 187, 0.12);
    z-index: 2;
  }}
  .cloud-icon {{ font-size: 26px; }}
  .cloud-text {{ font-size: 13.5px; font-weight: 800; color: #16191f; }}
  .cloud-sub {{ font-size: 11px; color: #545b64; }}

  /* SVG Ingress Connector */
  .ingress-svg {{
    width: 100%;
    height: 28px;
    display: block;
    margin: -6px 0 -4px 0;
  }}

  /* Main Comparison Grid: Console vs Terraform */
  .vpcs-container {{
    display: grid;
    grid-template-columns: 1fr 1fr;
    gap: 24px;
    flex-grow: 1;
    margin: 4px 0 10px 0;
  }}

  /* VPC Box */
  .vpc-card {{
    border: 2px solid #248814;
    border-radius: 12px;
    background: #ffffff;
    padding: 16px;
    display: flex;
    flex-direction: column;
    position: relative;
    box-shadow: 0 4px 12px rgba(36, 136, 20, 0.08);
  }}
  .vpc-header {{
    display: flex;
    justify-content: space-between;
    align-items: center;
    margin-bottom: 10px;
    padding-bottom: 8px;
    border-bottom: 1px solid #e1e4e8;
  }}
  .vpc-title-group {{
    display: flex;
    align-items: center;
    gap: 8px;
  }}
  .vpc-icon-tag {{
    background: #248814;
    color: white;
    font-size: 11px;
    font-weight: 800;
    padding: 3px 8px;
    border-radius: 4px;
    letter-spacing: 0.5px;
  }}
  .vpc-name {{
    font-size: 15.5px;
    font-weight: 800;
    color: #16191f;
  }}
  .vpc-cidr {{
    font-family: ui-monospace, SFMono-Regular, Menlo, monospace;
    font-size: 12px;
    background: #f1f8f1;
    border: 1px solid #c8e6c9;
    color: #1b5e20;
    padding: 3px 9px;
    border-radius: 4px;
    font-weight: 700;
  }}

  /* IGW Bar */
  .igw-bar {{
    display: flex;
    justify-content: space-between;
    align-items: center;
    background: #fff8e1;
    border: 1.5px solid #ffe082;
    border-radius: 8px;
    padding: 7px 14px;
    margin-bottom: 12px;
  }}
  .igw-left {{
    display: flex;
    align-items: center;
    gap: 8px;
    font-size: 12.5px;
    font-weight: 800;
    color: #b78103;
  }}
  .igw-flow {{
    font-size: 11.5px;
    color: #795548;
    font-weight: 700;
  }}

  /* AZ Grid inside VPC */
  .az-layout {{
    display: grid;
    grid-template-columns: 2.15fr 1fr;
    gap: 12px;
    flex-grow: 1;
  }}

  /* AZ Box (Dashed AWS boundary) */
  .az-box {{
    border: 2px dashed #0073bb;
    border-radius: 10px;
    background: #fafbfc;
    padding: 12px;
    display: flex;
    flex-direction: column;
    gap: 9px;
    position: relative;
  }}
  .az-box.az-primary {{
    border-color: #0073bb;
  }}
  .az-box.az-secondary {{
    border-color: #90a4ae;
    background: #fbfcfc;
  }}
  .az-header {{
    display: flex;
    justify-content: space-between;
    align-items: center;
    font-size: 12px;
    font-weight: 800;
    color: #0073bb;
    padding-bottom: 5px;
    border-bottom: 1px dashed #d0d7de;
  }}
  .az-header.secondary-header {{
    color: #546e7a;
  }}
  .az-tag {{
    font-size: 10.5px;
    font-weight: 800;
    padding: 2px 7px;
    border-radius: 4px;
    background: #e1f5fe;
    color: #0277bd;
  }}

  /* Subnet Cards */
  .subnet-card {{
    border-radius: 8px;
    padding: 10px 12px;
    display: flex;
    flex-direction: column;
    gap: 8px;
  }}
  .public-subnet {{
    border: 1.5px solid #2e7d32;
    background: #ffffff;
  }}
  .private-subnet {{
    border: 1.5px solid #1565c0;
    background: #ffffff;
  }}
  .secondary-subnet {{
    border: 1.5px dashed #78909c;
    background: #ffffff;
    height: calc(100% - 24px);
    display: flex;
    flex-direction: column;
    justify-content: space-between;
  }}

  .subnet-top-label {{
    display: flex;
    justify-content: space-between;
    align-items: center;
    font-size: 11.5px;
    font-weight: 800;
  }}
  .public-subnet .subnet-top-label {{ color: #2e7d32; }}
  .private-subnet .subnet-top-label {{ color: #1565c0; }}
  .secondary-subnet .subnet-top-label {{ color: #546e7a; }}

  .subnet-cidr-tag {{
    font-family: ui-monospace, SFMono-Regular, Menlo, monospace;
    font-size: 11px;
    font-weight: 700;
    background: #f0f0f0;
    padding: 2px 6px;
    border-radius: 3px;
    color: #333;
  }}

  /* Resource Instances inside Subnet */
  .instance-row {{
    display: flex;
    align-items: center;
    gap: 12px;
    background: #f8f9fa;
    border: 1px solid #e9ecef;
    border-radius: 6px;
    padding: 8px 12px;
  }}
  .aws-service-icon {{
    width: 48px;
    height: 48px;
    border-radius: 6px;
    object-fit: cover;
    flex-shrink: 0;
    box-shadow: 0 2px 5px rgba(0,0,0,0.1);
  }}

  .instance-meta {{
    flex-grow: 1;
  }}
  .instance-title {{
    font-size: 13.5px;
    font-weight: 800;
    color: #16191f;
    display: flex;
    align-items: center;
    justify-content: space-between;
  }}
  .instance-sub {{
    font-size: 11.5px;
    color: #545b64;
    font-family: ui-monospace, SFMono-Regular, Menlo, monospace;
    margin-top: 2px;
  }}
  .instance-badge-row {{
    display: flex;
    gap: 6px;
    margin-top: 4px;
    font-size: 10.5px;
    font-weight: 700;
  }}
  .badge-port {{
    background: #e3f2fd;
    color: #1565c0;
    padding: 2px 7px;
    border-radius: 3px;
  }}
  .badge-ssh {{
    background: #f5f5f5;
    color: #424242;
    padding: 2px 7px;
    border-radius: 3px;
  }}
  .badge-private-only {{
    background: #ffebee;
    color: #c62828;
    padding: 2px 7px;
    border-radius: 3px;
  }}

  /* Intra-AZ Connection Arrow */
  .intra-az-flow {{
    display: flex;
    justify-content: center;
    align-items: center;
    gap: 8px;
    padding: 5px 8px;
    background: #e8f0fe;
    border: 1.5px dashed #1a73e8;
    border-radius: 6px;
    font-size: 11.5px;
    font-weight: 800;
    color: #1a73e8;
  }}

  /* SG Info Pills */
  .sg-info-row {{
    display: flex;
    justify-content: space-between;
    font-size: 11px;
    color: #555;
    background: #ffffff;
    padding: 4px 8px;
    border-radius: 4px;
    border: 1px solid #e0e0e0;
  }}

  /* Footer */
  .footer-note {{
    background: #f2f3f3;
    border: 1px solid #d5dbdb;
    border-radius: 8px;
    padding: 10px 18px;
    display: flex;
    justify-content: space-between;
    align-items: center;
    font-size: 12.5px;
    color: #374151;
  }}
  .footer-note strong {{ color: #111827; }}
  .footer-highlight {{ color: #0073bb; font-weight: 800; }}
</style>
</head>
<body>

  <!-- Top Header -->
  <div class="header">
    <div class="header-left">
      <div class="aws-logo-badge">
        AWS <span>Cloud</span>
      </div>
      <div class="title-block">
        <h1>NovaShop 2-Katmanlı Altyapı: Tek AZ (Single-AZ) Mimarisi</h1>
        <p>LAB-02 — Web (EC2) ve Veritabanı (RDS) Katmanlarının Aynı Availability Zone (us-east-1a) İçinde Konuşlandırılması</p>
      </div>
    </div>
    <div class="header-right">
      <div class="badge badge-single-az">✓ Single-AZ (Tek AZ'de 2 Katman)</div>
      <div class="badge badge-region">📍 us-east-1 (N. Virginia)</div>
    </div>
  </div>

  <!-- Internet & Clients -->
  <div class="internet-bar">
    <div class="internet-cloud-box">
      <span class="cloud-icon">🌐</span>
      <div>
        <div class="cloud-text">İstemci / Web Tarayıcısı (Internet Users)</div>
        <div class="cloud-sub">HTTP Port 80 (Web İstekleri) &bull; SSH Port 22 (Yönetim Erişimi)</div>
      </div>
    </div>
  </div>

  <!-- SVG Ingress Connector Lines -->
  <svg class="ingress-svg" viewBox="0 0 1476 28">
    <!-- Center drop -->
    <line x1="738" y1="0" x2="738" y2="12" stroke="#0073bb" stroke-width="2" />
    <!-- Horizontal spread -->
    <line x1="369" y1="12" x2="1107" y2="12" stroke="#0073bb" stroke-width="2" />
    <!-- Left drop to Console IGW -->
    <line x1="369" y1="12" x2="369" y2="28" stroke="#0073bb" stroke-width="2" marker-end="url(#arrow)" />
    <!-- Right drop to TF IGW -->
    <line x1="1107" y1="12" x2="1107" y2="28" stroke="#0073bb" stroke-width="2" marker-end="url(#arrow)" />
    <defs>
      <marker id="arrow" viewBox="0 0 10 10" refX="5" refY="5" markerWidth="6" markerHeight="6" orient="auto-start-reverse">
        <path d="M 0 0 L 10 5 L 0 10 z" fill="#0073bb"/>
      </marker>
    </defs>
  </svg>

  <!-- VPCs Container (Console vs Terraform) -->
  <div class="vpcs-container">

    <!-- LEFT: AWS CONSOLE VPC -->
    <div class="vpc-card">
      <div class="vpc-header">
        <div class="vpc-title-group">
          <span class="vpc-icon-tag">VPC</span>
          <span class="vpc-name">novashop-console-vpc</span>
        </div>
        <span class="vpc-cidr">10.0.0.0/16 (Bölüm 1: Web UI)</span>
      </div>

      <!-- IGW -->
      <div class="igw-bar">
        <div class="igw-left">
          <span>🚪</span>
          <span>novashop-console-igw (Internet Gateway)</span>
        </div>
        <div class="igw-flow">0.0.0.0/0 &rarr; HTTP (:80) Girişi</div>
      </div>

      <!-- AZ Layout -->
      <div class="az-layout">
        
        <!-- Primary AZ (us-east-1a): CONTAINS BOTH WEB AND RDS -->
        <div class="az-box az-primary">
          <div class="az-header">
            <span>Availability Zone: us-east-1a</span>
            <span class="az-tag">TEK AZ (Aktif Altyapı)</span>
          </div>

          <!-- Katman 1: Public Subnet (Web) -->
          <div class="subnet-card public-subnet">
            <div class="subnet-top-label">
              <span>🔒 Katman 1: Public Subnet (web-subnet)</span>
              <span class="subnet-cidr-tag">10.0.1.0/24</span>
            </div>
            <div class="instance-row">
              <img src="{ec2_b64}" class="aws-service-icon" alt="EC2">
              <div class="instance-meta">
                <div class="instance-title">
                  <span>1x EC2 Web Sunucusu</span>
                  <span style="font-size:11px; font-weight:800; color:#2e7d32;">Public IP</span>
                </div>
                <div class="instance-sub">novashop-console-web &bull; Ubuntu 22.04</div>
                <div class="instance-badge-row">
                  <span class="badge-port">HTTP :80 (Nginx)</span>
                  <span class="badge-ssh">SSH :22</span>
                  <span style="color:#555; font-size:10px;">SG: web-sg</span>
                </div>
              </div>
            </div>
            <div class="sg-info-row">
              <span>Route Table: 0.0.0.0/0 &rarr; IGW</span>
              <span style="color:#2e7d32; font-weight:700;">Dış İnternete Açık</span>
            </div>
          </div>

          <!-- Arrow between Web and RDS inside SAME AZ -->
          <div class="intra-az-flow">
            <span>⬇️</span>
            <span>Aynı AZ İçi MySQL Port 3306 (Özel Ağ İletişimi - Yalnızca web-sg)</span>
            <span>⬇️</span>
          </div>

          <!-- Katman 2: Private Subnet (RDS Database) -->
          <div class="subnet-card private-subnet">
            <div class="subnet-top-label">
              <span>🗄️ Katman 2: Private Subnet 1 (db-subnet-1a)</span>
              <span class="subnet-cidr-tag">10.0.10.0/24</span>
            </div>
            <div class="instance-row">
              <img src="{rds_b64}" class="aws-service-icon" alt="RDS">
              <div class="instance-meta">
                <div class="instance-title">
                  <span>1x RDS MySQL Instance (Single-AZ)</span>
                </div>
                <div class="instance-sub">novashop-console-db &bull; MySQL 8.0 &bull; db.t3.small</div>
                <div class="instance-badge-row">
                  <span class="badge-port">MySQL :3306</span>
                  <span class="badge-private-only">Dışa Kapalı (Private)</span>
                  <span style="color:#555; font-size:10px;">SG: rds-sg</span>
                </div>
              </div>
            </div>
            <div class="sg-info-row">
              <span>Route Table: Sadece Yerel Ağ (Local Only)</span>
              <span style="color:#c62828; font-weight:800;">Dış İnternet Doğrudan Erişim: YASAK</span>
            </div>
          </div>

        </div>

        <!-- Secondary AZ (us-east-1b): RDS DB Subnet Group Requirement -->
        <div class="az-box az-secondary">
          <div class="az-header secondary-header">
            <span>AZ: us-east-1b</span>
            <span style="font-size:10.5px; color:#546e7a;">Standby AZ</span>
          </div>

          <div class="subnet-card secondary-subnet">
            <div class="subnet-top-label">
              <span>Private Subnet 2</span>
              <span class="subnet-cidr-tag">10.0.11.0/24</span>
            </div>
            <div style="text-align:center; padding:20px 8px;">
              <div style="font-size:32px; margin-bottom:8px;">💤</div>
              <div style="font-size:12.5px; font-weight:800; color:#37474f;">DB Subnet Group</div>
              <div style="font-size:11px; color:#78909c; margin-top:6px; line-height:1.4;">
                AWS RDS şartı gereği 2. AZ tanımlıdır.<br/>
                <strong>Single-AZ</strong> olduğu için aktif veritabanı <code>us-east-1a</code>'dadır.
              </div>
            </div>
            <div class="sg-info-row" style="background:#f8f9fa;">
              <span>Standby / Boş</span>
              <span style="color:#78909c;">Trafik Yok</span>
            </div>
          </div>
        </div>

      </div>
    </div>

    <!-- RIGHT: TERRAFORM IAC VPC -->
    <div class="vpc-card">
      <div class="vpc-header">
        <div class="vpc-title-group">
          <span class="vpc-icon-tag" style="background:#5c4ee5;">IaC</span>
          <span class="vpc-name">novashop-tf-vpc</span>
        </div>
        <span class="vpc-cidr" style="background:#ede7f6; border-color:#d1c4e9; color:#4527a0;">10.1.0.0/16 (Bölüm 2: Terraform)</span>
      </div>

      <!-- IGW -->
      <div class="igw-bar" style="background:#f3e5f5; border-color:#e1bee7;">
        <div class="igw-left" style="color:#6a1b9a;">
          <span>🚪</span>
          <span>novashop-tf-igw (Internet Gateway)</span>
        </div>
        <div class="igw-flow" style="color:#4a148c;">0.0.0.0/0 &rarr; HTTP (:80) Girişi</div>
      </div>

      <!-- AZ Layout -->
      <div class="az-layout">
        
        <!-- Primary AZ (us-east-1a): CONTAINS BOTH WEB AND RDS -->
        <div class="az-box az-primary">
          <div class="az-header">
            <span>Availability Zone: us-east-1a</span>
            <span class="az-tag">TEK AZ (Aktif Altyapı)</span>
          </div>

          <!-- Katman 1: Public Subnet (Web) -->
          <div class="subnet-card public-subnet">
            <div class="subnet-top-label">
              <span>🔒 Katman 1: Public Subnet (public-1a)</span>
              <span class="subnet-cidr-tag">10.1.1.0/24</span>
            </div>
            <div class="instance-row">
              <img src="{ec2_b64}" class="aws-service-icon" alt="EC2">
              <div class="instance-meta">
                <div class="instance-title">
                  <span>1x EC2 Web Sunucusu</span>
                  <span style="font-size:11px; font-weight:800; color:#2e7d32;">Public IP</span>
                </div>
                <div class="instance-sub">novashop-tf-web &bull; Ubuntu 22.04</div>
                <div class="instance-badge-row">
                  <span class="badge-port">HTTP :80 (Nginx)</span>
                  <span class="badge-ssh">SSH :22</span>
                  <span style="color:#555; font-size:10px;">SG: web-sg</span>
                </div>
              </div>
            </div>
            <div class="sg-info-row">
              <span>Route Table: 0.0.0.0/0 &rarr; IGW</span>
              <span style="color:#2e7d32; font-weight:700;">Dış İnternete Açık</span>
            </div>
          </div>

          <!-- Arrow between Web and RDS inside SAME AZ -->
          <div class="intra-az-flow">
            <span>⬇️</span>
            <span>Aynı AZ İçi MySQL Port 3306 (Özel Ağ İletişimi - Yalnızca web-sg)</span>
            <span>⬇️</span>
          </div>

          <!-- Katman 2: Private Subnet (RDS Database) -->
          <div class="subnet-card private-subnet">
            <div class="subnet-top-label">
              <span>🗄️ Katman 2: Private Subnet 1 (private-1a)</span>
              <span class="subnet-cidr-tag">10.1.10.0/24</span>
            </div>
            <div class="instance-row">
              <img src="{rds_b64}" class="aws-service-icon" alt="RDS">
              <div class="instance-meta">
                <div class="instance-title">
                  <span>1x RDS MySQL Instance (Single-AZ)</span>
                </div>
                <div class="instance-sub">novashop-tf-db &bull; MySQL 8.0 &bull; db.t3.small</div>
                <div class="instance-badge-row">
                  <span class="badge-port">MySQL :3306</span>
                  <span class="badge-private-only">Dışa Kapalı (Private)</span>
                  <span style="color:#555; font-size:10px;">SG: rds-sg</span>
                </div>
              </div>
            </div>
            <div class="sg-info-row">
              <span>Route Table: Sadece Yerel Ağ (Local Only)</span>
              <span style="color:#c62828; font-weight:800;">Dış İnternet Doğrudan Erişim: YASAK</span>
            </div>
          </div>

        </div>

        <!-- Secondary AZ (us-east-1b): RDS DB Subnet Group Requirement -->
        <div class="az-box az-secondary">
          <div class="az-header secondary-header">
            <span>AZ: us-east-1b</span>
            <span style="font-size:10.5px; color:#546e7a;">Standby AZ</span>
          </div>

          <div class="subnet-card secondary-subnet">
            <div class="subnet-top-label">
              <span>Private Subnet 2 (private-1b)</span>
              <span class="subnet-cidr-tag">10.1.11.0/24</span>
            </div>
            <div style="text-align:center; padding:20px 8px;">
              <div style="font-size:32px; margin-bottom:8px;">💤</div>
              <div style="font-size:12.5px; font-weight:800; color:#37474f;">DB Subnet Group</div>
              <div style="font-size:11px; color:#78909c; margin-top:6px; line-height:1.4;">
                AWS RDS şartı gereği 2. AZ tanımlıdır.<br/>
                <strong>Single-AZ</strong> olduğu için aktif veritabanı <code>us-east-1a</code>'dadır.
              </div>
            </div>
            <div class="sg-info-row" style="background:#f8f9fa;">
              <span>Standby / Boş</span>
              <span style="color:#78909c;">Trafik Yok</span>
            </div>
          </div>
        </div>

      </div>
    </div>

  </div>

  <!-- Footer Note -->
  <div class="footer-note">
    <div>
      <strong>Mimari Kuralı:</strong> LAB-02 altyapısı <span class="footer-highlight">Tek AZ (Single-AZ: us-east-1a)</span> üzerinde 2-katmanlıdır (Public Web + Private Database).
    </div>
    <div>
      RDS DB Subnet Group en az 2 AZ gerektirdiği için <code>us-east-1b</code> tanımlanmıştır; ancak aktif veritabanı <code>us-east-1a</code>'dadır.
    </div>
  </div>

</body>
</html>
"""

html_path = "/tmp/lab02_arch_v2.html"
png_path = "/tmp/lab02_arch_v2.png"
jpg_path = "/tmp/lab02_arch_v2.jpg"

with open(html_path, "w", encoding="utf-8") as f:
    f.write(html_content)

chrome_cmd = [
    "/Applications/Google Chrome.app/Contents/MacOS/Google Chrome",
    "--headless",
    "--disable-gpu",
    "--window-size=1540,980",
    "--screenshot=" + png_path,
    "file://" + html_path
]

print("Rendering HTML with Chrome...")
subprocess.run(chrome_cmd, check=True)

im = Image.open(png_path)
rgb_im = im.convert("RGB")
rgb_im.save(jpg_path, quality=95)
print(f"Generated {jpg_path} with size {rgb_im.size}")
