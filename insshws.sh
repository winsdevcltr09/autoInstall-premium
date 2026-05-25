#!/bin/bash
# ================================================================
#   Installer WebSocket Tunneling (SSH over WebSocket)
#   DevCulture XII Store VPN Premium
# ================================================================

RED='\033[0;31m'
GREEN='\033[0;32m'
CYAN='\033[0;36m'
YELLOW='\033[1;33m'
NC='\033[0m'
OK="[${GREEN}  OK  ${NC}]"
ERR="[${RED} FAIL ${NC}]"
INFO="[${CYAN} INFO ${NC}]"

GITHUB_RAW="https://raw.githubusercontent.com/winsdevcltr09/autoInstall-premium/main"

cd /root

echo -e "${INFO} Install Python3 untuk WebSocket tunneling..."

# FIX: Ubuntu 22.04/24.04 tidak punya paket 'python' (Python 2),
#      wajib gunakan 'python3'. Script WS menggunakan python3.
if ! command -v python3 &>/dev/null; then
    apt-get install -y -qq python3
fi

# Pastikan python3 tersedia, buat symlink 'python' → 'python3' jika dibutuhkan
if ! command -v python &>/dev/null && command -v python3 &>/dev/null; then
    ln -sf "$(command -v python3)" /usr/local/bin/python
fi

echo -e "${OK} Python3 $(python3 --version 2>&1 | awk '{print $2}') siap"

# ── Download script WS ────────────────────────────────────────────
echo -e "${INFO} Download script WebSocket..."

wget -q --timeout=30 --tries=3 -O /usr/local/bin/ws-openssh \
    "${GITHUB_RAW}/insshws/openssh-socket.py.txt"

wget -q --timeout=30 --tries=3 -O /usr/local/bin/ws-dropbear \
    "${GITHUB_RAW}/insshws/dropbear-ws.py.txt"

wget -q --timeout=30 --tries=3 -O /usr/local/bin/ws-stunnel \
    "${GITHUB_RAW}/insshws/ws-stunnel.txt"

chmod +x /usr/local/bin/ws-openssh
chmod +x /usr/local/bin/ws-dropbear
chmod +x /usr/local/bin/ws-stunnel

# Perbarui shebang ke python3 agar kompatibel di semua OS
for f in /usr/local/bin/ws-openssh /usr/local/bin/ws-dropbear /usr/local/bin/ws-stunnel; do
    if [[ -f "$f" ]]; then
        sed -i 's|#!/usr/bin/env python$|#!/usr/bin/env python3|g' "$f"
        sed -i 's|#!/usr/bin/python$|#!/usr/bin/python3|g' "$f"
    fi
done

echo -e "${OK} Script WS berhasil didownload"

# ── Download & aktifkan service systemd ──────────────────────────
echo -e "${INFO} Install service systemd WebSocket..."

for svc in ws-openssh ws-dropbear ws-stunnel; do
    # Tentukan nama file template berdasarkan service
    case "$svc" in
        ws-openssh)  src="insshws/service-wsopenssh.txt" ;;
        ws-dropbear) src="insshws/service-wsdropbear.txt" ;;
        ws-stunnel)  src="insshws/ws-stunnel.service.txt" ;;
    esac

    wget -q --timeout=30 --tries=3 \
        -O /etc/systemd/system/${svc}.service \
        "${GITHUB_RAW}/${src}"

    chmod 644 /etc/systemd/system/${svc}.service
done

# Reload & aktifkan semua service WS
systemctl daemon-reload

for svc in ws-openssh ws-dropbear ws-stunnel; do
    systemctl enable "${svc}.service" &>/dev/null
    systemctl restart "${svc}.service" &>/dev/null
    if systemctl is-active --quiet "${svc}.service"; then
        echo -e "${OK} ${svc} aktif"
    else
        echo -e "[${YELLOW} WARN ${NC}] ${svc} tidak berjalan — cek log: journalctl -u ${svc}"
    fi
done

echo -e ""
echo -e "${OK} WebSocket SSH setup selesai"
