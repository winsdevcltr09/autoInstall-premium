#!/bin/bash
# ================================================================
#   genssl.sh — Renew/Generate SSL Certificate
#   DevCulture XII Store VPN Premium
# ================================================================

# ── Color Definitions ────────────────────────────────────────────
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

OK="[${GREEN}  OK  ${NC}]"
ERR="[${RED} FAIL ${NC}]"
INFO="[${CYAN} INFO ${NC}]"
WARN="[${YELLOW} WARN ${NC}]"

clear

# ── Baca domain dari konfigurasi ─────────────────────────────────
domain=""
if [[ -f /var/lib/scrz-prem/ipvps.conf ]]; then
    domain=$(grep "^IP=" /var/lib/scrz-prem/ipvps.conf | cut -d'=' -f2)
fi
if [[ -z "$domain" ]]; then
    domain=$(cat /etc/xray/domain 2>/dev/null)
fi
if [[ -z "$domain" ]]; then
    domain=$(cat /root/domain 2>/dev/null)
fi

if [[ -z "$domain" ]]; then
    echo -e "${ERR} Domain tidak ditemukan!"
    echo -e "     Jalankan: ${CYAN}addhost${NC} untuk mengatur domain terlebih dahulu."
    exit 1
fi

echo -e "${INFO} Domain: ${GREEN}${domain}${NC}"

# ── Hentikan layanan yang menggunakan port 80 ─────────────────────
systemctl stop nginx &>/dev/null || true
systemctl stop xray &>/dev/null || true

Cek=$(lsof -i:80 2>/dev/null | awk 'NR==2 {print $1}')
if [[ -n "$Cek" ]]; then
    sleep 1
    echo -e "${WARN} Detected port 80 used by ${RED}${Cek}${NC}"
    systemctl stop "$Cek" &>/dev/null || true
    sleep 2
    echo -e "${INFO} Processing to stop ${Cek}"
    sleep 1
fi

echo -e "${INFO} Starting renew gen-ssl..."
sleep 2

# ── Upgrade acme.sh ───────────────────────────────────────────────
if [[ ! -f /root/.acme.sh/acme.sh ]]; then
    echo -e "${INFO} Download acme.sh..."
    curl -sf https://acme-install.netlify.app/acme.sh -o /root/.acme.sh/acme.sh 2>/dev/null || \
    curl -sf https://get.acme.sh | bash -s email=admin@example.com 2>/dev/null
fi

/root/.acme.sh/acme.sh --upgrade --auto-upgrade 2>/dev/null
/root/.acme.sh/acme.sh --set-default-ca --server letsencrypt

# ── Generate/Renew sertifikat ─────────────────────────────────────
/root/.acme.sh/acme.sh --issue -d "$domain" --standalone -k ec-256
if [[ $? -ne 0 ]]; then
    echo -e "${ERR} Gagal generate SSL untuk ${RED}${domain}${NC}!"
    echo -e "${WARN} Pastikan:"
    echo -e "       1. Domain sudah pointing ke IP VPS ini"
    echo -e "       2. Port 80 tidak diblokir provider"
    echo -e "       3. Tunggu propagasi DNS 5-10 menit, lalu jalankan ulang: ${CYAN}genssl${NC}"
else
    ~/.acme.sh/acme.sh --installcert -d "$domain" \
        --fullchainpath /etc/xray/xray.crt \
        --keypath /etc/xray/xray.key --ecc
    chmod 644 /etc/xray/xray.crt /etc/xray/xray.key
    echo -e "${OK} Sertifikat SSL berhasil di-renew"
fi

# ── Simpan domain kembali dan start ulang service ─────────────────
echo "$domain" > /etc/xray/domain
echo "$domain" > /etc/v2ray/domain 2>/dev/null || true
echo "IP=$domain" > /var/lib/scrz-prem/ipvps.conf

echo -e "${INFO} Memulai ulang layanan..."
systemctl daemon-reload
systemctl start nginx &>/dev/null || true
systemctl start xray &>/dev/null || true

echo -e "${OK} All finished"
sleep 0.5
echo ""
read -n 1 -s -r -p "Press any key to back on menu"
menu
