#!/bin/bash
# ================================================================
#   Tools Installer - DevCulture XII Store VPN Premium
#   Install semua dependensi yang dibutuhkan
# ================================================================
clear
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'
OK="[${GREEN}  OK  ${NC}]"
ERR="[${RED} FAIL ${NC}]"
INFO="[${CYAN} INFO ${NC}]"

export DEBIAN_FRONTEND=noninteractive

# Deteksi OS
if [[ -f /etc/os-release ]]; then
    . /etc/os-release
    OS_NAME=$ID
    OS_VERSION=$VERSION_ID
else
    echo -e "${ERR} Tidak bisa mendeteksi OS"
    exit 1
fi

# Deteksi network interface
NET=$(ip route show default 2>/dev/null | awk '{print $5}' | head -1)
[[ -z "$NET" ]] && NET=$(ls /sys/class/net | grep -v lo | head -1)

echo -e "${INFO} OS: ${OS_NAME} ${OS_VERSION} | Interface: ${NET}"
echo -e "${INFO} Memulai instalasi dependensi..."
sleep 1

# Update repositori
echo -e "${INFO} Update repository..."
apt-get update -qq 2>/dev/null
echo -e "${OK} Repository diperbarui"

# Hapus paket konflik
echo -e "${INFO} Menghapus paket konflik..."
apt-get remove --purge -y ufw firewalld exim4 apache2 &>/dev/null
echo -e "${OK} Paket konflik dihapus"

# Install dependensi utama
echo -e "${INFO} Menginstall dependensi utama..."
apt-get install -y \
    screen curl jq bzip2 gzip coreutils rsyslog iftop \
    htop zip unzip net-tools sed gnupg gnupg1 gnupg2 \
    bc apt-transport-https build-essential dirmngr git lsof \
    openssl fail2ban tmux stunnel4 \
    dropbear libsqlite3-dev \
    socat cron bash-completion ntpdate xz-utils \
    dnsutils lsb-release chrony ca-certificates \
    libnss3-dev libnspr4-dev pkg-config libpam0g-dev \
    libcap-ng-dev libcap-ng-utils libselinux1-dev \
    libcurl4-nss-dev flex bison make libnss3-tools \
    libevent-dev libxml-parser-perl -qq 2>/dev/null
echo -e "${OK} Dependensi utama terinstall"

# squid (nama berbeda di Debian 11+)
echo -e "${INFO} Menginstall squid..."
if apt-get install -y squid3 -qq &>/dev/null; then
    echo -e "${OK} Squid3 terinstall"
elif apt-get install -y squid -qq &>/dev/null; then
    echo -e "${OK} Squid terinstall"
else
    echo -e "${ERR} Squid gagal (tidak kritikal, lanjut...)"
fi

# xl2tpd & pptpd (opsional)
apt-get install -y xl2tpd pptpd &>/dev/null && echo -e "${OK} xl2tpd & pptpd terinstall" || echo -e "${INFO} xl2tpd/pptpd tidak tersedia (opsional)"

# Node.js 18.x
echo -e "${INFO} Menginstall Node.js 18.x..."
if ! command -v node &>/dev/null || [[ "$(node -v | cut -d. -f1 | tr -d 'v')" -lt 16 ]]; then
    curl -fsSL https://deb.nodesource.com/setup_18.x | bash - &>/dev/null
    apt-get install -y nodejs -qq &>/dev/null
fi
echo -e "${OK} Node.js $(node -v 2>/dev/null) terinstall"

# vnstat - install dari repo (lebih stabil)
echo -e "${INFO} Menginstall vnstat..."
if apt-get install -y vnstat -qq &>/dev/null; then
    # Konfigurasi interface
    if [[ -n "$NET" ]]; then
        sed -i "s/Interface \"eth0\"/Interface \"${NET}\"/g" /etc/vnstat.conf 2>/dev/null || true
        vnstat -i "$NET" --add &>/dev/null || true
    fi
    chown vnstat:vnstat /var/lib/vnstat -R &>/dev/null || true
    systemctl enable vnstat &>/dev/null
    systemctl restart vnstat &>/dev/null
    echo -e "${OK} vnstat terinstall & dikonfigurasi (interface: ${NET})"
else
    echo -e "${ERR} vnstat gagal diinstall"
fi

echo ""
echo -e "${OK} Semua dependensi berhasil diinstall!"
sleep 2
clear
