#!/bin/bash
# ================================================================
#   addhost.sh — Ganti Domain VPS (End-to-End Automated)
#   DevCulture XII Store VPN Premium
#   Flow  : Input → Validasi → DNS CF → Update Config → SSL → Restart
#   Kompatibel : Ubuntu 20/22/24 | Debian 11/12
#   Update ke  : /usr/bin/addhost (via update.sh)
# ================================================================

# ── Warna & Status ───────────────────────────────────────────────
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'
PURPLE='\033[0;35m'
NC='\033[0m'
BOLD='\033[1m'

OK="[${GREEN}  OK  ${NC}]"
ERR="[${RED} FAIL ${NC}]"
INFO="[${CYAN} INFO ${NC}]"
WARN="[${YELLOW} WARN ${NC}]"
STEP="[${PURPLE} >>> ${NC}]"

# ── Konstanta ─────────────────────────────────────────────────────
CF_CONF="/etc/xray/cf.conf"
DOMAIN_CONF="/etc/xray/domain.conf"
NGINX_XRAY_CONF="/etc/nginx/conf.d/xray.conf"
DOMAIN_OWNER_BASE="florezha.eu.org"

# ── Root check ────────────────────────────────────────────────────
if [[ $EUID -ne 0 ]]; then
    echo -e "${ERR} Script harus dijalankan sebagai root!"
    exit 1
fi

# ─────────────────────────────────────────────────────────────────
# FUNGSI: Baca domain aktif dari semua sumber yang mungkin
# ─────────────────────────────────────────────────────────────────
read_current_domain() {
    local d=""
    [[ -f /etc/xray/domain ]] && d=$(cat /etc/xray/domain 2>/dev/null | tr -d '[:space:]')
    if [[ -z "$d" ]]; then
        [[ -f /var/lib/scrz-prem/ipvps.conf ]] && \
            d=$(grep "^IP=" /var/lib/scrz-prem/ipvps.conf 2>/dev/null | cut -d'=' -f2 | tr -d '[:space:]')
    fi
    if [[ -z "$d" ]]; then
        [[ -f /root/domain ]] && d=$(cat /root/domain 2>/dev/null | tr -d '[:space:]')
    fi
    echo "$d"
}

# ─────────────────────────────────────────────────────────────────
# FUNGSI: Validasi format FQDN (domain lengkap)
# ─────────────────────────────────────────────────────────────────
validate_domain() {
    local domain="$1"
    [[ -z "$domain" ]] && return 1
    [[ ${#domain} -gt 253 ]] && return 1
    # Harus ada minimal 1 titik, setiap label maks 63 char
    if [[ ! "$domain" =~ ^[a-zA-Z0-9]([a-zA-Z0-9\-]{0,61}[a-zA-Z0-9])?(\.[a-zA-Z0-9]([a-zA-Z0-9\-]{0,61}[a-zA-Z0-9])?)*\.[a-zA-Z]{2,}$ ]]; then
        return 1
    fi
    return 0
}

# ─────────────────────────────────────────────────────────────────
# FUNGSI: Validasi format subdomain
# ─────────────────────────────────────────────────────────────────
validate_subdomain() {
    local sub="$1"
    [[ -z "$sub" || ${#sub} -lt 1 ]] && return 1
    [[ ${#sub} -gt 63 ]] && return 1
    # Hanya lowercase, angka, dash — tidak boleh mulai/akhiri dengan dash
    if [[ ! "$sub" =~ ^[a-z0-9]([a-z0-9-]*[a-z0-9])?$ && ! "$sub" =~ ^[a-z0-9]$ ]]; then
        return 1
    fi
    return 0
}

# ─────────────────────────────────────────────────────────────────
# FUNGSI: Input domain dari user (Dual Mode)
# ─────────────────────────────────────────────────────────────────
input_domain() {
    clear
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "    ${WHITE}${BOLD}   GANTI DOMAIN — DevCulture XII Store Premium${NC}"
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

    local current_domain
    current_domain=$(read_current_domain)
    if [[ -n "$current_domain" ]]; then
        echo -e "\n  ${INFO} Domain aktif saat ini : ${YELLOW}${current_domain}${NC}\n"
    else
        echo -e "\n  ${WARN} Belum ada domain terkonfigurasi.\n"
    fi

    echo -e "  Pilih mode domain:\n"
    echo -e "    ${CYAN}[1]${NC} ${WHITE}Domain Owner${NC}  → subdomain.${DOMAIN_OWNER_BASE}"
    echo -e "    ${CYAN}[2]${NC} ${WHITE}Domain Pribadi${NC} → subdomain.domain-anda.com\n"
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

    local mode
    while true; do
        read -rp "  Pilihan [1/2]: " mode
        case "$mode" in
            1|2) break ;;
            *) echo -e "  ${WARN} Masukkan 1 atau 2" ;;
        esac
    done

    local new_domain domain_base subdomain

    if [[ "$mode" == "1" ]]; then
        # ── Mode 1: Domain Owner ──────────────────────────────────
        domain_base="$DOMAIN_OWNER_BASE"
        echo ""
        echo -e "  ${INFO} Mode: ${WHITE}Domain Owner${NC} (${domain_base})"
        echo ""
        while true; do
            read -rp "  Masukkan subdomain (contoh: sg1, hk01, us02): " subdomain
            subdomain=$(echo "$subdomain" | tr '[:upper:]' '[:lower:]' | tr -d ' ')
            if validate_subdomain "$subdomain"; then
                new_domain="${subdomain}.${domain_base}"
                echo -e "\n  ${INFO} Domain yang akan digunakan: ${GREEN}${new_domain}${NC}"
                break
            else
                echo -e "  ${ERR} Subdomain tidak valid."
                echo -e "       Gunakan: huruf kecil, angka, dan dash (-)"
                echo -e "       Tidak boleh diawali/diakhiri dengan dash."
            fi
        done

    else
        # ── Mode 2: Domain Pribadi ────────────────────────────────
        echo ""
        echo -e "  ${INFO} Mode: ${WHITE}Domain Pribadi${NC}"
        echo ""
        while true; do
            read -rp "  Masukkan base domain (contoh: myvpn.com): " domain_base
            domain_base=$(echo "$domain_base" | tr '[:upper:]' '[:lower:]' | tr -d ' ')
            if validate_domain "$domain_base"; then
                break
            else
                echo -e "  ${ERR} Format domain tidak valid."
                echo -e "       Contoh: myvpn.com / vpn.example.net"
            fi
        done
        while true; do
            read -rp "  Masukkan subdomain (contoh: sg1, vps01): " subdomain
            subdomain=$(echo "$subdomain" | tr '[:upper:]' '[:lower:]' | tr -d ' ')
            if validate_subdomain "$subdomain"; then
                new_domain="${subdomain}.${domain_base}"
                echo -e "\n  ${INFO} Domain yang akan digunakan: ${GREEN}${new_domain}${NC}"
                break
            else
                echo -e "  ${ERR} Subdomain tidak valid."
                echo -e "       Gunakan: huruf kecil, angka, dan dash (-)"
            fi
        done

        echo ""
        echo -e "  ${WARN} ${YELLOW}PERHATIAN — Domain Pribadi:${NC}"
        echo -e "    Pastikan DNS A Record ${WHITE}${new_domain}${NC}"
        echo -e "    sudah pointing ke IP VPS ini SEBELUM melanjutkan."
        echo -e "    SSL akan gagal jika DNS belum propagasi (5-15 menit)."
    fi

    echo ""
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

    # Konfirmasi sebelum lanjut
    if [[ -n "$current_domain" && "$new_domain" == "$current_domain" ]]; then
        echo -e "\n  ${WARN} Domain sama dengan yang aktif (${current_domain})."
        echo -e "  Proses akan regenerate SSL dan restart service.\n"
        read -rp "  Lanjutkan? [y/N]: " confirm
    else
        echo ""
        read -rp "  Konfirmasi ganti domain ke ${GREEN}${new_domain}${NC}? [y/N]: " confirm
    fi

    if [[ ! "$confirm" =~ ^[Yy]$ ]]; then
        echo -e "\n  ${INFO} Dibatalkan oleh user."
        exit 0
    fi

    # Export ke variabel global
    NEW_DOMAIN="$new_domain"
    DOMAIN_MODE="$mode"
    SUBDOMAIN="$subdomain"
    DOMAIN_BASE="$domain_base"
}

# ─────────────────────────────────────────────────────────────────
# FUNGSI: Update DNS Cloudflare (hanya Mode 1 - Domain Owner)
# ─────────────────────────────────────────────────────────────────
update_cf_dns() {
    local domain="$1"
    local subdomain="$2"

    echo -e "\n${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${STEP} Update DNS Cloudflare..."

    if [[ ! -f "$CF_CONF" ]]; then
        echo -e "  ${WARN} File CF credentials tidak ditemukan: ${CF_CONF}"
        echo -e "        Jalankan ${CYAN}cf-subdomain${NC} untuk setup Cloudflare terlebih dahulu."
        echo -e "  ${INFO} Lewati update DNS Cloudflare..."
        CF_DNS_STATUS="skip"
        return 0
    fi

    local CF_EMAIL CF_TOKEN CF_ZONE_ID
    CF_EMAIL=$(grep "^CF_EMAIL=" "$CF_CONF" 2>/dev/null | cut -d'=' -f2 | tr -d '"')
    CF_TOKEN=$(grep "^CF_TOKEN=" "$CF_CONF" 2>/dev/null | cut -d'=' -f2 | tr -d '"')
    CF_ZONE_ID=$(grep "^CF_ZONE_ID=" "$CF_CONF" 2>/dev/null | cut -d'=' -f2 | tr -d '"')

    if [[ -z "$CF_EMAIL" || -z "$CF_TOKEN" || -z "$CF_ZONE_ID" ]]; then
        echo -e "  ${WARN} Data CF credentials tidak lengkap di ${CF_CONF}."
        echo -e "        Jalankan ${CYAN}cf-subdomain${NC} untuk setup ulang."
        echo -e "  ${INFO} Lewati update DNS Cloudflare..."
        CF_DNS_STATUS="skip"
        return 0
    fi

    # Ambil IP publik VPS
    local VPS_IP
    VPS_IP=$(curl -sf --max-time 10 https://ipv4.icanhazip.com 2>/dev/null | tr -d '[:space:]')
    if [[ -z "$VPS_IP" ]]; then
        VPS_IP=$(curl -sf --max-time 10 https://api.ipify.org 2>/dev/null | tr -d '[:space:]')
    fi
    if [[ -z "$VPS_IP" ]]; then
        echo -e "  ${WARN} Tidak bisa deteksi IP VPS. Lewati update DNS..."
        CF_DNS_STATUS="skip"
        return 0
    fi
    echo -e "  ${INFO} IP VPS   : ${WHITE}${VPS_IP}${NC}"
    echo -e "  ${INFO} Domain   : ${WHITE}${domain}${NC}"

    # Cek apakah record sudah ada
    local EXISTING_ID
    EXISTING_ID=$(curl -sf --max-time 20 \
        -H "X-Auth-Email: ${CF_EMAIL}" \
        -H "X-Auth-Key: ${CF_TOKEN}" \
        -H "Content-Type: application/json" \
        "https://api.cloudflare.com/client/v4/zones/${CF_ZONE_ID}/dns_records?type=A&name=${domain}" \
        2>/dev/null | python3 -c "
import sys, json
try:
    d = json.load(sys.stdin)
    r = d.get('result', [])
    print(r[0]['id'] if r else '')
except:
    print('')
" 2>/dev/null || true)

    local CF_RESP CF_SUCCESS
    if [[ -n "$EXISTING_ID" ]]; then
        # Update record yang sudah ada
        CF_RESP=$(curl -sf --max-time 20 -X PUT \
            -H "X-Auth-Email: ${CF_EMAIL}" \
            -H "X-Auth-Key: ${CF_TOKEN}" \
            -H "Content-Type: application/json" \
            "https://api.cloudflare.com/client/v4/zones/${CF_ZONE_ID}/dns_records/${EXISTING_ID}" \
            --data "{\"type\":\"A\",\"name\":\"${subdomain}\",\"content\":\"${VPS_IP}\",\"ttl\":120,\"proxied\":false}" \
            2>/dev/null || true)
        echo -e "  ${INFO} Mode     : Update record yang sudah ada"
    else
        # Buat record baru
        CF_RESP=$(curl -sf --max-time 20 -X POST \
            -H "X-Auth-Email: ${CF_EMAIL}" \
            -H "X-Auth-Key: ${CF_TOKEN}" \
            -H "Content-Type: application/json" \
            "https://api.cloudflare.com/client/v4/zones/${CF_ZONE_ID}/dns_records" \
            --data "{\"type\":\"A\",\"name\":\"${subdomain}\",\"content\":\"${VPS_IP}\",\"ttl\":120,\"proxied\":false}" \
            2>/dev/null || true)
        echo -e "  ${INFO} Mode     : Buat record baru"
    fi

    CF_SUCCESS=$(echo "$CF_RESP" | python3 -c "
import sys, json
try:
    d = json.load(sys.stdin)
    print('yes' if d.get('success') else 'no')
except:
    print('unknown')
" 2>/dev/null || echo "unknown")

    if [[ "$CF_SUCCESS" == "yes" ]]; then
        echo -e "  ${OK} DNS Cloudflare berhasil: ${WHITE}${domain}${NC} → ${VPS_IP}"
        CF_DNS_STATUS="ok"
    else
        local CF_ERR
        CF_ERR=$(echo "$CF_RESP" | python3 -c "
import sys, json
try:
    d = json.load(sys.stdin)
    errs = d.get('errors', [])
    print(errs[0].get('message','') if errs else 'unknown error')
except:
    print('unknown error')
" 2>/dev/null || echo "unknown error")
        echo -e "  ${WARN} Cloudflare API error: ${CF_ERR}"
        echo -e "        Update config dilanjutkan secara manual..."
        CF_DNS_STATUS="fail"
    fi
}

# ─────────────────────────────────────────────────────────────────
# FUNGSI: Update SEMUA file domain (7 lokasi + domain.conf)
# ─────────────────────────────────────────────────────────────────
update_domain_files() {
    local new_domain="$1"
    local mode="$2"
    local subdomain="$3"
    local domain_base="$4"

    echo -e "\n${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${STEP} Update file konfigurasi domain (7 lokasi)..."

    mkdir -p /etc/xray /etc/v2ray /var/lib/scrz-prem

    # 1. /etc/xray/domain — dibaca oleh add-ws, add-vless, add-tr, dll
    echo "$new_domain" > /etc/xray/domain
    echo -e "  ${OK} /etc/xray/domain"

    # 2. /etc/v2ray/domain — kompatibilitas backward
    echo "$new_domain" > /etc/v2ray/domain
    echo -e "  ${OK} /etc/v2ray/domain"

    # 3. /etc/xray/scdomain — secondary domain pointer
    echo "$new_domain" > /etc/xray/scdomain
    echo -e "  ${OK} /etc/xray/scdomain"

    # 4. /etc/v2ray/scdomain
    echo "$new_domain" > /etc/v2ray/scdomain
    echo -e "  ${OK} /etc/v2ray/scdomain"

    # 5. /root/domain — dibaca nginx-ssl.sh, cf-subdomain.sh
    echo "$new_domain" > /root/domain
    echo -e "  ${OK} /root/domain"

    # 6. /root/scdomain
    echo "$new_domain" > /root/scdomain
    echo -e "  ${OK} /root/scdomain"

    # 7. /var/lib/scrz-prem/ipvps.conf — format IP=domain
    echo "IP=${new_domain}" > /var/lib/scrz-prem/ipvps.conf
    echo -e "  ${OK} /var/lib/scrz-prem/ipvps.conf"

    # 8. /etc/xray/domain.conf — structured config (backward compatible, new addition)
    cat > "$DOMAIN_CONF" << DOMAINEOF
DOMAIN_OWNER="${DOMAIN_OWNER_BASE}"
DOMAIN_MODE="${mode}"
SUBDOMAIN="${subdomain}"
DOMAIN_BASE="${domain_base}"
FULL_DOMAIN="${new_domain}"
DOMAINEOF
    echo -e "  ${OK} /etc/xray/domain.conf"

    echo -e "  ${OK} ${GREEN}Semua file domain berhasil diperbarui${NC}"
}

# ─────────────────────────────────────────────────────────────────
# FUNGSI: Regenerate nginx config lengkap
# ─────────────────────────────────────────────────────────────────
regenerate_nginx_config() {
    local domain="$1"

    cat > "$NGINX_XRAY_CONF" << NGINXEOF
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
    echo -e "  ${OK} Nginx config digenerate ulang untuk: ${domain}"
}

# ─────────────────────────────────────────────────────────────────
# FUNGSI: Update nginx config domain (sed atau regenerate)
# ─────────────────────────────────────────────────────────────────
update_nginx_config() {
    local old_domain="$1"
    local new_domain="$2"

    echo -e "\n${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${STEP} Update konfigurasi Nginx..."

    # Buat direktori nginx conf.d jika belum ada
    mkdir -p /etc/nginx/conf.d

    if [[ ! -f "$NGINX_XRAY_CONF" ]]; then
        echo -e "  ${WARN} ${NGINX_XRAY_CONF} tidak ditemukan — generate dari template..."
        regenerate_nginx_config "$new_domain"
        return
    fi

    # Backup nginx config sebelum diubah
    local BACKUP_FILE="${NGINX_XRAY_CONF}.bak.$(date +%Y%m%d%H%M%S)"
    cp "$NGINX_XRAY_CONF" "$BACKUP_FILE"
    echo -e "  ${INFO} Backup dibuat: ${BACKUP_FILE}"

    # Cek apakah old_domain ada di dalam file
    if [[ -n "$old_domain" ]] && grep -qF "$old_domain" "$NGINX_XRAY_CONF" 2>/dev/null; then
        # Replace domain lama → domain baru di seluruh file
        sed -i "s|${old_domain}|${new_domain}|g" "$NGINX_XRAY_CONF"
        echo -e "  ${OK} Nginx server_name: ${YELLOW}${old_domain}${NC} → ${GREEN}${new_domain}${NC}"
    else
        # Tidak ditemukan domain lama — replace server_name line langsung
        if grep -q "server_name" "$NGINX_XRAY_CONF" 2>/dev/null; then
            sed -i "s|server_name .*;|server_name ${new_domain};|g" "$NGINX_XRAY_CONF"
            echo -e "  ${OK} Nginx server_name diperbarui ke: ${GREEN}${new_domain}${NC}"
        else
            # File ada tapi tidak punya server_name — regenerate
            echo -e "  ${WARN} Format nginx config tidak dikenali — regenerate..."
            regenerate_nginx_config "$new_domain"
        fi
    fi

    echo -e "  ${OK} Konfigurasi Nginx selesai diperbarui"
}

# ─────────────────────────────────────────────────────────────────
# FUNGSI: Generate / Issue SSL Certificate via acme.sh
# ─────────────────────────────────────────────────────────────────
renew_ssl() {
    local domain="$1"

    echo -e "\n${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${STEP} Generate SSL Certificate untuk: ${WHITE}${domain}${NC}"

    # Stop nginx & xray agar port 80 bebas
    systemctl stop nginx 2>/dev/null || true
    systemctl stop xray 2>/dev/null || true
    sleep 1

    # Cek & hentikan proses lain yang pakai port 80
    local PORT80_PROC
    PORT80_PROC=$(lsof -i:80 2>/dev/null | awk 'NR==2{print $1}' | head -1 || true)
    if [[ -n "$PORT80_PROC" ]]; then
        echo -e "  ${WARN} Port 80 dipakai oleh: ${PORT80_PROC} — dihentikan sementara"
        systemctl stop "$PORT80_PROC" 2>/dev/null || true
        sleep 2
    fi

    # Install acme.sh jika belum ada
    if [[ ! -f /root/.acme.sh/acme.sh ]]; then
        echo -e "  ${INFO} Install acme.sh..."
        mkdir -p /root/.acme.sh
        curl -sf --max-time 60 https://acme-install.netlify.app/acme.sh \
            -o /root/.acme.sh/acme.sh 2>/dev/null || true
        if [[ ! -f /root/.acme.sh/acme.sh ]]; then
            curl -sf --max-time 60 \
                "https://raw.githubusercontent.com/acmesh-official/acme.sh/master/acme.sh" \
                -o /root/.acme.sh/acme.sh 2>/dev/null || true
        fi
        chmod +x /root/.acme.sh/acme.sh 2>/dev/null || true
    fi

    /root/.acme.sh/acme.sh --upgrade --auto-upgrade 2>/dev/null || true
    /root/.acme.sh/acme.sh --set-default-ca --server letsencrypt 2>/dev/null || true

    echo -e "  ${INFO} Memulai issue sertifikat (standalone mode)..."

    # Issue SSL — paksa issue ulang untuk domain ini
    if /root/.acme.sh/acme.sh --issue -d "$domain" --standalone -k ec-256 --force 2>&1 | \
            grep -v "^$" | sed 's/^/          /'; then
        # Install cert ke path yang dipakai xray & nginx
        /root/.acme.sh/acme.sh --installcert -d "$domain" \
            --fullchainpath /etc/xray/xray.crt \
            --keypath /etc/xray/xray.key --ecc 2>/dev/null
        chmod 644 /etc/xray/xray.crt /etc/xray/xray.key 2>/dev/null || true
        echo -e "  ${OK} ${GREEN}SSL Certificate berhasil digenerate${NC}"

        # Setup / perbarui cron auto-renew SSL
        if [[ ! -f /usr/local/bin/ssl_renew.sh ]]; then
            cat > /usr/local/bin/ssl_renew.sh << 'RENEWEOF'
#!/bin/bash
domain=$(cat /etc/xray/domain 2>/dev/null)
systemctl stop nginx 2>/dev/null || true
/root/.acme.sh/acme.sh --cron --home /root/.acme.sh > /root/renew_ssl.log 2>&1
if [[ -n "$domain" ]]; then
    /root/.acme.sh/acme.sh --installcert -d "$domain" \
        --fullchainpath /etc/xray/xray.crt \
        --keypath /etc/xray/xray.key --ecc 2>/dev/null
fi
systemctl start nginx 2>/dev/null || true
RENEWEOF
            chmod +x /usr/local/bin/ssl_renew.sh
        fi
        if ! crontab -l 2>/dev/null | grep -q 'ssl_renew.sh'; then
            (crontab -l 2>/dev/null; echo "15 03 */3 * * /usr/local/bin/ssl_renew.sh") | crontab -
        fi
        return 0
    else
        echo ""
        echo -e "  ${ERR} ${RED}Gagal generate SSL untuk ${domain}!${NC}"
        echo ""
        echo -e "  ${WARN} Kemungkinan penyebab:"
        echo -e "        1. DNS belum propagasi (tunggu 5-15 menit)"
        echo -e "        2. Port 80 diblokir oleh provider VPS"
        echo -e "        3. Domain belum pointing ke IP VPS ini"
        echo -e "        4. Rate limit Let's Encrypt (terlalu sering issue)"
        echo ""
        echo -e "  ${INFO} Setelah DNS propagasi, jalankan: ${CYAN}genssl${NC}"
        return 1
    fi
}

# ─────────────────────────────────────────────────────────────────
# FUNGSI: Validasi konfigurasi sebelum restart
# ─────────────────────────────────────────────────────────────────
validate_config() {
    echo -e "\n${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${STEP} Validasi konfigurasi..."

    local ALL_OK=true

    # Nginx syntax test
    if command -v nginx &>/dev/null; then
        local NGINX_TEST
        NGINX_TEST=$(nginx -t 2>&1)
        if echo "$NGINX_TEST" | grep -q "syntax is ok"; then
            echo -e "  ${OK} nginx -t: konfigurasi valid"
        else
            echo -e "  ${ERR} nginx -t: ada kesalahan konfigurasi!"
            echo "$NGINX_TEST" | sed 's/^/          /'
            ALL_OK=false
        fi
    else
        echo -e "  ${WARN} nginx tidak ditemukan, skip validasi nginx"
    fi

    # Cek SSL cert
    if [[ -f /etc/xray/xray.crt && -s /etc/xray/xray.crt ]]; then
        local EXPIRY CN
        EXPIRY=$(openssl x509 -enddate -noout -in /etc/xray/xray.crt 2>/dev/null | cut -d'=' -f2 || echo "unknown")
        CN=$(openssl x509 -subject -noout -in /etc/xray/xray.crt 2>/dev/null | \
             grep -oP 'CN\s*=\s*\K[^,/]+' | head -1 || echo "unknown")
        echo -e "  ${OK} SSL cert: CN=${CN}, expired=${EXPIRY}"
    else
        echo -e "  ${WARN} SSL cert tidak ditemukan atau kosong (/etc/xray/xray.crt)"
    fi

    # Cek xray config.json
    if [[ -f /etc/xray/config.json ]]; then
        if python3 -c "import json,sys; json.load(open('/etc/xray/config.json'))" 2>/dev/null; then
            echo -e "  ${OK} Xray config.json: valid JSON"
        else
            echo -e "  ${WARN} Xray config.json mungkin rusak — cek manual"
        fi
    fi

    # Cek nginx xray.conf server_name
    if [[ -f "$NGINX_XRAY_CONF" ]]; then
        local SN
        SN=$(grep "server_name" "$NGINX_XRAY_CONF" 2>/dev/null | awk '{print $2}' | tr -d ';' | head -1)
        echo -e "  ${INFO} Nginx server_name: ${WHITE}${SN:-tidak ditemukan}${NC}"
    fi

    # Cek domain file
    if [[ -f /etc/xray/domain ]]; then
        local DOM
        DOM=$(cat /etc/xray/domain)
        echo -e "  ${INFO} Domain aktif: ${WHITE}${DOM}${NC}"
    fi

    if $ALL_OK; then
        echo -e "  ${OK} ${GREEN}Semua validasi berhasil${NC}"
        return 0
    else
        echo -e "  ${WARN} Ada kesalahan ditemukan — restart mungkin gagal"
        return 1
    fi
}

# ─────────────────────────────────────────────────────────────────
# FUNGSI: Restart services dengan aman
# ─────────────────────────────────────────────────────────────────
restart_services() {
    echo -e "\n${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${STEP} Restart layanan..."

    systemctl daemon-reload 2>/dev/null || true

    # Nginx — hanya restart jika config valid
    if command -v nginx &>/dev/null; then
        if nginx -t 2>/dev/null; then
            if systemctl restart nginx 2>/dev/null; then
                echo -e "  ${OK} nginx berhasil direstart"
            else
                echo -e "  ${WARN} nginx gagal restart — coba start..."
                systemctl start nginx 2>/dev/null && \
                    echo -e "  ${OK} nginx berhasil distart" || \
                    echo -e "  ${ERR} nginx gagal start"
            fi
        else
            echo -e "  ${ERR} nginx config invalid — skip restart nginx"
            echo -e "        Perbaiki: nginx -t untuk lihat error"
        fi
    fi

    # Xray
    if systemctl restart xray 2>/dev/null; then
        echo -e "  ${OK} xray berhasil direstart"
    else
        echo -e "  ${WARN} xray gagal restart"
    fi

    # Services tambahan — hanya jika sudah aktif
    for svc in ssh dropbear stunnel4; do
        if systemctl is-active --quiet "$svc" 2>/dev/null; then
            systemctl restart "$svc" 2>/dev/null && \
                echo -e "  ${OK} ${svc} direstart" || \
                echo -e "  ${WARN} ${svc} gagal restart"
        fi
    done

    sleep 2

    # Verifikasi status layanan
    echo ""
    echo -e "  ${INFO} Status layanan setelah restart:"
    for svc in nginx xray; do
        if systemctl is-active --quiet "$svc" 2>/dev/null; then
            echo -e "    ${OK} ${WHITE}${svc}${NC}: aktif"
        else
            echo -e "    ${WARN} ${WHITE}${svc}${NC}: tidak aktif"
        fi
    done
}

# ─────────────────────────────────────────────────────────────────
# FUNGSI: Tampilkan ringkasan hasil akhir
# ─────────────────────────────────────────────────────────────────
show_summary() {
    local new_domain="$1"
    local old_domain="$2"
    local ssl_ok="$3"

    local NGINX_STATUS XRAY_STATUS
    NGINX_STATUS=$(systemctl is-active nginx 2>/dev/null || echo "unknown")
    XRAY_STATUS=$(systemctl is-active xray 2>/dev/null || echo "unknown")

    echo ""
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "    ${WHITE}${BOLD}   RINGKASAN PERUBAHAN DOMAIN${NC}"
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
    echo -e "  ${BOLD}Domain Lama   ${NC}: ${YELLOW}${old_domain:-tidak ada}${NC}"
    echo -e "  ${BOLD}Domain Baru   ${NC}: ${GREEN}${new_domain}${NC}"
    echo -e "  ${BOLD}Mode          ${NC}: $(
        if [[ "$DOMAIN_MODE" == "1" ]]; then
            echo "Domain Owner (${DOMAIN_OWNER_BASE})"
        else
            echo "Domain Pribadi"
        fi)"

    echo -e "  ${BOLD}DNS Cloudflare${NC}: $(
        case "${CF_DNS_STATUS:-skip}" in
            ok)   echo -e "${GREEN}✓ Berhasil${NC}" ;;
            skip) echo -e "${YELLOW}⊘ Dilewati (Mode 2 atau CF belum setup)${NC}" ;;
            fail) echo -e "${YELLOW}⚠ Gagal — update DNS manual${NC}" ;;
        esac)"

    echo -e "  ${BOLD}SSL Certificate${NC}: $(
        if [[ "$ssl_ok" == "true" ]]; then
            echo -e "${GREEN}✓ Berhasil${NC}"
        else
            echo -e "${YELLOW}⚠ Gagal/Pending — jalankan: genssl${NC}"
        fi)"

    echo -e "  ${BOLD}Nginx         ${NC}: $(
        if [[ "$NGINX_STATUS" == "active" ]]; then
            echo -e "${GREEN}✓ Berjalan${NC}"
        else
            echo -e "${YELLOW}⚠ Tidak aktif${NC}"
        fi)"

    echo -e "  ${BOLD}Xray          ${NC}: $(
        if [[ "$XRAY_STATUS" == "active" ]]; then
            echo -e "${GREEN}✓ Berjalan${NC}"
        else
            echo -e "${YELLOW}⚠ Tidak aktif${NC}"
        fi)"

    echo ""
    echo -e "  ${INFO} File yang diperbarui:"
    echo -e "       /etc/xray/domain       /etc/v2ray/domain"
    echo -e "       /etc/xray/scdomain     /etc/v2ray/scdomain"
    echo -e "       /root/domain           /root/scdomain"
    echo -e "       /var/lib/scrz-prem/ipvps.conf"
    echo -e "       /etc/xray/domain.conf"
    echo -e "       /etc/nginx/conf.d/xray.conf"
    echo ""

    if [[ "$ssl_ok" != "true" ]]; then
        echo -e "  ${WARN} ${YELLOW}SSL belum berhasil. Setelah DNS propagasi:${NC}"
        echo -e "       Jalankan perintah: ${CYAN}genssl${NC}"
        echo ""
    fi

    if [[ "$NGINX_STATUS" != "active" || "$XRAY_STATUS" != "active" ]]; then
        echo -e "  ${WARN} Ada layanan yang tidak berjalan."
        echo -e "       Cek log: ${CYAN}journalctl -u nginx -n 30${NC}"
        echo -e "              : ${CYAN}journalctl -u xray -n 30${NC}"
        echo ""
    fi

    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
}

# ─────────────────────────────────────────────────────────────────
# MAIN — Flow end-to-end
# ─────────────────────────────────────────────────────────────────
main() {
    # Ambil domain lama sebelum apapun diubah
    local OLD_DOMAIN
    OLD_DOMAIN=$(read_current_domain)

    # Variabel global yang diisi oleh input_domain()
    NEW_DOMAIN=""
    DOMAIN_MODE=""
    SUBDOMAIN=""
    DOMAIN_BASE=""
    CF_DNS_STATUS="skip"

    # ── STEP 1: Input & validasi domain ──────────────────────────
    input_domain

    echo ""
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "  ${INFO} Memulai proses perubahan domain..."
    echo -e "  ${INFO} Domain lama : ${YELLOW}${OLD_DOMAIN:-tidak ada}${NC}"
    echo -e "  ${INFO} Domain baru : ${GREEN}${NEW_DOMAIN}${NC}"
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

    # ── STEP 2: Update DNS Cloudflare (Mode 1 saja) ───────────────
    if [[ "$DOMAIN_MODE" == "1" ]]; then
        update_cf_dns "$NEW_DOMAIN" "$SUBDOMAIN"
        if [[ "${CF_DNS_STATUS}" == "ok" ]]; then
            echo -e "\n  ${INFO} Tunggu 10 detik untuk propagasi DNS awal..."
            sleep 10
        fi
    fi

    # ── STEP 3: Update semua file domain ─────────────────────────
    update_domain_files "$NEW_DOMAIN" "$DOMAIN_MODE" "$SUBDOMAIN" "$DOMAIN_BASE"

    # ── STEP 4: Update nginx config ──────────────────────────────
    update_nginx_config "$OLD_DOMAIN" "$NEW_DOMAIN"

    # ── STEP 5: Generate / Renew SSL ─────────────────────────────
    local SSL_OK=false
    if renew_ssl "$NEW_DOMAIN"; then
        SSL_OK=true
    fi

    # ── STEP 6: Validasi config sebelum restart ───────────────────
    validate_config

    # ── STEP 7: Restart services dengan aman ─────────────────────
    restart_services

    # ── STEP 8: Ringkasan hasil ───────────────────────────────────
    show_summary "$NEW_DOMAIN" "$OLD_DOMAIN" "$SSL_OK"

    echo ""
    read -n 1 -s -r -p "  Tekan sembarang tombol untuk kembali ke menu..."
    echo ""
    menu 2>/dev/null || true
}

main
