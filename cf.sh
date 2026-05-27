#!/bin/bash
# ================================================================
#   cf.sh — Cloudflare Dynamic DNS Updater
#   DevCulture XII Store VPN Premium
#   Fungsi : Update DNS record ke IP VPS saat ini (otomatis)
#   Domain : florezha.eu.org
#   Ref    : github.com/winsdevcltr09/autoInstall-premium
# ================================================================
#
#   Untuk setup subdomain interaktif, gunakan:
#     cf-subdomain
#
# ================================================================

set -euo pipefail

# ── Warna ─────────────────────────────────────────────────────────
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
PURPLE='\033[0;35m'
WHITE='\033[1;37m'
NC='\033[0m'
BOLD='\033[1m'

OK="[${GREEN}  OK  ${NC}]"
ERR="[${RED} FAIL ${NC}]"
INFO="[${CYAN} INFO ${NC}]"
WARN="[${YELLOW} WARN ${NC}]"

# ── Centralized Config ────────────────────────────────────────────
# Kredensial dibaca dari /etc/xray/cf.conf
# Gunakan cf-subdomain untuk setup config pertama kali
CF_CONF="/etc/xray/cf.conf"
CF_DOMAIN="florezha.eu.org"
CF_EMAIL=""
CF_TOKEN=""

if [[ -f "$CF_CONF" ]]; then
    # shellcheck source=/dev/null
    source "$CF_CONF"
fi

if [[ -z "$CF_TOKEN" || -z "$CF_EMAIL" ]]; then
    echo -e "${ERR} Konfigurasi Cloudflare belum tersedia."
    echo -e "${INFO} Jalankan: ${CYAN}cf-subdomain${NC} untuk setup pertama kali."
    exit 1
fi

# ── Baca domain dari konfigurasi VPS ─────────────────────────────
CURRENT_DOMAIN=""
[[ -f /root/domain ]] && CURRENT_DOMAIN=$(cat /root/domain)

# ── Banner ────────────────────────────────────────────────────────
clear
echo -e "${PURPLE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "     ${WHITE}${BOLD}   CF DNS UPDATER — DevCulture Elite${NC}"
echo -e "     ${CYAN}   Update otomatis DNS A Record ke IP VPS saat ini${NC}"
echo -e "${PURPLE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e ""

# ── Deteksi IP publik VPS ─────────────────────────────────────────
echo -e "${INFO} Mendeteksi IP publik VPS..."
VPS_IP=""
VPS_IP=$(curl -sf --max-time 8 https://ipinfo.io/ip 2>/dev/null) ||
VPS_IP=$(curl -sf --max-time 8 https://ifconfig.me 2>/dev/null) ||
VPS_IP=$(wget -qO- --timeout=8 https://ipv4.icanhazip.com 2>/dev/null) || true

if [[ -z "$VPS_IP" ]]; then
    echo -e "${ERR} Tidak bisa mendeteksi IP publik VPS."
    exit 1
fi
echo -e "${OK} IP VPS: ${GREEN}${VPS_IP}${NC}"

# ── Tentukan subdomain yang akan diupdate ─────────────────────────
if [[ -n "$CURRENT_DOMAIN" && "$CURRENT_DOMAIN" == *"${CF_DOMAIN}"* ]]; then
    TARGET_DOMAIN="$CURRENT_DOMAIN"
    echo -e "${INFO} Domain aktif: ${GREEN}${TARGET_DOMAIN}${NC}"
else
    echo -e "${WARN} Tidak ada domain aktif di /root/domain."
    echo -e "${INFO} Gunakan ${CYAN}cf-subdomain${NC} untuk membuat subdomain baru."
    echo -e ""
    read -rp "  Input subdomain (contoh: resa11): " INPUT_SUB
    if [[ -z "${INPUT_SUB:-}" ]]; then
        echo -e "${ERR} Input kosong. Dibatalkan."
        exit 1
    fi
    TARGET_DOMAIN="${INPUT_SUB}.${CF_DOMAIN}"
fi

echo -e "${INFO} Target DNS: ${GREEN}${TARGET_DOMAIN}${NC} → ${GREEN}${VPS_IP}${NC}"

# ── Install deps jika belum ada ───────────────────────────────────
for cmd in curl jq; do
    command -v "$cmd" &>/dev/null || apt-get install -y -q "$cmd" 2>/dev/null
done

# ── Get Zone ID ───────────────────────────────────────────────────
echo -e "${INFO} Menghubungkan ke Cloudflare API..."
ZONE_RESP=$(curl -sf --max-time 20 -X GET \
    "https://api.cloudflare.com/client/v4/zones?name=${CF_DOMAIN}&status=active" \
    -H "Authorization: Bearer ${CF_TOKEN}" \
    -H "Content-Type: application/json" 2>/dev/null) || {
    echo -e "${ERR} Cloudflare API tidak bisa dihubungi."
    exit 1
}

ZONE_ID=$(echo "$ZONE_RESP" | jq -r '.result[0].id // empty')
if [[ -z "$ZONE_ID" || "$ZONE_ID" == "null" ]]; then
    echo -e "${ERR} Zone '${CF_DOMAIN}' tidak ditemukan."
    exit 1
fi
echo -e "${OK} Zone ID ditemukan"

# ── Get/Create Record ─────────────────────────────────────────────
RECORD_RESP=$(curl -sf --max-time 20 -X GET \
    "https://api.cloudflare.com/client/v4/zones/${ZONE_ID}/dns_records?type=A&name=${TARGET_DOMAIN}" \
    -H "Authorization: Bearer ${CF_TOKEN}" \
    -H "Content-Type: application/json" 2>/dev/null)

RECORD_ID=$(echo "$RECORD_RESP" | jq -r '.result[0].id // empty')

if [[ -z "$RECORD_ID" || "$RECORD_ID" == "null" ]]; then
    echo -e "${INFO} Record belum ada. Membuat baru..."
    curl -sf --max-time 20 -X POST \
        "https://api.cloudflare.com/client/v4/zones/${ZONE_ID}/dns_records" \
        -H "Authorization: Bearer ${CF_TOKEN}" \
        -H "Content-Type: application/json" \
        -d "{\"type\":\"A\",\"name\":\"${TARGET_DOMAIN}\",\"content\":\"${VPS_IP}\",\"ttl\":120,\"proxied\":false}" > /dev/null
else
    # ── Update Record ─────────────────────────────────────────────
    curl -sf --max-time 20 -X PUT \
        "https://api.cloudflare.com/client/v4/zones/${ZONE_ID}/dns_records/${RECORD_ID}" \
        -H "Authorization: Bearer ${CF_TOKEN}" \
        -H "Content-Type: application/json" \
        -d "{\"type\":\"A\",\"name\":\"${TARGET_DOMAIN}\",\"content\":\"${VPS_IP}\",\"ttl\":120,\"proxied\":false}" > /dev/null
fi

echo -e ""
echo -e "${OK} DNS record berhasil diupdate!"
echo -e ""
echo -e "  ${CYAN}Domain${NC} : ${GREEN}${TARGET_DOMAIN}${NC}"
echo -e "  ${CYAN}IP     ${NC} : ${GREEN}${VPS_IP}${NC}"
echo -e ""
echo -e "${PURPLE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e ""
