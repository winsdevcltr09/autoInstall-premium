#!/bin/bash
# ================================================================
#   Script Installer - DevCulture XII Store VPN Premium
#   Version : 3.0.0 LTS
#   GitHub  : github.com/winsdevcltr09/autoInstall-premium
#   OS      : Ubuntu 18.04 / 20.04 / 22.04 | Debian 10 / 11
#   By      : DevCulture XII Store
# ================================================================

# ── Color Definitions ────────────────────────────────────────────
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
BLUE='\033[0;34m'
WHITE='\033[1;37m'
MAGENTA='\033[0;35m'
BOLD='\033[1m'
NC='\033[0m'

OK="[${GREEN}  OK  ${NC}]"
ERR="[${RED} FAIL ${NC}]"
INFO="[${CYAN} INFO ${NC}]"
WARN="[${YELLOW} WARN ${NC}]"
STEP="[${MAGENTA} STEP ${NC}]"

GITHUB_RAW="https://raw.githubusercontent.com/winsdevcltr09/autoInstall-premium/main"
LOG_FILE="/root/log-install.txt"
ERRORS=0

# ── Helper: log to file ───────────────────────────────────────────
log() { echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" >> "$LOG_FILE"; }

# ── Banner ────────────────────────────────────────────────────────
banner() {
    clear
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "     ${WHITE}${BOLD}   ____  _______  _____ ____    __  ___  ___ ${NC}"
    echo -e "     ${CYAN}  |  _ \\/ ___\\ \\/ /_ _|___ \\  \\ \\/ / ||_ _|${NC}"
    echo -e "     ${CYAN}  | | | | |    \\  / | |  __) |  \\  /   | || ${NC}"
    echo -e "     ${CYAN}  | |_| | |___ /  \\ | | / __/   /  \\   | | ${NC}"
    echo -e "     ${CYAN}  |____/ \\____/_/\\_\\___|_____| /_/\\_\\ |___|${NC}"
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "     ${WHITE}${BOLD}    DevCulture XII Store - Auto Installer VPN${NC}"
    echo -e "     ${CYAN}    Version 3.0.0 LTS | Ubuntu & Debian${NC}"
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
}

# ── Check root ───────────────────────────────────────────────────
check_root() {
    if [[ $EUID -ne 0 ]]; then
        echo -e "${ERR} Jalankan script ini sebagai ${RED}root${NC}!"
        echo -e "     Ketik: ${YELLOW}sudo -i${NC} lalu jalankan ulang."
        exit 1
    fi
    echo -e "${OK} Akses root terverifikasi"
}

# ── Check & validate OS ──────────────────────────────────────────
check_os() {
    echo -e "${INFO} Mendeteksi sistem operasi..."
    if [[ ! -f /etc/os-release ]]; then
        echo -e "${ERR} File /etc/os-release tidak ditemukan. OS tidak dikenali."
        exit 1
    fi
    . /etc/os-release
    OS_NAME="$ID"
    OS_VERSION="$VERSION_ID"
    OS_PRETTY="$PRETTY_NAME"

    case "$OS_NAME" in
        ubuntu)
            case "$OS_VERSION" in
                18.04)
                    echo -e "${WARN} Ubuntu 18.04 - Dukungan terbatas. Beberapa fitur mungkin tidak berfungsi."
                    ;;
                20.04)
                    echo -e "${OK} OS: ${GREEN}Ubuntu 20.04 LTS (Focal Fossa) - Direkomendasikan${NC}"
                    ;;
                22.04)
                    echo -e "${OK} OS: ${GREEN}Ubuntu 22.04 LTS (Jammy Jellyfish) - Didukung${NC}"
                    ;;
                *)
                    echo -e "${ERR} Ubuntu ${OS_VERSION} tidak didukung!"
                    echo -e "     OS yang didukung: Ubuntu 18.04 / 20.04 / 22.04"
                    exit 1
                    ;;
            esac
            ;;
        debian)
            case "$OS_VERSION" in
                10|11)
                    echo -e "${OK} OS: ${GREEN}Debian ${OS_VERSION} - Didukung${NC}"
                    ;;
                *)
                    echo -e "${ERR} Debian ${OS_VERSION} tidak didukung!"
                    exit 1
                    ;;
            esac
            ;;
        *)
            echo -e "${ERR} OS ${RED}${OS_NAME}${NC} tidak didukung!"
            echo -e "     Gunakan: Ubuntu 18.04/20.04/22.04 atau Debian 10/11"
            exit 1
            ;;
    esac

    # Cek arsitektur
    ARCH=$(uname -m)
    if [[ "$ARCH" != "x86_64" ]]; then
        echo -e "${WARN} Arsitektur ${ARCH} belum diuji (direkomendasikan: x86_64)"
    else
        echo -e "${OK} Arsitektur: ${GREEN}x86_64${NC}"
    fi

    log "OS: ${OS_PRETTY} | Arch: ${ARCH}"
}

# ── Check internet ───────────────────────────────────────────────
check_internet() {
    echo -e "${INFO} Memeriksa koneksi internet..."
    if ! ping -c 1 -W 5 8.8.8.8 &>/dev/null; then
        echo -e "${ERR} Tidak ada koneksi internet!"
        exit 1
    fi
    echo -e "${OK} Koneksi internet aktif"
    MYIP=$(curl -sf --max-time 10 ipv4.icanhazip.com 2>/dev/null || \
           curl -sf --max-time 10 ifconfig.me 2>/dev/null || \
           wget -qO- --timeout=10 ipinfo.io/ip 2>/dev/null)
    if [[ -z "$MYIP" ]]; then
        echo -e "${WARN} Tidak bisa mendeteksi IP publik"
        MYIP="unknown"
    else
        echo -e "${OK} IP VPS: ${GREEN}${MYIP}${NC}"
    fi
    log "IP VPS: ${MYIP}"
}

# ── Check izin ───────────────────────────────────────────────────
check_izin() {
    echo -e "${INFO} Memeriksa izin akses script..."
    local IZIN_URL="${GITHUB_RAW}/izin"
    local IZIN_DATA
    IZIN_DATA=$(curl -sf --max-time 15 "$IZIN_URL" 2>/dev/null)

    if [[ -z "$IZIN_DATA" ]]; then
        echo -e "${WARN} Tidak bisa mengambil data izin. Melanjutkan..."
        return 0
    fi

    local IZIN_IP
    IZIN_IP=$(echo "$IZIN_DATA" | grep -v "^#" | awk '{print $3}' | grep -w "$MYIP")

    if [[ -z "$IZIN_IP" ]]; then
        echo -e "${ERR} IP ${RED}${MYIP}${NC} tidak terdaftar!"
        echo -e "     Hubungi admin untuk mendaftarkan IP VPS Anda."
        echo -e "     ${CYAN}Telegram: t.me/dcxii${NC}"
        exit 1
    fi

    local EXP_DATE
    EXP_DATE=$(echo "$IZIN_DATA" | grep -w "$MYIP" | awk '{print $2}')
    local TODAY
    TODAY=$(date +%Y-%m-%d)

    if [[ "$TODAY" > "$EXP_DATE" ]]; then
        echo -e "${ERR} Lisensi untuk IP ${RED}${MYIP}${NC} sudah EXPIRED pada ${EXP_DATE}!"
        echo -e "     Perpanjang lisensi: ${CYAN}t.me/dcxii${NC}"
        exit 1
    fi

    local CLIENT_NAME
    CLIENT_NAME=$(echo "$IZIN_DATA" | grep -w "$MYIP" | awk '{print $1}')
    echo -e "${OK} Izin diterima — Client: ${GREEN}${CLIENT_NAME}${NC} | Exp: ${GREEN}${EXP_DATE}${NC}"
    log "Izin: ${CLIENT_NAME} | Exp: ${EXP_DATE}"
}

# ── Input domain ──────────────────────────────────────────────────
input_domain() {
    echo ""
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "     ${WHITE}${BOLD} Setup Domain${NC}"
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${INFO} Domain digunakan untuk VMess/Vless/Trojan TLS"
    echo -e "${WARN} Pastikan domain sudah pointing ke IP VPS: ${GREEN}${MYIP}${NC}"
    echo ""
    read -rp "  Input domain (contoh: vpn.example.com): " DOMAIN
    echo ""

    if [[ -z "$DOMAIN" ]]; then
        echo -e "${WARN} Domain kosong. Menggunakan IP VPS sebagai fallback: ${YELLOW}${MYIP}${NC}"
        DOMAIN="$MYIP"
    fi

    # Simpan domain
    mkdir -p /etc/xray /etc/v2ray
    echo "$DOMAIN" > /etc/xray/domain
    echo "$DOMAIN" > /etc/v2ray/domain
    echo "$DOMAIN" > /etc/xray/scdomain
    echo "$DOMAIN" > /etc/v2ray/scdomain
    echo "$DOMAIN" > /root/domain
    echo "$DOMAIN" > /root/scdomain
    mkdir -p /var/lib/scrz-prem
    echo "IP=$DOMAIN" > /var/lib/scrz-prem/ipvps.conf

    echo -e "${OK} Domain disimpan: ${GREEN}${DOMAIN}${NC}"
    log "Domain: ${DOMAIN}"
}

# ── Install dependencies ─────────────────────────────────────────
install_deps() {
    echo ""
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "     ${WHITE}${BOLD} [1/6] Update & Install Dependencies${NC}"
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

    echo -e "${INFO} Update paket sistem..."
    export DEBIAN_FRONTEND=noninteractive
    apt-get update -qq 2>/dev/null
    apt-get upgrade -y -qq 2>/dev/null
    echo -e "${OK} Sistem diperbarui"

    # Hapus paket konflik
    echo -e "${INFO} Menghapus paket konflik..."
    apt-get remove --purge -y ufw firewalld exim4 apache2 &>/dev/null
    echo -e "${OK} Paket konflik dihapus"

    # Paket dasar
    echo -e "${INFO} Menginstall dependensi utama..."
    local PKGS=(
        curl wget git zip unzip jq socat cron
        net-tools iptables iptables-persistent
        openssl ca-certificates gnupg lsb-release
        build-essential libssl-dev
        screen tmux htop iftop vnstat
        fail2ban rsyslog logrotate
        dropbear stunnel4
        squid net-tools bc
        bash-completion ntpdate chrony
        lsof dnsutils xz-utils
        sed gawk grep
    )

    # Python (berbeda per OS)
    if [[ "$OS_NAME" == "ubuntu" && "$OS_VERSION" == "22.04" ]]; then
        PKGS+=(python3 python3-pip)
    else
        PKGS+=(python3 python3-pip)
        apt-get install -y python2 &>/dev/null || true
    fi

    apt-get install -y "${PKGS[@]}" -qq 2>/dev/null
    echo -e "${OK} Dependensi utama terinstall"

    # Node.js
    echo -e "${INFO} Menginstall Node.js..."
    if ! command -v node &>/dev/null; then
        curl -fsSL https://deb.nodesource.com/setup_18.x | bash - &>/dev/null
        apt-get install -y nodejs -qq &>/dev/null
    fi
    echo -e "${OK} Node.js $(node -v 2>/dev/null || echo 'terinstall')"

    log "Dependencies installed"
}

# ── System configuration ─────────────────────────────────────────
system_config() {
    echo ""
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "     ${WHITE}${BOLD} [2/6] Konfigurasi Sistem${NC}"
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

    # Timezone
    ln -sf /usr/share/zoneinfo/Asia/Jakarta /etc/localtime
    echo -e "${OK} Timezone: Asia/Jakarta (GMT+7)"

    # Disable IPv6
    cat >> /etc/sysctl.conf << 'EOF'
net.ipv6.conf.all.disable_ipv6 = 1
net.ipv6.conf.default.disable_ipv6 = 1
net.ipv6.conf.lo.disable_ipv6 = 1
EOF
    sysctl -p &>/dev/null
    echo -e "${OK} IPv6 dinonaktifkan"

    # Hostname fix
    local LOCALIP
    LOCALIP=$(hostname -I | awk '{print $1}')
    local HST
    HST=$(hostname)
    if ! grep -q "$HST" /etc/hosts; then
        echo "$LOCALIP $HST" >> /etc/hosts
    fi
    echo -e "${OK} Hostname dikonfigurasi"

    # Buat direktori yang diperlukan
    mkdir -p /root/akun/{vmess,vless,shadowsocks,trojan}
    mkdir -p /etc/xray /etc/v2ray /var/lib/scrz-prem
    mkdir -p /root/backup
    echo -e "${OK} Direktori sistem dibuat"

    log "System configured"
}

# ── Download & run sub-installers ────────────────────────────────
run_dl() {
    local label="$1"
    local url_path="$2"
    local filename="$3"
    echo -e "${STEP} ${label}..."
    if wget -q --timeout=60 --tries=3 -O "/tmp/${filename}" "${GITHUB_RAW}/${url_path}" 2>/dev/null \
       && [[ -s "/tmp/${filename}" ]] \
       && ! grep -q "404: Not Found" "/tmp/${filename}" 2>/dev/null; then
        chmod +x "/tmp/${filename}"
        bash "/tmp/${filename}"
        local EXIT_CODE=$?
        rm -f "/tmp/${filename}"
        if [[ $EXIT_CODE -eq 0 ]]; then
            echo -e "${OK} ${label} selesai"
        else
            echo -e "${WARN} ${label} selesai dengan kode: ${EXIT_CODE}"
        fi
    else
        echo -e "${ERR} Gagal download ${label} dari: ${GITHUB_RAW}/${url_path}"
        ((ERRORS++))
    fi
}

install_services() {
    echo ""
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "     ${WHITE}${BOLD} [3/6] Install SSH & Websocket${NC}"
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    run_dl "SSH & Multi-Port" "ssh-vpn.sh" "ssh-vpn.sh"
    run_dl "Nginx SSL" "nginx-ssl.sh" "nginx-ssl.sh"
    run_dl "WebSocket (SSH)" "insshws.sh" "insshws.sh"

    echo ""
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "     ${WHITE}${BOLD} [4/6] Install Xray Core${NC}"
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    run_dl "Xray Core" "ins-xray.sh" "ins-xray.sh"

    echo ""
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "     ${WHITE}${BOLD} [5/6] Install SlowDNS${NC}"
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    run_dl "SlowDNS" "slow.sh" "slow.sh"
}

# ── Install menu scripts ─────────────────────────────────────────
install_menus() {
    echo ""
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "     ${WHITE}${BOLD} [6/6] Install Menu & Script Manajemen${NC}"
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

    # Jalankan senmenu.sh untuk install semua menu sekaligus
    run_dl "Semua Script Menu" "senmenu.sh" "senmenu.sh"

    # Pastikan update script ada
    wget -q --timeout=30 -O /usr/bin/updatsc "${GITHUB_RAW}/update.sh" 2>/dev/null && chmod +x /usr/bin/updatsc
    echo -e "${OK} Script update terpasang di /usr/bin/updatsc"
}

# ── Setup cronjobs ───────────────────────────────────────────────
setup_cron() {
    echo -e "${INFO} Mengatur cronjob..."
    # Hapus entri lama jika ada
    sed -i '/root reboot\|root clog\|root pkill.*menu\|root xp\|root notramcpu/d' /etc/crontab 2>/dev/null

    cat >> /etc/crontab << 'CRONEOF'
0 5 * * * root /sbin/reboot
* * * * * root /usr/bin/clog
59 * * * * root pkill -f menu
0 1 * * * root /usr/bin/xp
*/5 * * * * root /usr/bin/notramcpu
CRONEOF

    systemctl enable cron &>/dev/null
    systemctl restart cron &>/dev/null
    echo -e "${OK} Cronjob dikonfigurasi"
    log "Cron configured"
}

# ── Setup auto-login menu ─────────────────────────────────────────
setup_profile() {
    cat > /root/.profile << 'PROFEOF'
# ~/.profile: DevCulture XII Store
if [ "$BASH" ]; then
  if [ -f ~/.bashrc ]; then
    . ~/.bashrc
  fi
fi
mesg n 2>/dev/null || true
clear
menu
PROFEOF
    chmod 644 /root/.profile
    echo -e "${OK} Auto-launch menu dikonfigurasi"

    # Simpan info ISP
    curl -sf --max-time 10 https://ipapi.co/org > /root/.isp 2>/dev/null || true
}

# ── Final Summary ─────────────────────────────────────────────────
show_summary() {
    clear
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "     ${WHITE}${BOLD}  INSTALASI SELESAI - DevCulture XII Store${NC}"
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
    echo -e "     ${CYAN}>>> Service & Port${NC}" | tee -a "$LOG_FILE"
    echo -e "     ${WHITE}OpenSSH             : 22, 53, 2222, 2269${NC}" | tee -a "$LOG_FILE"
    echo -e "     ${WHITE}SSH Websocket       : 80, 8880, 8080${NC}" | tee -a "$LOG_FILE"
    echo -e "     ${WHITE}SSH SSL Websocket   : 443${NC}" | tee -a "$LOG_FILE"
    echo -e "     ${WHITE}Stunnel5            : 222, 777${NC}" | tee -a "$LOG_FILE"
    echo -e "     ${WHITE}Dropbear            : 109, 143${NC}" | tee -a "$LOG_FILE"
    echo -e "     ${WHITE}BadVPN (UDP GW)     : 7100–7300${NC}" | tee -a "$LOG_FILE"
    echo -e "     ${WHITE}Nginx               : 81${NC}" | tee -a "$LOG_FILE"
    echo -e "     ${WHITE}XRAY VMess TLS      : 443${NC}" | tee -a "$LOG_FILE"
    echo -e "     ${WHITE}XRAY VMess Non-TLS  : 80${NC}" | tee -a "$LOG_FILE"
    echo -e "     ${WHITE}XRAY Vless TLS      : 443${NC}" | tee -a "$LOG_FILE"
    echo -e "     ${WHITE}XRAY Trojan WS/GRPC : 443${NC}" | tee -a "$LOG_FILE"
    echo -e "     ${WHITE}Shadowsocks WS/GRPC : 443${NC}" | tee -a "$LOG_FILE"
    echo -e "     ${WHITE}SlowDNS             : 53, 5300${NC}" | tee -a "$LOG_FILE"
    echo ""
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "     ${CYAN}>>> Fitur Sistem${NC}"
    echo -e "     ${WHITE}Timezone     : Asia/Jakarta (GMT+7)${NC}"
    echo -e "     ${WHITE}Fail2Ban     : [ON]${NC}"
    echo -e "     ${WHITE}IPtables     : [ON]${NC}"
    echo -e "     ${WHITE}IPv6         : [OFF]${NC}"
    echo -e "     ${WHITE}Auto-Reboot  : [ON] 05:00 WIB${NC}"
    echo -e "     ${WHITE}Auto-Expire  : [ON] 01:00 WIB${NC}"
    echo -e "     ${WHITE}Auto-Update  : ketik ${YELLOW}updatsc${WHITE} di terminal${NC}"
    echo -e "     ${WHITE}Domain/Host  : ${GREEN}${DOMAIN}${NC}"
    echo -e "     ${WHITE}IP VPS       : ${GREEN}${MYIP}${NC}"
    echo ""
    if [[ $ERRORS -gt 0 ]]; then
        echo -e "     ${YELLOW}⚠ Ada ${ERRORS} error selama instalasi.${NC}"
        echo -e "     ${WHITE}Log: ${YELLOW}cat ${LOG_FILE}${NC}"
    else
        echo -e "     ${GREEN}✓ Instalasi berhasil tanpa error!${NC}"
    fi
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "     ${WHITE}${BOLD}  DevCulture XII Store VPN Premium v3.0.0 LTS${NC}"
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
    log "=== Instalasi selesai. Errors: ${ERRORS} ==="

    read -rp "  Reboot sekarang? (y/n): " ANS
    if [[ "$ANS" =~ ^[Yy]$ ]]; then
        echo -e "${INFO} Reboot dalam 3 detik..."
        sleep 3
        reboot
    else
        echo -e "${INFO} Ketik ${YELLOW}menu${NC} untuk membuka panel manajemen."
        echo ""
    fi
}

# ── Main ──────────────────────────────────────────────────────────
main() {
    rm -f "$LOG_FILE"
    log "=== Mulai Instalasi ==="

    banner
    check_root
    check_os
    check_internet
    check_izin
    input_domain
    install_deps
    system_config
    install_services
    install_menus
    setup_cron
    setup_profile

    # Versi
    echo "3.0.0" > /root/versi

    # Bersihkan file sementara
    cd /root
    rm -f setupku.sh ins-xray.sh senmenu.sh xraymode.sh slowdns.sh \
          nginx-ssl.sh ssh-vpn.sh insshws.sh update.sh 2>/dev/null

    show_summary
}

main
