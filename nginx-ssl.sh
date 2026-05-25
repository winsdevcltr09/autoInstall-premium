#!/bin/bash
# ================================================================
#   Script Install Nginx + SSL (acme.sh / Let's Encrypt)
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

echo -e ""
date
echo ""

# Ambil domain dari file yang sudah dibuat setupku.sh
domain=$(cat /root/domain 2>/dev/null || cat /etc/xray/domain 2>/dev/null)
if [[ -z "$domain" ]]; then
    echo -e "${ERR} Domain tidak ditemukan! Pastikan setupku.sh sudah dijalankan dulu."
    exit 1
fi

mkdir -p /etc/xray /home/vps/public_html
echo -e "${INFO} Domain: ${GREEN}${domain}${NC}"

# ── Sinkronisasi waktu ────────────────────────────────────────────
echo -e "${INFO} Sinkronisasi waktu..."
apt-get install -y -qq iptables iptables-persistent 2>/dev/null
apt-get install -y -qq curl socat xz-utils wget apt-transport-https \
    gnupg gnupg2 gnupg1 dnsutils lsb-release chrony ntpdate zip 2>/dev/null
ntpdate -u pool.ntp.org &>/dev/null || true
timedatectl set-ntp true &>/dev/null || true
systemctl enable chrony &>/dev/null && systemctl restart chrony &>/dev/null
timedatectl set-timezone Asia/Jakarta &>/dev/null
echo -e "${OK} Waktu disinkronisasi (Asia/Jakarta)"

# ── Generate SSL dengan acme.sh ──────────────────────────────────
echo -e "${INFO} Generate sertifikat SSL untuk domain: ${domain}..."

# Hentikan nginx & xray sementara agar port 80 bebas
systemctl stop nginx &>/dev/null || true
systemctl stop xray &>/dev/null || true

# Cek jika ada proses lain yang pakai port 80
PORT80_PROC=$(lsof -i:80 2>/dev/null | awk 'NR==2{print $1}')
if [[ -n "$PORT80_PROC" ]]; then
    echo -e "${WARN} Port 80 dipakai oleh: ${PORT80_PROC} — dihentikan sementara"
    systemctl stop "$PORT80_PROC" &>/dev/null || true
fi

# Install acme.sh jika belum ada
if [[ ! -f /root/.acme.sh/acme.sh ]]; then
    mkdir -p /root/.acme.sh
    curl -sf https://acme-install.netlify.app/acme.sh -o /root/.acme.sh/acme.sh
    chmod +x /root/.acme.sh/acme.sh
fi

/root/.acme.sh/acme.sh --upgrade --auto-upgrade
/root/.acme.sh/acme.sh --set-default-ca --server letsencrypt

# Issue sertifikat
/root/.acme.sh/acme.sh --issue -d "$domain" --standalone -k ec-256
if [[ $? -ne 0 ]]; then
    echo -e "${ERR} Gagal generate SSL untuk ${domain}!"
    echo -e "${WARN} Pastikan:"
    echo -e "       1. Domain sudah pointing ke IP VPS ini"
    echo -e "       2. Port 80 tidak diblokir provider"
    echo -e "       3. Tunggu propagasi DNS 5-10 menit, lalu jalankan: genssl"
else
    ~/.acme.sh/acme.sh --installcert -d "$domain" \
        --fullchainpath /etc/xray/xray.crt \
        --keypath /etc/xray/xray.key --ecc
    chmod 644 /etc/xray/xray.crt /etc/xray/xray.key
    echo -e "${OK} Sertifikat SSL berhasil digenerate"
fi

# ── Setup auto-renew SSL via cron ────────────────────────────────
cat > /usr/local/bin/ssl_renew.sh << 'RENEWEOF'
#!/bin/bash
/etc/init.d/nginx stop 2>/dev/null || systemctl stop nginx 2>/dev/null
"/root/.acme.sh/acme.sh" --cron --home "/root/.acme.sh" > /root/renew_ssl.log 2>&1
/etc/init.d/nginx start 2>/dev/null || systemctl start nginx 2>/dev/null
RENEWEOF
chmod +x /usr/local/bin/ssl_renew.sh

# Tambah cron renew jika belum ada
if ! grep -q 'ssl_renew.sh' /var/spool/cron/crontabs/root 2>/dev/null; then
    (crontab -l 2>/dev/null; echo "15 03 */3 * * /usr/local/bin/ssl_renew.sh") | crontab -
fi
echo -e "${OK} Auto-renew SSL dikonfigurasi"

# ── Konfigurasi Nginx untuk Xray ─────────────────────────────────
echo -e "${INFO} Menulis konfigurasi Nginx..."

cat > /etc/nginx/conf.d/xray.conf << NGINXEOF
server {
    listen 80;
    listen [::]:80;
    listen 443 ssl http2 reuseport;
    listen [::]:443 ssl http2 reuseport;
    server_name ${domain};

    ssl_certificate     /etc/xray/xray.crt;
    ssl_certificate_key /etc/xray/xray.key;
    ssl_ciphers         EECDH+CHACHA20:EECDH+CHACHA20-draft:EECDH+ECDSA+AES128:EECDH+aRSA+AES128:RSA+AES128:EECDH+ECDSA+AES256:EECDH+aRSA+AES256:RSA+AES256:!MD5;
    ssl_protocols       TLSv1.2 TLSv1.3;

    root /home/vps/public_html;

    location / {
        if (\$http_upgrade != "Upgrade") {
            rewrite /(.*) /vmess break;
        }
        proxy_redirect off;
        proxy_pass http://127.0.0.1:11825;
        proxy_http_version 1.1;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection "upgrade";
        proxy_set_header Host \$http_host;
    }

    location = /vmess {
        proxy_redirect off;
        proxy_pass http://127.0.0.1:11825;
        proxy_http_version 1.1;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection "upgrade";
        proxy_set_header Host \$http_host;
    }

    location = /vless {
        proxy_redirect off;
        proxy_pass http://127.0.0.1:12877;
        proxy_http_version 1.1;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection "upgrade";
        proxy_set_header Host \$http_host;
    }

    location = /trojan-ws {
        proxy_redirect off;
        proxy_pass http://127.0.0.1:23591;
        proxy_http_version 1.1;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection "upgrade";
        proxy_set_header Host \$http_host;
    }

    location = /ss-ws {
        proxy_redirect off;
        proxy_pass http://127.0.0.1:23083;
        proxy_http_version 1.1;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection "upgrade";
        proxy_set_header Host \$http_host;
    }

    location ^~ /vless-grpc {
        grpc_set_header X-Real-IP \$remote_addr;
        grpc_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        grpc_set_header Host \$http_host;
        grpc_pass grpc://127.0.0.1:40568;
    }

    location ^~ /vmess-grpc {
        grpc_set_header X-Real-IP \$remote_addr;
        grpc_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        grpc_set_header Host \$http_host;
        grpc_pass grpc://127.0.0.1:12206;
    }

    location ^~ /trojan-grpc {
        grpc_set_header X-Real-IP \$remote_addr;
        grpc_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        grpc_set_header Host \$http_host;
        grpc_pass grpc://127.0.0.1:34872;
    }

    location ^~ /ss-grpc {
        grpc_set_header X-Real-IP \$remote_addr;
        grpc_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        grpc_set_header Host \$http_host;
        grpc_pass grpc://127.0.0.1:34834;
    }
}
NGINXEOF

echo -e "${OK} Konfigurasi Nginx ditulis"

# ── Start ulang layanan ───────────────────────────────────────────
echo -e "${INFO} Menyimpan domain & memulai ulang layanan..."
echo "$domain" > /etc/xray/domain
echo "$domain" > /root/domain

# FIX: Perbaiki typo 'daemin-reload' → daemon-reload
# FIX: Hapus 'systemctl enable runn' (service tidak ada)
systemctl daemon-reload
systemctl enable nginx &>/dev/null
systemctl restart nginx
systemctl enable xray &>/dev/null
systemctl restart xray &>/dev/null || true

echo -e "${OK} Nginx & Xray direstart"

# Pindahkan domain ke lokasi xray
if [[ -f /root/domain ]]; then
    mv /root/domain /etc/xray/domain 2>/dev/null || true
fi
rm -f /root/scdomain 2>/dev/null || true

echo -e ""
echo -e "${OK} ${GREEN}nginx-ssl.sh selesai tanpa error${NC}"
rm -f /root/nginx-ssl.sh
