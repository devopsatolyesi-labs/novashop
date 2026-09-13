#!/usr/bin/env python3
"""
Cloudflare DNS Automation for DevOps Atölyesi Training Platform.
Automatically creates or updates DNS A-records for students:
  - studentXX-novashop.devopsatolyesi.com
  - studentXX-gitlab.devopsatolyesi.com
  - studentXX-harbor.devopsatolyesi.com
  - studentXX-sonarqube.devopsatolyesi.com
  - studentXX-jenkins.devopsatolyesi.com
  - studentXX-argocd.devopsatolyesi.com
  - studentXX-grafana.devopsatolyesi.com
  - studentXX-cockpit.devopsatolyesi.com

Zero external dependencies: Uses Python standard library (urllib + json).
"""

import csv
import json
import os
import sys
import urllib.error
import urllib.request

SUBDOMAIN_SUFFIXES = [
    "novashop",
    "gitlab",
    "harbor",
    "sonarqube",
    "jenkins",
    "argocd",
    "grafana",
    "cockpit",
]

DOMAIN = os.environ.get("CLOUDFLARE_DOMAIN", "devopsatolyesi.com")
ZONE_ID = os.environ.get("CLOUDFLARE_ZONE_ID", "25d95256b65efd93ea3de7df1aaab798")
API_TOKEN = os.environ.get("CLOUDFLARE_API_TOKEN")

def cf_api(method, endpoint, payload=None):
    url = f"https://api.cloudflare.com/client/v4/zones/{ZONE_ID}{endpoint}"
    headers = {
        "Authorization": f"Bearer {API_TOKEN}",
        "Content-Type": "application/json",
    }
    data = json.dumps(payload).encode("utf-8") if payload else None
    req = urllib.request.Request(url, data=data, headers=headers, method=method)
    try:
        with urllib.request.urlopen(req) as resp:
            return json.loads(resp.read().decode("utf-8"))
    except urllib.error.HTTPError as e:
        err_msg = e.read().decode("utf-8")
        print(f"❌ API Hatası ({e.code}): {err_msg}", file=sys.stderr)
        return None

def get_existing_records():
    print("🔍 Cloudflare mevcut DNS kayıtları alınıyor...")
    res = cf_api("GET", "/dns_records?type=A&per_page=100")
    if not res or not res.get("success"):
        print("❌ Kayıtlar alınamadı!", file=sys.stderr)
        return {}
    records = {}
    for r in res.get("result", []):
        records[r["name"]] = {"id": r["id"], "content": r["content"], "proxied": r["proxied"]}
    return records

def sync_student(student_id, vm_ip, existing_records, proxied=False):
    print(f"\n🚀 Öğrenci İşleniyor: [{student_id}] -> IP: {vm_ip}")
    for suffix in SUBDOMAIN_SUFFIXES:
        subdomain = f"{student_id}-{suffix}.{DOMAIN}"
        payload = {
            "type": "A",
            "name": subdomain,
            "content": vm_ip,
            "ttl": 1,  # Auto TTL
            "proxied": proxied,  # False for direct port routing / let's encrypt flexibility
        }
        if subdomain in existing_records:
            cur = existing_records[subdomain]
            if cur["content"] == vm_ip and cur["proxied"] == proxied:
                print(f"  ✓ {subdomain} zaten güncel ({vm_ip})")
            else:
                print(f"  🔄 Güncelleniyor: {subdomain} -> {vm_ip}")
                cf_api("PUT", f"/dns_records/{cur['id']}", payload)
        else:
            print(f"  ➕ Oluşturuluyor: {subdomain} -> {vm_ip}")
            cf_api("POST", "/dns_records", payload)

def main():
    csv_file = sys.argv[1] if len(sys.argv) > 1 else "students.csv"
    if not os.path.exists(csv_file):
        print(f"❌ Dosya bulunamadı: {csv_file}")
        sys.exit(1)

    if not API_TOKEN:
        print("❌ HATA: CLOUDFLARE_API_TOKEN çevre değişkeni ayarlanmamış!")
        print("Kullanım:")
        print("  export CLOUDFLARE_API_TOKEN=\"your-api-token\"")
        print(f"  python3 {sys.argv[0]} [students.csv]")
        sys.exit(1)

    existing = get_existing_records()

    with open(csv_file, mode="r", encoding="utf-8") as f:
        reader = csv.reader(f)
        for row in reader:
            if not row or row[0].strip().startswith("#"):
                continue
            student_id = row[0].strip()
            vm_ip = row[1].strip()
            sync_student(student_id, vm_ip, existing)

    print("\n✅ Tüm öğrenci DNS kayıtları başarıyla senkronize edildi!")

if __name__ == "__main__":
    main()
