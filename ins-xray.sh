#!/bin/bash
# ================================================================
#   Installer Xray Core — VMess / VLESS / Trojan / Shadowsocks
#   DevCulture XII Store VPN Premium
# ================================================================

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'
OK="[${GREEN}  OK  ${NC}]"
ERR="[${RED} FAIL ${NC}]"
INFO="[${CYAN} INFO ${NC}]"
WARN="[${YELLOW} WARN ${NC}]"

GITHUB_RAW="https://raw.githubusercontent.com/winsdevcltr09/autoInstall-premium/main"
export DEBIAN_FRONTEND=noninteractive

# Ambil domain
domain=$(cat /etc/xray/domain 2>/dev/null || cat /root/domain 2>/dev/null)
if [[ -z "$domain" ]]; then
    echo -e "${ERR} Domain tidak ditemukan! Jalankan setupku.sh terlebih dahulu."
    exit 1
fi

echo -e "${INFO} Domain aktif: ${GREEN}${domain}${NC}"

# Simpan domain di semua lokasi yang dibutuhkan
mkdir -p /etc/xray /etc/v2ray /var/lib/scrz-prem
echo "$domain" > /etc/xray/domain
echo "$domain" > /etc/v2ray/domain
echo "IP=$domain" > /var/lib/scrz-prem/ipvps.conf

# ── Buat direktori log ─────────────────────────────────────────────
mkdir -p /var/log/xray /home/vps/public_html
touch /var/log/xray/access.log /var/log/xray/error.log
chown www-data:www-data /var/log/xray 2>/dev/null || true
echo -e "${OK} Direktori Xray siap"

# ── Install dependensi ─────────────────────────────────────────────
echo -e "${INFO} Install dependensi Xray..."
apt-get install -y -qq curl wget socat xz-utils zip openssl \
    apt-transport-https gnupg dnsutils lsb-release jq 2>/dev/null
echo -e "${OK} Dependensi terinstall"

# ── Sinkronisasi waktu ─────────────────────────────────────────────
ntpdate -u pool.ntp.org &>/dev/null || true
timedatectl set-timezone Asia/Jakarta &>/dev/null

# ── Download config.json dari repo sendiri ─────────────────────────
# FIX: Sebelumnya mengambil dari repo pihak ketiga 'Agunxzzz/XrayCol'
#      Sekarang diambil dari repo resmi winsdevcltr09/autoInstall-premium
echo -e "${INFO} Download konfigurasi Xray..."
wget -q --timeout=30 --tries=3 \
    -O /etc/nginx/conf.d/vps.conf \
    "${GITHUB_RAW}/conf/vps.conf" 2>/dev/null || true

wget -q --timeout=30 --tries=3 \
    -O /etc/xray/config.json \
    "${GITHUB_RAW}/conf/config.json"

if [[ ! -s /etc/xray/config.json ]]; then
    echo -e "${ERR} Gagal download config.json!"
    exit 1
fi
chmod 644 /etc/xray/config.json
echo -e "${OK} config.json berhasil didownload"

# ── Install Xray Core via xray-install resmi ──────────────────────
echo -e "${INFO} Install Xray Core..."
bash -c "$(curl -L https://github.com/XTLS/Xray-install/raw/main/install-release.sh)" @ install
if [[ $? -ne 0 ]]; then
    echo -e "${WARN} Xray-install gagal, mencoba cara alternatif..."
    # Alternatif: download langsung dari release GitHub
    XRAY_VER=$(curl -sf "https://api.github.com/repos/XTLS/Xray-core/releases/latest" \
        | grep '"tag_name"' | cut -d'"' -f4)
    [[ -z "$XRAY_VER" ]] && XRAY_VER="v1.8.23"
    wget -q --timeout=60 \
        -O /tmp/xray.zip \
        "https://github.com/XTLS/Xray-core/releases/download/${XRAY_VER}/Xray-linux-64.zip"
    unzip -q -o /tmp/xray.zip -d /tmp/xray-bin/
    install -m 755 /tmp/xray-bin/xray /usr/local/bin/xray
    rm -rf /tmp/xray.zip /tmp/xray-bin/
fi
echo -e "${OK} Xray Core terinstall: $(/usr/local/bin/xray version 2>/dev/null | head -1)"

# ── Buat service systemd Xray ──────────────────────────────────────
cat > /etc/systemd/system/xray.service << 'EOF'
[Unit]
Description=Xray Service
Documentation=https://github.com/xtls
After=network.target nss-lookup.target

[Service]
User=www-data
CapabilityBoundingSet=CAP_NET_ADMIN CAP_NET_BIND_SERVICE
AmbientCapabilities=CAP_NET_ADMIN CAP_NET_BIND_SERVICE
NoNewPrivileges=true
ExecStart=/usr/local/bin/xray run -config /etc/xray/config.json
Restart=on-failure
RestartPreventExitStatus=23
LimitNPROC=10000
LimitNOFILE=1000000

[Install]
WantedBy=multi-user.target
EOF

# ── Download xray.conf Nginx dari repo sendiri ─────────────────────
wget -q --timeout=30 --tries=3 \
    -O /etc/nginx/conf.d/xray.conf \
    "${GITHUB_RAW}/conf/xray.conf"

# Ganti domain placeholder jika ada
sed -i "s/hoka.jateng.tech/${domain}/g" /etc/nginx/conf.d/xray.conf 2>/dev/null

echo -e "${OK} Konfigurasi Nginx-Xray ditulis"

# ── Aktifkan & start Xray ──────────────────────────────────────────
systemctl daemon-reload
systemctl enable xray &>/dev/null
systemctl start xray
systemctl restart xray

# Verifikasi
sleep 2
if systemctl is-active --quiet xray; then
    echo -e "${OK} Xray berjalan normal"
else
    echo -e "${WARN} Xray tidak aktif — cek log: journalctl -u xray -n 50"
fi

# Restart Nginx setelah Xray siap
systemctl restart nginx &>/dev/null

echo -e "${OK} Xray Core setup selesai"
rm -f /root/ins-xray.sh
