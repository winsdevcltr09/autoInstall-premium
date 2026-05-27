#!/bin/bash
# ================================================================
#  PREFLIGHT CHECK — autoInstall-premium VPN Script
#  DevCulture XII Store VPN Premium
#  Version : 1.0.0
#  Desc    : Fail-fast environment validator. Runs before setupku.sh
#            to catch all blocking issues before any installation.
#  Usage   : bash preflight.sh [--domain yourdomain.com] [--skip-dns]
#  Idempotent: aman dijalankan berkali-kali tanpa efek samping
# ================================================================

# ── WARNA & SIMBOL ──────────────────────────────────────────────
RED='\033[0;31m';  GREEN='\033[0;32m'; YELLOW='\033[1;33m'
CYAN='\033[0;36m'; BLUE='\033[0;34m';  WHITE='\033[1;37m'
MAGENTA='\033[0;35m'; BOLD='\033[1m';  NC='\033[0m'

OK="  [${GREEN} OK ${NC}]"
WARN="[${YELLOW}WARN${NC}]"
FAIL="[${RED}FAIL${NC}]"
INFO="[${CYAN}INFO${NC}]"
FIX="[${MAGENTA} FIX${NC}]"
SEP="${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

# ── COUNTERS & STATE ────────────────────────────────────────────
CRITICAL=0
WARNINGS=0
AUTOFIX=0
LOG_FILE="/tmp/preflight-$(date +%Y%m%d-%H%M%S).log"
DOMAIN_ARG=""
SKIP_DNS=false
SKIP_DOMAIN_CHECK=false

# ── ARGUMENT PARSING ────────────────────────────────────────────
while [[ $# -gt 0 ]]; do
  case "$1" in
    --domain) DOMAIN_ARG="$2"; shift 2 ;;
    --skip-dns) SKIP_DNS=true; shift ;;
    --skip-domain) SKIP_DOMAIN_CHECK=true; shift ;;
    *) shift ;;
  esac
done

# ── HELPER FUNCTIONS ────────────────────────────────────────────
log()      { echo "[$(date '+%H:%M:%S')] $*" >> "$LOG_FILE"; }
ok()       { echo -e "${OK}  $*"; log "OK: $*"; }
warn()     { echo -e "${WARN}  $*"; log "WARN: $*"; WARNINGS=$((WARNINGS+1)); }
fail()     { echo -e "${FAIL}  $*"; log "CRITICAL: $*"; CRITICAL=$((CRITICAL+1)); }
info()     { echo -e "${INFO}  $*"; log "INFO: $*"; }
autofix()  { echo -e "${FIX}  $*"; log "AUTOFIX: $*"; AUTOFIX=$((AUTOFIX+1)); }
section()  { echo -e "\n${SEP}"; echo -e "  ${BOLD}${WHITE}$*${NC}"; echo -e "${SEP}"; }

# Retry dengan timeout
retry_cmd() {
  local retries=3 delay=2 timeout_s=10
  local cmd=("${@}")
  for ((i=1; i<=retries; i++)); do
    if timeout "$timeout_s" "${cmd[@]}" &>/dev/null; then
      return 0
    fi
    [[ $i -lt $retries ]] && sleep "$delay"
  done
  return 1
}

# ── BANNER ──────────────────────────────────────────────────────
clear
echo -e "${SEP}"
echo -e "  ${BOLD}${WHITE}   ____  ____  _____  _____ _     ___ ____ _   _ _____  ${NC}"
echo -e "  ${CYAN}  |  _ \\|  _ \\| ____||  ___| |   |_ _/ ___| | | |_   _| ${NC}"
echo -e "  ${CYAN}  | |_) | |_) |  _|  | |_  | |    | | |  _| |_| | | |   ${NC}"
echo -e "  ${CYAN}  |  __/|  _ <| |___ |  _| | |___ | | |_| |  _  | | |   ${NC}"
echo -e "  ${CYAN}  |_|   |_| \\_\\_____||_|   |_____|___\\____|_| |_| |_|   ${NC}"
echo -e "${SEP}"
echo -e "  ${WHITE}${BOLD}  DevCulture XII — VPN Installer Pre-flight Check v1.0${NC}"
echo -e "  ${CYAN}  Log: ${LOG_FILE}${NC}"
echo -e "${SEP}"
echo ""
log "=== PREFLIGHT START $(date) ==="

# ════════════════════════════════════════════════════════════════
# 1. ROOT CHECK
# ════════════════════════════════════════════════════════════════
section "1/17 · Root & Sudo Validation"

if [[ $EUID -ne 0 ]]; then
  fail "Script harus dijalankan sebagai root!"
  echo -e "       ${YELLOW}Solusi: ${WHITE}sudo su - ${NC}lalu jalankan ulang."
  echo ""
  echo -e "${RED}[STOP] Tidak bisa lanjut tanpa akses root.${NC}"
  exit 1
fi
ok "Berjalan sebagai root (EUID=0)"

# Cek sudo tersedia untuk sub-command
if command -v sudo &>/dev/null; then
  ok "sudo tersedia"
else
  warn "sudo tidak ditemukan — tidak masalah jika sudah root"
fi

# ════════════════════════════════════════════════════════════════
# 2. OS & VERSI
# ════════════════════════════════════════════════════════════════
section "2/17 · Deteksi OS & Versi"

if [[ ! -f /etc/os-release ]]; then
  fail "Tidak dapat mendeteksi OS — /etc/os-release tidak ada"
else
  . /etc/os-release
  OS_ID="$ID"
  OS_VER="$VERSION_ID"
  OS_PRETTY="$PRETTY_NAME"

  case "$OS_ID" in
    ubuntu)
      case "$OS_VER" in
        20.04|22.04|24.04) ok "OS didukung: ${WHITE}$OS_PRETTY${NC}" ;;
        18.04) warn "Ubuntu 18.04 EOL — disarankan upgrade ke 20.04+" ;;
        *)     warn "Ubuntu $OS_VER belum diuji penuh — lanjut dengan risiko sendiri" ;;
      esac
      ;;
    debian)
      case "$OS_VER" in
        11|12) ok "OS didukung: ${WHITE}$OS_PRETTY${NC}" ;;
        10)    warn "Debian 10 EOL — disarankan upgrade ke 11+" ;;
        *)     warn "Debian $OS_VER belum diuji — lanjut dengan risiko sendiri" ;;
      esac
      ;;
    *)
      fail "OS tidak didukung: $OS_PRETTY (hanya Ubuntu/Debian)"
      ;;
  esac
fi

# ════════════════════════════════════════════════════════════════
# 3. ARSITEKTUR CPU & VIRTUALISASI
# ════════════════════════════════════════════════════════════════
section "3/17 · Arsitektur CPU & Virtualisasi"

ARCH=$(uname -m)
case "$ARCH" in
  x86_64)  ok "Arsitektur: ${WHITE}x86_64 (amd64)${NC}" ;;
  aarch64) ok "Arsitektur: ${WHITE}aarch64 (arm64)${NC}" ;;
  armv7*)  warn "Arsitektur: ${WHITE}ARMv7${NC} — beberapa binary mungkin tidak tersedia" ;;
  *)       fail "Arsitektur tidak dikenal: $ARCH — binary mungkin tidak kompatibel" ;;
esac

# Deteksi virtualisasi
VIRT="unknown"
if command -v systemd-detect-virt &>/dev/null; then
  VIRT=$(systemd-detect-virt 2>/dev/null || echo "none")
elif [[ -f /proc/cpuinfo ]]; then
  if grep -qi "hypervisor" /proc/cpuinfo; then VIRT="vm"; fi
fi

case "$VIRT" in
  kvm|qemu)  ok "Virtualisasi: ${WHITE}KVM/QEMU${NC} — optimal" ;;
  xen)       ok "Virtualisasi: ${WHITE}Xen${NC}" ;;
  vmware)    ok "Virtualisasi: ${WHITE}VMware${NC}" ;;
  lxc*|openvz) warn "Virtualisasi: ${WHITE}$VIRT${NC} — TUN/TAP dan iptables mungkin terbatas" ;;
  none)      ok "Bare metal / tidak terdeteksi sebagai VM" ;;
  *)         info "Virtualisasi: ${WHITE}$VIRT${NC}" ;;
esac

# Cek TUN/TAP device (dibutuhkan OpenVPN)
if [[ -c /dev/net/tun ]]; then
  ok "TUN/TAP device tersedia (/dev/net/tun)"
else
  warn "TUN/TAP device tidak ada — OpenVPN tidak akan bisa berjalan"
  info "Solusi: aktifkan TUN di panel VPS provider Anda"
fi

# ════════════════════════════════════════════════════════════════
# 4. RAM, CPU, DISK
# ════════════════════════════════════════════════════════════════
section "4/17 · Hardware Resources (RAM, CPU, Disk)"

# RAM
RAM_MB=$(awk '/MemTotal/ {printf "%d", $2/1024}' /proc/meminfo)
if [[ $RAM_MB -ge 512 ]]; then
  ok "RAM: ${WHITE}${RAM_MB} MB${NC} (minimum 512 MB)"
elif [[ $RAM_MB -ge 256 ]]; then
  warn "RAM: ${WHITE}${RAM_MB} MB${NC} — sangat minim, install mungkin lambat/gagal"
else
  fail "RAM hanya ${RAM_MB} MB — minimum yang dibutuhkan adalah 256 MB"
fi

# CPU cores
CPU_CORES=$(nproc 2>/dev/null || grep -c "^processor" /proc/cpuinfo)
if [[ $CPU_CORES -ge 1 ]]; then
  ok "CPU: ${WHITE}${CPU_CORES} core(s)${NC}"
else
  warn "Tidak dapat mendeteksi jumlah CPU core"
fi

# Disk space (root partition)
DISK_FREE_MB=$(df -m / | awk 'NR==2 {print $4}')
if [[ $DISK_FREE_MB -ge 2048 ]]; then
  ok "Disk free: ${WHITE}${DISK_FREE_MB} MB${NC} (minimum 2 GB)"
elif [[ $DISK_FREE_MB -ge 1024 ]]; then
  warn "Disk free: ${WHITE}${DISK_FREE_MB} MB${NC} — agak sempit, pantau selama install"
else
  fail "Disk free hanya ${DISK_FREE_MB} MB — minimum 1 GB diperlukan untuk install"
fi

# /tmp space
TMP_FREE_MB=$(df -m /tmp | awk 'NR==2 {print $4}')
if [[ $TMP_FREE_MB -ge 100 ]]; then
  ok "/tmp free: ${WHITE}${TMP_FREE_MB} MB${NC}"
else
  warn "/tmp free hanya ${TMP_FREE_MB} MB — mungkin bermasalah saat download"
fi

# ════════════════════════════════════════════════════════════════
# 5. KONEKTIVITAS INTERNET & DNS
# ════════════════════════════════════════════════════════════════
section "5/17 · Internet Connectivity & DNS"

# Internet connectivity
INTERNET_OK=false
for host in 8.8.8.8 1.1.1.1 208.67.222.222; do
  if timeout 5 ping -c 1 -W 3 "$host" &>/dev/null; then
    INTERNET_OK=true
    ok "Internet: terhubung (ping $host berhasil)"
    break
  fi
done
if ! $INTERNET_OK; then
  fail "Tidak ada koneksi internet — cek network VPS Anda"
fi

# DNS resolution
DNS_OK=false
for domain in google.com github.com raw.githubusercontent.com; do
  if timeout 5 nslookup "$domain" &>/dev/null || \
     timeout 5 getent hosts "$domain" &>/dev/null; then
    DNS_OK=true
    ok "DNS: bisa resolve ${WHITE}$domain${NC}"
    break
  fi
done
if ! $DNS_OK; then
  fail "DNS tidak bekerja — tidak bisa resolve hostname"
  info "Solusi: echo 'nameserver 8.8.8.8' >> /etc/resolv.conf"
fi

# HTTPS connectivity ke GitHub (sumber download utama)
if timeout 10 curl -s --head https://github.com | grep -q "200\|301\|302"; then
  ok "HTTPS ke github.com: ${WHITE}OK${NC}"
else
  warn "Tidak bisa akses github.com via HTTPS — download mungkin gagal"
fi

# Endpoint kritis repo ini
GITHUB_RAW="https://raw.githubusercontent.com/winsdevcltr09/autoInstall-premium/main"
if timeout 10 curl -s --head "${GITHUB_RAW}/setupku.sh" | grep -q "200"; then
  ok "Endpoint repo: ${WHITE}dapat diakses${NC}"
else
  warn "Endpoint raw.githubusercontent.com lambat/tidak bisa diakses — install mungkin gagal"
fi

# ════════════════════════════════════════════════════════════════
# 6. DETEKSI KONFLIK PORT
# ════════════════════════════════════════════════════════════════
section "6/17 · Port Conflict Detection"

# Fungsi cek port
check_port() {
  local port=$1 svc=$2 severity=${3:-warn}
  if ss -tlnp 2>/dev/null | grep -q ":${port} " || \
     netstat -tlnp 2>/dev/null | grep -q ":${port} "; then
    local proc=$(ss -tlnp 2>/dev/null | grep ":${port} " | \
                 grep -oP 'users:\(\(".*?"\)' | head -1 || echo "unknown")
    if [[ "$severity" == "fail" ]]; then
      fail "Port ${WHITE}$port ($svc)${NC} sudah dipakai! [$proc]"
    else
      warn "Port ${WHITE}$port ($svc)${NC} sudah dipakai [$proc]"
    fi
    return 1
  else
    ok "Port ${WHITE}$port ($svc)${NC}: bebas"
    return 0
  fi
}

check_port 22   "SSH default"         warn
check_port 80   "HTTP/Nginx"          fail
check_port 443  "HTTPS/Nginx+Xray"    fail
check_port 2082 "WS-OpenSSH"          warn
check_port 2083 "WS TLS"              warn
check_port 2086 "WS non-TLS"          warn
check_port 8880 "WS-Dropbear"         warn
check_port 700  "WS-Stunnel"          warn
check_port 1194 "OpenVPN UDP"         warn
check_port 1194 "OpenVPN TCP"         warn
check_port 109  "Dropbear"            warn
check_port 143  "Dropbear alt"        warn
check_port 2222 "SSH SlowDNS"         warn
check_port 2269 "SSH SlowDNS server"  warn
check_port 5300 "SlowDNS UDP"         warn
check_port 7100 "BadVPN UDPGW"        warn
check_port 7200 "BadVPN UDPGW alt"    warn
check_port 7300 "BadVPN UDPGW alt2"   warn
check_port 8388 "Shadowsocks"         warn
check_port 3128 "Squid proxy"         warn

# ════════════════════════════════════════════════════════════════
# 7. DEPENDENSI TOOL
# ════════════════════════════════════════════════════════════════
section "7/17 · Dependency & Tool Validation"

MISSING_TOOLS=()
check_tool() {
  local tool=$1 pkg=${2:-$1} critical=${3:-false}
  if command -v "$tool" &>/dev/null; then
    local ver=$(${tool} --version 2>&1 | head -1 | grep -oP '\d+\.\d+[\.\d]*' | head -1)
    ok "${WHITE}$tool${NC} tersedia${ver:+ (v$ver)}"
  else
    if $critical; then
      fail "${WHITE}$tool${NC} tidak ditemukan — paket: $pkg"
      MISSING_TOOLS+=("$pkg")
    else
      warn "${WHITE}$tool${NC} tidak ditemukan — paket: $pkg"
      MISSING_TOOLS+=("$pkg")
    fi
  fi
}

check_tool python3   python3          true
check_tool curl      curl             true
check_tool wget      wget             true
check_tool unzip     unzip            false
check_tool jq        jq               false
check_tool cron      cron             false
check_tool crontab   cron             false
check_tool openssl   openssl          true
check_tool tar       tar              true
check_tool git       git              false
check_tool netstat   net-tools        false
check_tool ss        iproute2         false
check_tool iptables  iptables         false
check_tool nslookup  dnsutils         false
check_tool lsof      lsof             false
check_tool bc        bc               false
check_tool socat     socat            false
check_tool certbot   certbot          false

# Cek systemctl
if command -v systemctl &>/dev/null && systemctl --version &>/dev/null; then
  ok "${WHITE}systemctl${NC} tersedia (systemd berjalan)"
else
  fail "${WHITE}systemctl${NC} tidak ada atau systemd tidak berjalan"
fi

# Auto-fix: install tools yang hilang (jika tidak kritis)
if [[ ${#MISSING_TOOLS[@]} -gt 0 ]]; then
  NON_CRITICAL_MISSING=()
  for t in "${MISSING_TOOLS[@]}"; do
    # Hanya auto-install yang tidak kritis
    if [[ "$t" != "python3" && "$t" != "curl" && "$t" != "openssl" ]]; then
      NON_CRITICAL_MISSING+=("$t")
    fi
  done

  if [[ ${#NON_CRITICAL_MISSING[@]} -gt 0 ]]; then
    autofix "Auto-install tool yang hilang: ${NON_CRITICAL_MISSING[*]}"
    apt-get update -qq 2>/dev/null
    apt-get install -y -qq "${NON_CRITICAL_MISSING[@]}" 2>/dev/null && \
      ok "Auto-install selesai: ${NON_CRITICAL_MISSING[*]}" || \
      warn "Auto-install gagal — install manual: apt install ${NON_CRITICAL_MISSING[*]}"
  fi
fi

# ════════════════════════════════════════════════════════════════
# 8. PACKAGE MANAGER HEALTH
# ════════════════════════════════════════════════════════════════
section "8/17 · Package Manager Health (apt)"

if ! command -v apt-get &>/dev/null; then
  fail "apt-get tidak ditemukan — bukan sistem Debian/Ubuntu?"
else
  # Test apt ringan (hanya cek, tidak install)
  APT_OUTPUT=$(apt-get update -qq 2>&1 | grep -iE "error|failed|unable" | head -3)
  if [[ -z "$APT_OUTPUT" ]]; then
    ok "apt update: ${WHITE}berjalan normal${NC}"
  else
    warn "apt update ada pesan error:"
    echo -e "       ${YELLOW}$APT_OUTPUT${NC}"
    autofix "Mencoba perbaiki dpkg lock..."
    rm -f /var/lib/dpkg/lock-frontend /var/lib/dpkg/lock 2>/dev/null
    dpkg --configure -a 2>/dev/null
  fi

  # Cek apt lock
  if fuser /var/lib/dpkg/lock &>/dev/null 2>&1; then
    warn "dpkg/apt sedang dipakai proses lain — tunggu sebentar"
  else
    ok "apt lock: tidak terkunci"
  fi
fi

# ════════════════════════════════════════════════════════════════
# 9. FIREWALL COMPATIBILITY
# ════════════════════════════════════════════════════════════════
section "9/17 · Firewall Compatibility"

# iptables
if command -v iptables &>/dev/null; then
  if iptables -L -n &>/dev/null 2>&1; then
    IPRULES=$(iptables -L -n 2>/dev/null | grep -c "^ACCEPT\|^DROP\|^REJECT" || echo 0)
    ok "iptables: ${WHITE}aktif${NC} ($IPRULES rules aktif)"
  else
    warn "iptables ada tapi tidak bisa list rules — mungkin nftables mode"
  fi
else
  warn "iptables tidak ditemukan"
fi

# nftables
if command -v nft &>/dev/null; then
  ok "nftables: ${WHITE}tersedia${NC}"
  warn "nftables terdeteksi — pastikan tidak ada konflik rule dengan iptables"
fi

# ufw
if command -v ufw &>/dev/null; then
  UFW_STATUS=$(ufw status 2>/dev/null | head -1)
  if echo "$UFW_STATUS" | grep -qi "active"; then
    warn "UFW aktif — script ini mengelola iptables langsung, konflik mungkin terjadi"
    info "Solusi: ufw disable (atau biarkan jika sudah dikonfigurasi manual)"
  else
    ok "UFW: ${WHITE}tidak aktif${NC} (aman)"
  fi
fi

# ════════════════════════════════════════════════════════════════
# 10. TIME SYNC / NTP
# ════════════════════════════════════════════════════════════════
section "10/17 · Time Sync & NTP"

# Cek sinkronisasi waktu
if command -v timedatectl &>/dev/null; then
  TIMED_OUT=$(timedatectl show 2>/dev/null | grep -E "NTPSynchronized|Synchronized")
  if echo "$TIMED_OUT" | grep -qi "yes\|true"; then
    TIME_NOW=$(date '+%Y-%m-%d %H:%M:%S %Z')
    ok "NTP sinkron: ${WHITE}$TIME_NOW${NC}"
  else
    warn "NTP tidak tersinkron — sertifikat SSL bisa gagal jika jam VPS salah"
    autofix "Mencoba sinkron waktu via NTP..."
    if command -v timedatectl &>/dev/null; then
      timedatectl set-ntp true 2>/dev/null
      systemctl restart systemd-timesyncd 2>/dev/null || true
      ok "NTP diaktifkan"
    elif command -v ntpdate &>/dev/null; then
      ntpdate -u pool.ntp.org 2>/dev/null && ok "NTP sinkron via ntpdate" || \
        warn "ntpdate gagal — cek koneksi ke pool.ntp.org"
    fi
  fi
else
  # Fallback: bandingkan dengan waktu Google
  SERVER_TIME=$(curl -sI --max-time 5 https://google.com 2>/dev/null | \
                grep -i "^date:" | sed 's/date: //i' | tr -d '\r')
  if [[ -n "$SERVER_TIME" ]]; then
    info "Waktu server: ${WHITE}$(date)${NC}"
    info "Waktu Google: ${WHITE}$SERVER_TIME${NC}"
  else
    warn "Tidak bisa verifikasi sinkronisasi waktu"
  fi
fi

# ════════════════════════════════════════════════════════════════
# 11. DOMAIN & DNS VALIDATION
# ════════════════════════════════════════════════════════════════
section "11/17 · Domain & DNS Validation"

MY_IP=$(timeout 10 curl -s https://ipinfo.io/ip 2>/dev/null || \
        timeout 10 curl -s https://api.ipify.org 2>/dev/null || \
        timeout 10 wget -qO- https://ipinfo.io/ip 2>/dev/null)

if [[ -n "$MY_IP" ]]; then
  ok "IP publik VPS: ${WHITE}$MY_IP${NC}"
else
  fail "Tidak bisa deteksi IP publik VPS — cek koneksi internet"
fi

# Cek domain yang sudah dikonfigurasi
XRAY_DOMAIN=""
if [[ -f /etc/xray/domain ]]; then
  XRAY_DOMAIN=$(cat /etc/xray/domain)
  info "Domain terkonfigurasi: ${WHITE}$XRAY_DOMAIN${NC}"
fi

# Gunakan domain dari argumen atau dari file
CHECK_DOMAIN="${DOMAIN_ARG:-$XRAY_DOMAIN}"

if [[ -n "$CHECK_DOMAIN" ]] && ! $SKIP_DOMAIN_CHECK; then
  info "Validasi DNS untuk: ${WHITE}$CHECK_DOMAIN${NC}"

  # Resolve domain
  DOMAIN_IP=$(getent hosts "$CHECK_DOMAIN" 2>/dev/null | awk '{print $1}' | head -1)
  if [[ -z "$DOMAIN_IP" ]]; then
    DOMAIN_IP=$(nslookup "$CHECK_DOMAIN" 2>/dev/null | \
                awk '/^Address: / {print $2}' | grep -v "#" | head -1)
  fi

  if [[ -n "$DOMAIN_IP" ]]; then
    if [[ "$DOMAIN_IP" == "$MY_IP" ]]; then
      ok "DNS: ${WHITE}$CHECK_DOMAIN${NC} → $DOMAIN_IP = IP VPS ini ✓"
    else
      warn "DNS: ${WHITE}$CHECK_DOMAIN${NC} → $DOMAIN_IP ≠ $MY_IP (IP VPS)"
      info "Pastikan A record domain mengarah ke IP VPS ini"
    fi
  else
    warn "DNS: ${WHITE}$CHECK_DOMAIN${NC} tidak bisa di-resolve"
    info "Solusi: set A record domain ke $MY_IP lalu tunggu propagasi DNS"
  fi
elif [[ -z "$CHECK_DOMAIN" ]] && ! $SKIP_DNS; then
  info "Domain belum dikonfigurasi — gunakan: bash preflight.sh --domain yourdomain.com"
fi

# Cek nsdomain untuk SlowDNS
if [[ -f /etc/xray/nsdomain ]]; then
  NS_DOMAIN=$(cat /etc/xray/nsdomain)
  ok "SlowDNS NS domain: ${WHITE}$NS_DOMAIN${NC}"
else
  warn "SlowDNS NS domain belum diset — slow.sh akan gagal"
  info "Solusi: echo 'ns.yourdomain.com' > /etc/xray/nsdomain"
fi

# ════════════════════════════════════════════════════════════════
# 12. DETEKSI INSTALL YANG SUDAH ADA
# ════════════════════════════════════════════════════════════════
section "12/17 · Existing Installation Detection"

EXISTING=false

check_existing() {
  local path=$1 desc=$2
  if [[ -e "$path" ]]; then
    warn "Sudah ada: ${WHITE}$desc${NC} ($path)"
    EXISTING=true
  fi
}

check_existing /etc/xray/config.json   "Xray config"
check_existing /usr/bin/xray           "Xray binary"
check_existing /etc/nginx/conf.d/xray.conf "Nginx Xray config"
check_existing /etc/slowdns            "SlowDNS install dir"
check_existing /usr/local/bin/ws-openssh  "WS-OpenSSH proxy"
check_existing /usr/local/bin/ws-dropbear "WS-Dropbear proxy"
check_existing /usr/sbin/dropbear      "Dropbear SSH"
check_existing /etc/openvpn            "OpenVPN config dir"
check_existing /root/log-install.txt   "Log install sebelumnya"

if $EXISTING; then
  warn "Ada install sebelumnya terdeteksi"
  echo -e "       ${YELLOW}Menjalankan setup ulang bisa ${RED}OVERWRITE${YELLOW} konfigurasi & akun VPN yang ada.${NC}"
  echo -e "       ${YELLOW}Backup dulu: tar -czf /root/backup-vpn-\$(date +%Y%m%d).tar.gz /etc/xray /etc/nginx /etc/openvpn 2>/dev/null${NC}"
else
  ok "Tidak ada install sebelumnya — fresh install"
fi

# ════════════════════════════════════════════════════════════════
# 13. PERMISSION & EXECUTABLE VALIDATION
# ════════════════════════════════════════════════════════════════
section "13/17 · Permission & Executable Validation"

# Cek script utama executable
for script in setupku.sh slow.sh insshws.sh menu.sh preflight.sh; do
  SCRIPT_PATH="$(dirname "$(readlink -f "$0")")/$script"
  if [[ -f "$SCRIPT_PATH" ]]; then
    if [[ -x "$SCRIPT_PATH" ]]; then
      ok "${WHITE}$script${NC}: executable"
    else
      autofix "chmod +x $script"
      chmod +x "$SCRIPT_PATH" && ok "${WHITE}$script${NC}: permission diperbaiki → executable" || \
        warn "Tidak bisa chmod +x $script"
    fi
  fi
done

# Cek /usr/local/bin writable
if [[ -w /usr/local/bin ]]; then
  ok "/usr/local/bin: ${WHITE}writable${NC}"
else
  fail "/usr/local/bin tidak bisa ditulis — install binary akan gagal"
fi

# Cek /etc/systemd/system writable
if [[ -w /etc/systemd/system ]]; then
  ok "/etc/systemd/system: ${WHITE}writable${NC}"
else
  fail "/etc/systemd/system tidak bisa ditulis — service tidak bisa diinstall"
fi

# ════════════════════════════════════════════════════════════════
# 14. FOLDER PREREQUISITE AUTO-CREATE
# ════════════════════════════════════════════════════════════════
section "14/17 · Folder Prerequisite Auto-Create"

DIRS=(
  "/etc/xray"
  "/var/log/xray"
  "/etc/slowdns"
  "/home/vps/public_html"
  "/var/www/html"
  "/root/akun/vless"
  "/root/akun/vmess"
  "/root/akun/trojan"
  "/root/akun/ssh"
  "/var/lib/scrz-prem"
)

for dir in "${DIRS[@]}"; do
  if [[ -d "$dir" ]]; then
    ok "Dir: ${WHITE}$dir${NC} sudah ada"
  else
    autofix "Membuat direktori: $dir"
    mkdir -p "$dir" && chmod 755 "$dir" && \
      ok "Dir: ${WHITE}$dir${NC} berhasil dibuat" || \
      warn "Gagal membuat $dir"
  fi
done

# ════════════════════════════════════════════════════════════════
# 15. BINARY DEPENDENCY VALIDATION
# ════════════════════════════════════════════════════════════════
section "15/17 · Binary & Library Validation"

# Cek library C
if ldconfig -p 2>/dev/null | grep -q "libssl\|libcrypto"; then
  ok "OpenSSL library: ${WHITE}tersedia${NC}"
else
  warn "OpenSSL library tidak ditemukan — install: apt install libssl-dev"
fi

# Cek badvpn binary (kompatibilitas arch)
BADVPN_PATH="$(dirname "$(readlink -f "$0")")/badvpn/badvpn-udpgw"
if [[ -f "$BADVPN_PATH" ]]; then
  BADVPN_ARCH=$(file "$BADVPN_PATH" 2>/dev/null)
  if echo "$BADVPN_ARCH" | grep -q "x86-64" && [[ "$ARCH" == "x86_64" ]]; then
    ok "badvpn-udpgw: ${WHITE}kompatibel (x86_64)${NC}"
  elif echo "$BADVPN_ARCH" | grep -q "x86-64" && [[ "$ARCH" != "x86_64" ]]; then
    warn "badvpn-udpgw di repo adalah x86_64 tapi VPS Anda adalah $ARCH"
    info "Solusi: download binary yang sesuai arsitektur VPS Anda"
  else
    info "badvpn-udpgw: $BADVPN_ARCH"
  fi
fi

# Cek Python 3 bisa import modul yang dipakai WS proxy
if command -v python3 &>/dev/null; then
  for mod in socket threading select sys time; do
    if python3 -c "import $mod" &>/dev/null 2>&1; then
      ok "Python3 module: ${WHITE}$mod${NC}"
    else
      fail "Python3 module ${WHITE}$mod${NC} tidak bisa diimport"
    fi
  done
fi

# ════════════════════════════════════════════════════════════════
# 16. DOWNLOAD ENDPOINT REACHABILITY TEST
# ════════════════════════════════════════════════════════════════
section "16/17 · Download Endpoint Reachability"

ENDPOINTS=(
  "https://raw.githubusercontent.com/winsdevcltr09/autoInstall-premium/main/setupku.sh|Repo utama"
  "https://github.com/XTLS/Xray-core/releases|Xray Core releases"
  "https://github.com/hidessh/slowdns/releases|SlowDNS releases"
  "https://acme.sh|acme.sh (SSL cert)"
  "https://api.ipify.org|IP detection API"
  "https://ipinfo.io/ip|IP detection fallback"
)

for entry in "${ENDPOINTS[@]}"; do
  url="${entry%%|*}"
  label="${entry##*|}"
  HTTP_CODE=$(timeout 10 curl -s -o /dev/null -w "%{http_code}" \
              --retry 2 --retry-delay 1 "$url" 2>/dev/null)
  if [[ "$HTTP_CODE" =~ ^(200|301|302|307|308)$ ]]; then
    ok "Endpoint ${WHITE}$label${NC}: HTTP $HTTP_CODE"
  else
    warn "Endpoint ${WHITE}$label${NC}: HTTP $HTTP_CODE — download mungkin gagal"
  fi
done

# ════════════════════════════════════════════════════════════════
# 17. VPS ENVIRONMENT SANITY CHECK
# ════════════════════════════════════════════════════════════════
section "17/17 · VPS Environment Sanity"

# Cek hostname
HOSTNAME=$(hostname -f 2>/dev/null || hostname)
ok "Hostname: ${WHITE}$HOSTNAME${NC}"

# Cek /proc/sys/net tersedia (dibutuhkan iptables/sysctl)
if [[ -d /proc/sys/net/ipv4 ]]; then
  ok "/proc/sys/net/ipv4: ${WHITE}tersedia${NC}"
else
  warn "/proc/sys/net/ipv4 tidak tersedia — kernel mungkin stripped (OpenVZ)"
fi

# Cek IP forward
IP_FWD=$(cat /proc/sys/net/ipv4/ip_forward 2>/dev/null || echo "?")
if [[ "$IP_FWD" == "1" ]]; then
  ok "IP forwarding: ${WHITE}aktif${NC}"
else
  autofix "Mengaktifkan IP forwarding..."
  echo 1 > /proc/sys/net/ipv4/ip_forward 2>/dev/null
  grep -q "net.ipv4.ip_forward" /etc/sysctl.conf 2>/dev/null || \
    echo "net.ipv4.ip_forward = 1" >> /etc/sysctl.conf
  sysctl -p -q 2>/dev/null
  ok "IP forwarding diaktifkan"
fi

# Cek apakah systemd-resolved berjalan (konflik dengan DNS port 53)
if systemctl is-active --quiet systemd-resolved 2>/dev/null; then
  RESOLVD_PORT=$(ss -tlnp 2>/dev/null | grep ":53 " || echo "")
  if [[ -n "$RESOLVD_PORT" ]]; then
    warn "systemd-resolved memakai port 53 — bisa konflik dengan SlowDNS"
    info "Solusi: systemctl disable --now systemd-resolved"
  fi
fi

# Cek cron service
if systemctl is-active --quiet cron 2>/dev/null || \
   systemctl is-active --quiet crond 2>/dev/null; then
  ok "Cron service: ${WHITE}berjalan${NC}"
else
  autofix "Mengaktifkan cron..."
  systemctl enable cron 2>/dev/null || systemctl enable crond 2>/dev/null || true
  systemctl start cron 2>/dev/null || systemctl start crond 2>/dev/null || true
  ok "Cron diaktifkan"
fi

# Cek swap (opsional tapi membantu di VPS RAM kecil)
SWAP_MB=$(free -m | awk '/^Swap/ {print $2}')
if [[ $SWAP_MB -gt 0 ]]; then
  ok "Swap: ${WHITE}${SWAP_MB} MB aktif${NC}"
else
  info "Swap: tidak ada — disarankan minimal 512MB untuk VPS dengan RAM < 1GB"
fi

# Cek SELinux / AppArmor
if command -v getenforce &>/dev/null && [[ "$(getenforce 2>/dev/null)" == "Enforcing" ]]; then
  warn "SELinux: ${WHITE}Enforcing${NC} — bisa memblokir layanan VPN"
  info "Solusi: setenforce 0 (sementara) atau sesuaikan SELinux policy"
fi
if command -v aa-status &>/dev/null && aa-status --enabled 2>/dev/null; then
  info "AppArmor: aktif — pantau jika ada layanan yang diblokir"
fi

# ════════════════════════════════════════════════════════════════
# SUMMARY HASIL CHECK
# ════════════════════════════════════════════════════════════════
echo ""
echo -e "${SEP}"
echo -e "  ${BOLD}${WHITE}  RINGKASAN HASIL PREFLIGHT CHECK${NC}"
echo -e "${SEP}"

echo -e "  ${BOLD}OS         :${NC} ${OS_PRETTY:-tidak terdeteksi}"
echo -e "  ${BOLD}Arch       :${NC} $ARCH"
echo -e "  ${BOLD}RAM        :${NC} ${RAM_MB} MB"
echo -e "  ${BOLD}Disk Free  :${NC} ${DISK_FREE_MB} MB"
echo -e "  ${BOLD}IP Publik  :${NC} ${MY_IP:-tidak terdeteksi}"
echo -e "  ${BOLD}Domain     :${NC} ${CHECK_DOMAIN:-belum dikonfigurasi}"
echo ""

if [[ $CRITICAL -eq 0 && $WARNINGS -eq 0 ]]; then
  echo -e "  ${GREEN}${BOLD}✔  SEMUA CHECK LULUS — VPS siap untuk install!${NC}"
  echo -e "  ${GREEN}   Jalankan: bash setupku.sh${NC}"
  EXIT_CODE=0
elif [[ $CRITICAL -eq 0 ]]; then
  echo -e "  ${YELLOW}${BOLD}⚠  $WARNINGS WARNING ditemukan — install bisa dilanjutkan${NC}"
  echo -e "  ${YELLOW}   Review warning di atas sebelum install.${NC}"
  echo -e "  ${GREEN}   Jalankan: bash setupku.sh${NC}"
  EXIT_CODE=2
else
  echo -e "  ${RED}${BOLD}✘  $CRITICAL CRITICAL ERROR — INSTALL DIHENTIKAN!${NC}"
  if [[ $WARNINGS -gt 0 ]]; then
    echo -e "  ${YELLOW}   + $WARNINGS warning tambahan${NC}"
  fi
  echo -e ""
  echo -e "  ${RED}   Perbaiki semua CRITICAL ERROR di atas terlebih dahulu.${NC}"
  echo -e "  ${RED}   Jalankan ulang: bash preflight.sh${NC}"
  EXIT_CODE=1
fi

if [[ $AUTOFIX -gt 0 ]]; then
  echo -e "  ${MAGENTA}   $AUTOFIX item diperbaiki otomatis (auto-fix)${NC}"
fi

echo ""
echo -e "  ${CYAN}Log lengkap: ${WHITE}$LOG_FILE${NC}"
echo -e "${SEP}"
echo ""

log "=== PREFLIGHT END: CRITICAL=$CRITICAL WARNINGS=$WARNINGS AUTOFIX=$AUTOFIX EXIT=$EXIT_CODE ==="
exit $EXIT_CODE
