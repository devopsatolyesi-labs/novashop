#!/usr/bin/env bash
# ==============================================================================
# NovaShop — Eğitmen Cloudflare DNS & Full SSL Proxy Otomasyon Betiği
# ==============================================================================
# Bu betik, verilen öğrenci kodu, IP adresi ve servis listesi için Cloudflare
# üzerinde proxied (turuncu bulut / CDN) DNS A kayıtlarını oluşturur ve
# Zone SSL modunu "Full" yaparak self-signed origin sertifikalarını tarayıcıda
# geçerli yeşil kilitli HTTPS haline getirir.
#
# Kullanım:
#   export CLOUDFLARE_API_TOKEN="token_buraya"
#   export CLOUDFLARE_ZONE_ID="zone_id_buraya"
#
#   1. Tek Öğrenci İçin Kayıt Açma / Güncelleme:
#      ./cloudflare-dns.sh apply student01 20.12.13.11 "novashop,gitlab,harbor,sonarqube,jenkins"
#
#   2. Tek Öğrenci Kayıtlarını Silme:
#      ./cloudflare-dns.sh delete student01
#
#   3. Toplu CSV'den Yükleme (Format: student_id,ip):
#      ./cloudflare-dns.sh batch students.csv
# ==============================================================================
set -euo pipefail

DOMAIN="${DOMAIN_NAME:-devopsatolyesi.com}"
PROXIED="${CLOUDFLARE_PROXIED:-true}"

# API Parametreleri Kontrolü
if [[ -z "${CLOUDFLARE_API_TOKEN:-}" ]]; then
    read -rsp "Cloudflare API Token giriniz: " CLOUDFLARE_API_TOKEN
    echo ""
fi

if [[ -z "${CLOUDFLARE_ZONE_ID:-}" ]]; then
    read -rp "Cloudflare Zone ID giriniz: " CLOUDFLARE_ZONE_ID
fi

if [[ -z "${CLOUDFLARE_API_TOKEN:-}" || -z "${CLOUDFLARE_ZONE_ID:-}" ]]; then
    echo "❌ HATA: CLOUDFLARE_API_TOKEN ve CLOUDFLARE_ZONE_ID zorunludur!"
    exit 1
fi

API_URL="https://api.cloudflare.com/client/v4/zones/${CLOUDFLARE_ZONE_ID}/dns_records"
AUTH_HEADER=("Authorization: Bearer ${CLOUDFLARE_API_TOKEN}" "Content-Type: application/json")

ensure_full_ssl() {
    echo "===> [Cloudflare SSL] Zone SSL modu 'full' olarak ayarlanıyor..."
    local res
    res=$(curl -sS -X PATCH "https://api.cloudflare.com/client/v4/zones/${CLOUDFLARE_ZONE_ID}/settings/ssl" \
        -H "${AUTH_HEADER[0]}" -H "${AUTH_HEADER[1]}" \
        --data '{"value":"full"}')
    if echo "$res" | grep -q '"success":true'; then
        echo "✅ Cloudflare SSL modu 'Full' (Origin CA uyumlu) olarak doğrulandı."
    else
        echo "⚠️ UYARI: SSL modu güncellenemedi: $res"
    fi
}

lookup_record_id() {
    local fqdn="$1"
    curl -sS -X GET "${API_URL}?type=A&name=${fqdn}" \
        -H "${AUTH_HEADER[0]}" -H "${AUTH_HEADER[1]}" | \
        grep -o '"id":"[^"]*' | head -n 1 | cut -d'"' -f4 || true
}

upsert_dns() {
    local fqdn="$1"
    local ip="$2"
    local record_id
    record_id=$(lookup_record_id "$fqdn")

    local payload="{\"type\":\"A\",\"name\":\"${fqdn}\",\"content\":\"${ip}\",\"ttl\":1,\"proxied\":${PROXIED}}"

    if [[ -n "${record_id}" ]]; then
        echo "🔄 Güncelleniyor: ${fqdn} -> ${ip} (Proxied: ${PROXIED})"
        curl -sS -X PUT "${API_URL}/${record_id}" \
            -H "${AUTH_HEADER[0]}" -H "${AUTH_HEADER[1]}" \
            --data "${payload}" > /dev/null
    else
        echo "➕ Ekleniyor: ${fqdn} -> ${ip} (Proxied: ${PROXIED})"
        curl -sS -X POST "${API_URL}" \
            -H "${AUTH_HEADER[0]}" -H "${AUTH_HEADER[1]}" \
            --data "${payload}" > /dev/null
    fi
}

delete_dns() {
    local fqdn="$1"
    local record_id
    record_id=$(lookup_record_id "$fqdn")
    if [[ -n "${record_id}" ]]; then
        echo "🗑️ Siliniyor: ${fqdn}"
        curl -sS -X DELETE "${API_URL}/${record_id}" \
            -H "${AUTH_HEADER[0]}" -H "${AUTH_HEADER[1]}" > /dev/null
    else
        echo "ℹ️ Kayıt zaten yok: ${fqdn}"
    fi
}

ACTION="${1:-help}"

case "${ACTION}" in
    apply)
        STUDENT_ID="${2:-}"
        STUDENT_IP="${3:-}"
        SERVICES_INPUT="${4:-novashop,gitlab,harbor,sonarqube,jenkins}"

        if [[ -z "${STUDENT_ID}" || -z "${STUDENT_IP}" ]]; then
            echo "Kullanım: $0 apply <student_id> <student_ip> [servis1,servis2,...]"
            echo "Örnek   : $0 apply student01 20.12.13.11 \"novashop,gitlab,harbor,sonarqube,jenkins\""
            exit 1
        fi

        ensure_full_ssl

        IFS=',' read -ra SERVICE_LIST <<< "${SERVICES_INPUT}"
        echo ""
        echo "======================================================================"
        echo "🚀 [${STUDENT_ID}] İçin DNS Kayıtları Oluşturuluyor..."
        echo "Sunucu IP: ${STUDENT_IP}"
        echo "======================================================================"

        for svc in "${SERVICE_LIST[@]}"; do
            svc=$(echo "$svc" | tr -d '[:space:]')
            fqdn="${STUDENT_ID}-${svc}.${DOMAIN}"
            upsert_dns "${fqdn}" "${STUDENT_IP}"
        done

        echo ""
        echo "======================================================================"
        echo "🎉 İşlem Tamamlandı! Oluşturulan HTTPS URL'leri:"
        echo "======================================================================"
        for svc in "${SERVICE_LIST[@]}"; do
            svc=$(echo "$svc" | tr -d '[:space:]')
            echo "🔗 https://${STUDENT_ID}-${svc}.${DOMAIN}"
        done
        echo "======================================================================"
        ;;

    delete)
        STUDENT_ID="${2:-}"
        SERVICES_INPUT="${3:-novashop,gitlab,harbor,sonarqube,jenkins}"

        if [[ -z "${STUDENT_ID}" ]]; then
            echo "Kullanım: $0 delete <student_id> [servis1,servis2,...]"
            exit 1
        fi

        IFS=',' read -ra SERVICE_LIST <<< "${SERVICES_INPUT}"
        for svc in "${SERVICE_LIST[@]}"; do
            svc=$(echo "$svc" | tr -d '[:space:]')
            delete_dns "${STUDENT_ID}-${svc}.${DOMAIN}"
        done
        echo "✅ [${STUDENT_ID}] için DNS kayıtları silindi."
        ;;

    batch)
        CSV_FILE="${2:-}"
        SERVICES_INPUT="${3:-novashop,gitlab,harbor,sonarqube,jenkins}"

        if [[ ! -f "${CSV_FILE}" ]]; then
            echo "❌ HATA: CSV dosyası bulunamadı: ${CSV_FILE}"
            exit 1
        fi

        ensure_full_ssl

        IFS=',' read -ra SERVICE_LIST <<< "${SERVICES_INPUT}"
        while IFS=, read -r student ip || [[ -n "$student" ]]; do
            student=$(echo "$student" | tr -d '[:space:]')
            ip=$(echo "$ip" | tr -d '[:space:]')
            [[ -z "$student" || "$student" =~ ^# ]] && continue

            echo "===> İşleniyor: $student ($ip)..."
            for svc in "${SERVICE_LIST[@]}"; do
                svc=$(echo "$svc" | tr -d '[:space:]')
                upsert_dns "${student}-${svc}.${DOMAIN}" "${ip}"
            done
        done < "${CSV_FILE}"
        echo "✅ Toplu DNS kayıtları tamamlandı."
        ;;

    *)
        echo "Kullanım: $0 <apply|delete|batch>"
        echo "  apply  : Tek bir öğrenci için kayıtları oluşturur/günceller."
        echo "  delete : Bir öğrenciye ait kayıtları siler."
        echo "  batch  : CSV dosyasından toplu kayıt açar."
        exit 1
        ;;
esac
