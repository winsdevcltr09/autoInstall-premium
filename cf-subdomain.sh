#!/bin/bash
# ================================================================
#   CF Auto Subdomain — DevCulture XII Store VPN Premium
#   Fitur  : Auto create/update DNS A Record di Cloudflare
#   Domain : florezha.eu.org
#   GitHub : github.com/winsdevcltr09/autoInstall-premium
# ================================================================

set -euo pipefail

# ── Warna & Status ───────────────────────────────────────────────
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
# Kredensial disimpan di /etc/xray/cf.conf (dibuat saat setup pertama)
# Format cf.conf:
#   CF_DOMAIN="florezha.eu.org"
#   CF_EMAIL="email@example.com"
#   CF_TOKEN="cfut_xxxxxxxxxxxx"
CF_CONF="/etc/xray/cf.conf"

# Default config (dapat di-override oleh cf.conf)
CF_DOMAIN="florezha.eu.org"
CF_EMAIL=""
CF_TOKEN=""

# Load config jika sudah ada
if [[ -f "$CF_CONF" ]]; then
    # shellcheck source=/dev/null
    source "$CF_CONF"
fi

# ── Banner ────────────────────────────────────────────────────────
clear
echo -e "${PURPLE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "     ${WHITE}${BOLD}   CF AUTO SUBDOMAIN — DevCulture Elite${NC}"
echo -e "     ${CYAN}   Auto DNS A Record via Cloudflare API${NC}"
echo -e "${PURPLE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e ""

# ── Root check ────────────────────────────────────────────────────
if [[ "${EUID}" -ne 0 ]]; then
    echo -e "${ERR} Jalankan script ini sebagai root!"
    echo -e "     Ketik: ${YELLOW}sudo -i${NC} lalu jalankan ulang."
    exit 1
fi

# ── Setup config jika belum ada ───────────────────────────────────
setup_config() {
    echo -e "${WARN} File konfigurasi Cloudflare belum ditemukan."
    echo -e "${INFO} Setup kredensial Cloudflare (tersimpan di ${CF_CONF})"
    echo -e ""

    read -rp "  CF Domain (contoh: florezha.eu.org) : " INPUT_DOMAIN
    read -rp "  CF Email                             : " INPUT_EMAIL
    read -rp "  CF API Token (cfut_...)              : " INPUT_TOKEN

    if [[ -z "$INPUT_DOMAIN" || -z "$INPUT_EMAIL" || -z "$INPUT_TOKEN" ]]; then
        echo -e "${ERR} Semua field wajib diisi."
        exit 1
    fi

    mkdir -p "$(dirname "$CF_CONF")"
    cat > "$CF_CONF" << EOF
# Cloudflare Config — DevCulture Elite
# File ini dibuat otomatis oleh cf-subdomain
CF_DOMAIN="${INPUT_DOMAIN}"
CF_EMAIL="${INPUT_EMAIL}"
CF_TOKEN="${INPUT_TOKEN}"
EOF
    chmod 600 "$CF_CONF"

    CF_DOMAIN="$INPUT_DOMAIN"
    CF_EMAIL="$INPUT_EMAIL"
    CF_TOKEN="$INPUT_TOKEN"

    echo -e "${OK} Konfigurasi disimpan di ${CF_CONF}"
    echo -e ""
}

if [[ -z "$CF_TOKEN" || -z "$CF_EMAIL" ]]; then
    setup_config
fi

echo -e "  ${INFO} Domain  : ${GREEN}${CF_DOMAIN}${NC}"
echo -e ""

# ── Fungsi: check & install deps ─────────────────────────────────
check_deps() {
    local missing=()
    for cmd in curl jq; do
        command -v "$cmd" &>/dev/null || missing+=("$cmd")
    done
    if [[ ${#missing[@]} -gt 0 ]]; then
        echo -e "${INFO} Install dependency yang kurang: ${missing[*]}"
        apt-get install -y -q "${missing[@]}" 2>/dev/null || {
            echo -e "${ERR} Gagal install dependency. Jalankan: apt-get install -y ${missing[*]}"
            exit 1
        }
        echo -e "${OK} Dependency berhasil diinstall"
    fi
}

# ── Fungsi: validasi subdomain ────────────────────────────────────
validate_subdomain() {
    local sub="${1,,}"

    local blacklist=("sg" "hk" "id" "us" "uk" "jp" "vn" "de" "fr" "in" "my" "th")
    for b in "${blacklist[@]}"; do
        if [[ "$sub" == "$b" ]]; then
            echo -e "${ERR} Subdomain '${sub}' tidak diizinkan. Gunakan nama yang lebih unik." >&2
            exit 1
        fi
    done

    if [[ ${#sub} -lt 4 ]]; then
        echo -e "${ERR} Subdomain terlalu pendek. Minimal 4 karakter (misal: vpn01, resa11)." >&2
        exit 1
    fi

    if ! [[ "$sub" =~ ^[a-z0-9-]+$ ]]; then
        echo -e "${ERR} Subdomain hanya boleh berisi huruf kecil (a-z), angka (0-9), dan dash (-)." >&2
        exit 1
    fi

    if [[ "$sub" == -* || "$sub" == *- ]]; then
        echo -e "${ERR} Subdomain tidak boleh diawali atau diakhiri dengan tanda dash (-)." >&2
        exit 1
    fi

    echo "$sub"
}

# ── Fungsi: ambil IP publik VPS ───────────────────────────────────
get_vps_ip() {
    local ip=""
    ip=$(curl -sf --max-time 8 https://ipinfo.io/ip 2>/dev/null) ||
    ip=$(curl -sf --max-time 8 https://ifconfig.me 2>/dev/null) ||
    ip=$(wget -qO- --timeout=8 https://ipv4.icanhazip.com 2>/dev/null) || true

    if [[ -z "$ip" ]]; then
        echo -e "${ERR} Tidak bisa mendeteksi IP publik VPS. Cek koneksi internet." >&2
        exit 1
    fi
    echo "$ip"
}

# ── Fungsi: Cloudflare API call ───────────────────────────────────
cf_api() {
    local method="$1"
    local endpoint="$2"
    local data="${3:-}"
    local response=""

    if [[ -n "$data" ]]; then
        response=$(curl -sf --max-time 20 -X "$method" \
            "https://api.cloudflare.com/client/v4/${endpoint}" \
            -H "Authorization: Bearer ${CF_TOKEN}" \
            -H "Content-Type: application/json" \
            -d "$data" 2>/dev/null) || true
    else
        response=$(curl -sf --max-time 20 -X "$method" \
            "https://api.cloudflare.com/client/v4/${endpoint}" \
            -H "Authorization: Bearer ${CF_TOKEN}" \
            -H "Content-Type: application/json" 2>/dev/null) || true
    fi

    if [[ -z "$response" ]]; then
        echo -e "${ERR} Tidak ada response dari Cloudflare API." >&2
        echo -e "${ERR} Kemungkinan: koneksi internet bermasalah / API timeout." >&2
        exit 1
    fi

    local success
    success=$(echo "$response" | jq -r '.success' 2>/dev/null || echo "false")
    if [[ "$success" != "true" ]]; then
        local err_msg
        err_msg=$(echo "$response" | jq -r '.errors[0].message // "Unknown error"' 2>/dev/null)
        echo -e "${ERR} Cloudflare API gagal: ${err_msg}" >&2
        echo -e "${ERR} Cek: CF_TOKEN valid, domain terdaftar di akun Cloudflare." >&2
        exit 1
    fi

    echo "$response"
}

# ── Check deps ────────────────────────────────────────────────────
echo -e "${INFO} Memeriksa dependencies..."
check_deps
echo -e "${OK} curl dan jq tersedia"
echo -e ""

# ── Input subdomain ───────────────────────────────────────────────
echo -e "${YELLOW}  Panduan input subdomain:${NC}"
echo -e "  • Minimal 4 karakter"
echo -e "  • Hanya huruf kecil (a-z), angka (0-9), dan dash (-)"
echo -e "  • Contoh: ${GREEN}resa11${NC} | ${GREEN}server01${NC} | ${GREEN}vpn-sg01${NC}"
echo -e "  • Hindari nama singkat: sg, hk, id, us (ditolak)"
echo -e ""
echo -e "  Format: ${CYAN}<subdomain>${NC}.${CF_DOMAIN}"
echo -e ""
read -rp "  Masukkan nama subdomain : " INPUT_SUB

if [[ -z "${INPUT_SUB:-}" ]]; then
    echo -e "${ERR} Input kosong. Dibatalkan."
    exit 1
fi

# ── Validasi ──────────────────────────────────────────────────────
echo -e ""
echo -e "${INFO} Memvalidasi input subdomain..."
SUB=$(validate_subdomain "$INPUT_SUB")
SUB_DOMAIN="${SUB}.${CF_DOMAIN}"
echo -e "${OK} Subdomain valid: ${GREEN}${SUB_DOMAIN}${NC}"

# ── Deteksi IP VPS ────────────────────────────────────────────────
echo -e "${INFO} Mendeteksi IP publik VPS..."
VPS_IP=$(get_vps_ip)
echo -e "${OK} IP VPS: ${GREEN}${VPS_IP}${NC}"

# ── Ambil Zone ID ─────────────────────────────────────────────────
echo -e "${INFO} Menghubungkan ke Cloudflare API..."
ZONE_RESP=$(cf_api "GET" "zones?name=${CF_DOMAIN}&status=active")
ZONE_ID=$(echo "$ZONE_RESP" | jq -r '.result[0].id // empty')

if [[ -z "$ZONE_ID" || "$ZONE_ID" == "null" ]]; then
    echo -e "${ERR} Zone '${CF_DOMAIN}' tidak ditemukan di akun Cloudflare."
    echo -e "${ERR} Pastikan domain sudah ditambahkan ke akun Cloudflare."
    exit 1
fi
echo -e "${OK} Zone ID ditemukan"

# ── Cek record existing ───────────────────────────────────────────
echo -e "${INFO} Mengecek record DNS yang sudah ada..."
RECORD_RESP=$(cf_api "GET" "zones/${ZONE_ID}/dns_records?type=A&name=${SUB_DOMAIN}")
RECORD_ID=$(echo "$RECORD_RESP" | jq -r '.result[0].id // empty')

if [[ -n "$RECORD_ID" && "$RECORD_ID" != "null" ]]; then
    EXISTING_IP=$(echo "$RECORD_RESP" | jq -r '.result[0].content // ""')
    echo -e "${WARN} Record ${SUB_DOMAIN} sudah ada (IP: ${EXISTING_IP})"
    echo -e "${INFO} Mengupdate ke IP VPS baru: ${VPS_IP}..."

    UPDATE_DATA=$(jq -n \
        --arg name "$SUB_DOMAIN" \
        --arg ip "$VPS_IP" \
        '{"type":"A","name":$name,"content":$ip,"ttl":120,"proxied":false}')
    cf_api "PUT" "zones/${ZONE_ID}/dns_records/${RECORD_ID}" "$UPDATE_DATA" > /dev/null
    echo -e "${OK} DNS A Record berhasil di-UPDATE"
    ACTION="diupdate"
else
    echo -e "${INFO} Membuat DNS A Record baru..."
    CREATE_DATA=$(jq -n \
        --arg name "$SUB_DOMAIN" \
        --arg ip "$VPS_IP" \
        '{"type":"A","name":$name,"content":$ip,"ttl":120,"proxied":false}')
    CREATE_RESP=$(cf_api "POST" "zones/${ZONE_ID}/dns_records" "$CREATE_DATA")
    RECORD_ID=$(echo "$CREATE_RESP" | jq -r '.result.id // ""')
    echo -e "${OK} DNS A Record berhasil DIBUAT (ID: ${RECORD_ID})"
    ACTION="dibuat"
fi

# ── Simpan domain ke path existing installer ──────────────────────
echo -e "${INFO} Menyimpan domain ke konfigurasi VPS..."
mkdir -p /etc/xray /etc/v2ray /var/lib/scrz-prem

echo "$SUB_DOMAIN" > /root/domain
echo "$SUB_DOMAIN" > /root/scdomain
echo "$SUB_DOMAIN" > /etc/xray/domain
echo "$SUB_DOMAIN" > /etc/xray/scdomain
echo "$SUB_DOMAIN" > /etc/v2ray/domain
echo "$SUB_DOMAIN" > /etc/v2ray/scdomain
echo "IP=$SUB_DOMAIN" > /var/lib/scrz-prem/ipvps.conf

echo -e "${OK} Domain disimpan ke semua path konfigurasi"

# ── Summary ───────────────────────────────────────────────────────
echo -e ""
echo -e "${PURPLE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "     ${WHITE}${BOLD}   SUBDOMAIN BERHASIL ${ACTION^^}${NC}"
echo -e "${PURPLE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e ""
echo -e "  ${CYAN}Subdomain${NC}   : ${GREEN}${SUB_DOMAIN}${NC}"
echo -e "  ${CYAN}IP VPS     ${NC} : ${GREEN}${VPS_IP}${NC}"
echo -e "  ${CYAN}TTL        ${NC} : 120 detik"
echo -e "  ${CYAN}Proxy Mode ${NC} : OFF (DNS Only — siap untuk SSL)"
echo -e "  ${CYAN}Status     ${NC} : ${GREEN}AKTIF${NC}"
echo -e ""
echo -e "  ${WARN} DNS propagasi butuh waktu 1–5 menit."
echo -e ""
echo -e "  ${INFO} Domain tersimpan di:"
echo -e "        /root/domain  •  /etc/xray/domain  •  /etc/v2ray/domain"
echo -e ""
echo -e "${PURPLE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e ""
read -n 1 -s -r -p "  Tekan tombol apapun untuk lanjut ke SSL setup..."
echo ""
genssl
