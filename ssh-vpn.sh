#!/bin/bash
# ================================================================
#   Script Installer SSH Multi-Port + Dropbear + Stunnel
#   DevCulture XII Store VPN Premium
# ================================================================

export DEBIAN_FRONTEND=noninteractive

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'
OK="[${GREEN}  OK  ${NC}]"
ERR="[${RED} FAIL ${NC}]"
INFO="[${CYAN} INFO ${NC}]"

MYIP=$(curl -sf --max-time 10 ipinfo.io/ip 2>/dev/null || echo "unknown")
SSHD_CONFIG="/etc/ssh/sshd_config"

# ── Informasi detail sertifikat (untuk stunnel) ──────────────────
country=ID
state=Indonesia
locality=none
organization=none
organizationalunit=TMSC
commonname=none
email=admin@devculture.id

# ── Setup rc-local ───────────────────────────────────────────────
cat > /etc/systemd/system/rc-local.service << 'EOF'
[Unit]
Description=/etc/rc.local
ConditionPathExists=/etc/rc.local

[Service]
Type=forking
ExecStart=/etc/rc.local start
TimeoutSec=0
StandardOutput=tty
RemainAfterExit=yes
SysVStartPriority=99

[Install]
WantedBy=multi-user.target
EOF

cat > /etc/rc.local << 'EOF'
#!/bin/sh -e
# rc.local — DevCulture XII Store
exit 0
EOF
chmod +x /etc/rc.local
systemctl enable rc-local &>/dev/null
systemctl start rc-local.service &>/dev/null
echo -e "${OK} rc-local dikonfigurasi"

# ── Disable IPv6 ─────────────────────────────────────────────────
echo 1 > /proc/sys/net/ipv6/conf/all/disable_ipv6
if ! grep -q "disable_ipv6" /etc/rc.local; then
    sed -i '$ i\echo 1 > /proc/sys/net/ipv6/conf/all/disable_ipv6' /etc/rc.local
fi
echo -e "${OK} IPv6 dinonaktifkan"

# ── Update & install paket dasar ─────────────────────────────────
echo -e "${INFO} Update sistem..."
apt-get update -qq
apt-get install -y -qq jq sysstat wget curl

# ── Buat direktori yang dibutuhkan ───────────────────────────────
mkdir -p /root/akun/{vmess,vless,shadowsocks,trojan}
mkdir -p /var/log/xray /var/log/trojan /home/vps/public_html
chown www-data:www-data /var/log/xray /var/log/trojan /home/vps/public_html 2>/dev/null || true
chmod 755 /var/log/xray /var/log/trojan
touch /var/log/xray/access.log /var/log/xray/error.log
touch /var/log/xray/access2.log /var/log/xray/error2.log
touch /root/log-limit.txt /root/log-reboot.txt /home/limit
echo -e "${OK} Direktori dibuat"

# ── Install Wondershaper ─────────────────────────────────────────
echo -e "${INFO} Install Wondershaper..."
apt-get install -y -qq wondershaper 2>/dev/null || true
if ! command -v wondershaper &>/dev/null; then
    git clone -q https://github.com/magnific0/wondershaper.git /tmp/wondershaper 2>/dev/null && \
    make -C /tmp/wondershaper install &>/dev/null && \
    rm -rf /tmp/wondershaper
fi
echo -e "${OK} Wondershaper siap"

# ── Konfigurasi Nginx dasar ──────────────────────────────────────
echo -e "${INFO} Install & konfigurasi Nginx..."
apt-get install -y -qq nginx
rm -f /etc/nginx/sites-enabled/default /etc/nginx/sites-available/default
if [ ! -f /etc/nginx/nginx.conf.bak ]; then
    cp /etc/nginx/nginx.conf /etc/nginx/nginx.conf.bak
fi
wget -q --timeout=30 -O /etc/nginx/nginx.conf \
    "https://raw.githubusercontent.com/winsdevcltr09/autoInstall-premium/main/nginx.conf"
mkdir -p /home/vps/public_html
systemctl restart nginx &>/dev/null || /etc/init.d/nginx restart &>/dev/null
echo -e "${OK} Nginx dikonfigurasi"

# ── Install BadVPN ───────────────────────────────────────────────
echo -e "${INFO} Install BadVPN UDP Gateway..."
wget -q --timeout=30 -O /usr/bin/badvpn-udpgw \
    "https://raw.githubusercontent.com/winsdevcltr09/autoInstall-premium/main/badvpn/badvpn-udpgw"
chmod +x /usr/bin/badvpn-udpgw

for port in 7100 7200 7300; do
    wget -q --timeout=30 -O /etc/systemd/system/svr-${port}.service \
        "https://raw.githubusercontent.com/winsdevcltr09/autoInstall-premium/main/badvpn/svr-${port}.service"
    chmod 644 /etc/systemd/system/svr-${port}.service
    systemctl daemon-reload
    systemctl enable svr-${port}.service &>/dev/null
    systemctl restart svr-${port}.service &>/dev/null
done
echo -e "${OK} BadVPN UDP Gateway (7100-7300) aktif"

# ── Konfigurasi port SSH ──────────────────────────────────────────
echo -e "${INFO} Konfigurasi port SSH..."
# FIX: tambah file target yang hilang di versi lama
sed -i 's/PasswordAuthentication no/PasswordAuthentication yes/g' "$SSHD_CONFIG"
sed -i 's/#PasswordAuthentication yes/PasswordAuthentication yes/g' "$SSHD_CONFIG"
sed -i 's/#Port 22/Port 22/g' "$SSHD_CONFIG"

# Tambah port tambahan hanya jika belum ada
for PORT in 500 200 40000 51443 58080; do
    if ! grep -q "^Port ${PORT}" "$SSHD_CONFIG"; then
        sed -i "/^Port 22/a Port ${PORT}" "$SSHD_CONFIG"
    fi
done

# Banner SSH
wget -q --timeout=30 -O /etc/issue.net \
    "https://raw.githubusercontent.com/winsdevcltr09/autoInstall-premium/main/issue.net"
if ! grep -q "^Banner" "$SSHD_CONFIG"; then
    echo "Banner /etc/issue.net" >> "$SSHD_CONFIG"
fi
# Nonaktifkan AcceptEnv agar tidak ada konflik
sed -i 's/^AcceptEnv/#AcceptEnv/g' "$SSHD_CONFIG"

/etc/init.d/ssh restart &>/dev/null || systemctl restart ssh &>/dev/null
echo -e "${OK} SSH dikonfigurasi (port: 22, 200, 500, 40000, 51443, 58080)"

# ── Install Dropbear ─────────────────────────────────────────────
echo -e "${INFO} Install Dropbear..."
apt-get install -y -qq dropbear
sed -i 's/NO_START=1/NO_START=0/g' /etc/default/dropbear
sed -i 's/DROPBEAR_PORT=22/DROPBEAR_PORT=143/g' /etc/default/dropbear

# Tambah port ekstra Dropbear — cek dulu agar tidak duplikat
if ! grep -q '\-p 109' /etc/default/dropbear; then
    sed -i 's/DROPBEAR_EXTRA_ARGS=.*/DROPBEAR_EXTRA_ARGS="-p 50000 -p 109 -p 110 -p 69"/' /etc/default/dropbear
fi

# Tambah shell nologin jika belum ada
grep -qxF '/bin/false' /etc/shells || echo '/bin/false' >> /etc/shells
grep -qxF '/usr/sbin/nologin' /etc/shells || echo '/usr/sbin/nologin' >> /etc/shells

# Update banner Dropbear
sed -i 's|DROPBEAR_BANNER="".*|DROPBEAR_BANNER="/etc/issue.net"|' /etc/default/dropbear

/etc/init.d/dropbear restart &>/dev/null || systemctl restart dropbear &>/dev/null
echo -e "${OK} Dropbear aktif (port: 143, 109, 110, 50000)"

# ── Install Stunnel4 ─────────────────────────────────────────────
echo -e "${INFO} Install Stunnel4..."
apt-get install -y -qq stunnel4

cat > /etc/stunnel/stunnel.conf << 'EOF'
cert = /etc/stunnel/stunnel.pem
client = no
socket = a:SO_REUSEADDR=1
socket = l:TCP_NODELAY=1
socket = r:TCP_NODELAY=1

[dropbear-222]
accept = 222
connect = 127.0.0.1:22

[dropbear-777]
accept = 777
connect = 127.0.0.1:109

[ws-stunnel]
accept = 2096
connect = 127.0.0.1:700

[openvpn]
accept = 442
connect = 127.0.0.1:1194
EOF

# Generate sertifikat stunnel
cd /tmp
openssl genrsa -out key.pem 2048 2>/dev/null
openssl req -new -x509 -key key.pem -out cert.pem -days 1095 \
  -subj "/C=${country}/ST=${state}/L=${locality}/O=${organization}/OU=${organizationalunit}/CN=${commonname}/emailAddress=${email}" 2>/dev/null
cat key.pem cert.pem > /etc/stunnel/stunnel.pem
rm -f key.pem cert.pem
cd /root

sed -i 's/ENABLED=0/ENABLED=1/g' /etc/default/stunnel4
/etc/init.d/stunnel4 restart &>/dev/null || systemctl restart stunnel4 &>/dev/null
echo -e "${OK} Stunnel4 aktif (port: 222, 777, 442, 2096)"

# ── Install Fail2Ban ─────────────────────────────────────────────
apt-get install -y -qq fail2ban
/etc/init.d/fail2ban restart &>/dev/null || systemctl restart fail2ban &>/dev/null
echo -e "${OK} Fail2Ban aktif"

# ── Blokir torrent via iptables ──────────────────────────────────
echo -e "${INFO} Konfigurasi iptables (blokir torrent)..."
TORRENT_STRINGS=("get_peers" "announce_peer" "find_node" "BitTorrent" "BitTorrent protocol"
                  "peer_id=" ".torrent" "announce.php?passkey=" "torrent" "announce" "info_hash")
for str in "${TORRENT_STRINGS[@]}"; do
    iptables -C FORWARD -m string --string "$str" --algo bm -j DROP 2>/dev/null || \
    iptables -A FORWARD -m string --string "$str" --algo bm -j DROP 2>/dev/null
done
iptables-save > /etc/iptables.up.rules 2>/dev/null
netfilter-persistent save &>/dev/null || true
echo -e "${OK} Blokir torrent aktif"

# ── Install vnstat ───────────────────────────────────────────────
apt-get install -y -qq vnstat
/etc/init.d/vnstat restart &>/dev/null || systemctl restart vnstat &>/dev/null
echo -e "${OK} vnstat aktif"

# ── Bersihkan cache apt ──────────────────────────────────────────
apt-get autoclean -y -qq &>/dev/null

echo -e "${OK} SSH & Services setup selesai"
rm -f /root/ssh-vpn.sh
