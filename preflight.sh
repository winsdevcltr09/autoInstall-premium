#!/bin/bash
# ================================================================
#  PREFLIGHT CHECK v2.0 — autoInstall-premium VPN Script
#  DevCulture XII Store VPN Premium
#  Version : 2.0.0
#  Desc    : Fail-fast environment validator. Otomatis dipanggil
#            oleh setupku.sh sebelum install dimulai.
#  Usage   : bash preflight.sh [--domain DOMAIN] [--skip-dns]
#            [--skip-cf] [--json-out FILE] [--called-by-setupku]
#  Idempotent: aman dijalankan berkali-kali
# ================================================================

# ── STRICT MODE dengan graceful error trap ──────────────────────
set -Eeuo pipefail

# Trap ERR: tangkap error tak terduga tanpa membingungkan user
_err_trap() {
  local LINE=$1 CMD=$2
  echo -e "\n${RED:-}[INTERNAL] Unexpected error di baris $LINE: $CMD${NC:-}" >&2
  echo "[INTERNAL ERROR] line=$LINE cmd=$CMD" >> "${LOG_FILE:-/tmp/preflight-err.log}"
  exit 99
}
trap '_err_trap $LINENO "$BASH_COMMAND"' ERR

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
SKIP_CF=false
CALLED_BY_SETUPKU=false
JSON_OUT=""
MY_IP=""

# ── ARGUMENT PARSING ────────────────────────────────────────────
while [[ $# -gt 0 ]]; do
  case "$1" in
    --domain)          DOMAIN_ARG="$2"; shift 2 ;;
    --skip-dns)        SKIP_DNS=true; shift ;;
    --skip-cf)         SKIP_CF=true; shift ;;
    --called-by-setupku) CALLED_BY_SETUPKU=true; shift ;;
    --json-out)        JSON_OUT="$2"; shift 2 ;;
    *)                 shift ;;
  esac
done

# ── HELPER FUNCTIONS ────────────────────────────────────────────
log()     { echo "[$(date '+%H:%M:%S')] $*" >> "$LOG_FILE"; }
ok()      { echo -e "${OK}  $*"; log "OK: $*"; }
warn()    { echo -e "${WARN}  $*"; log "WARN: $*"; WARNINGS=$((WARNINGS+1)); }
fail()    { echo -e "${FAIL}  $*"; log "CRITICAL: $*"; CRITICAL=$((CRITICAL+1)); }
info()    { echo -e "${INFO}  $*"; log "INFO: $*"; }
autofix() { echo -e "${FIX}  $*"; log "AUTOFIX: $*"; AUTOFIX=$((AUTOFIX+1)); }
section() { echo -e "\n${SEP}"; echo -e "  ${BOLD}${WHITE}$*${NC}"; echo -e "${SEP}"; }

# Retry dengan exponential backoff dan timeout per attempt
retry_cmd() {
  local retries=${1:-3} timeout_s=${2:-10} delay=${3:-2}
  shift 3
  local cmd=("$@")
  local i
  for ((i=1; i<=retries; i++)); do
    if timeout "$timeout_s" "${cmd[@]}" &>/dev/null; then
      return 0
    fi
    [[ $i -lt $retries ]] && sleep "$delay" && delay=$((delay*2))
  done
  return 1
}

# HTTP check dengan retry
http_check() {
  local url=$1 retries=${2:-3} timeout_s=${3:-10}
  local code i
  for ((i=1; i<=retries; i++)); do
    code=$(curl -s -o /dev/null -w "%{http_code}" --max-time "$timeout_s" \
           --retry 0 "$url" 2>/dev/null || echo "000")
    if [[ "$code" =~ ^(200|301|302|307|308)$ ]]; then
      echo "$code"; return 0
    fi
    [[ $i -lt $retries ]] && sleep 2
  done
  echo "$code"; return 1
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
echo -e "  ${WHITE}${BOLD}  DevCulture XII — Pre-flight Check v2.0${NC}"
if $CALLED_BY_SETUPKU; then
  echo -e "  ${CYAN}  [dipanggil otomatis oleh setupku.sh]${NC}"
fi
echo -e "  ${CYAN}  Log: ${LOG_FILE}${NC}"
echo -e "${SEP}"
echo ""
log "=== PREFLIGHT v2.0 START $(date) ==="

# ════════════════════════════════════════════════════════════════
# 1. ROOT CHECK
# ════════════════════════════════════════════════════════════════
section "1/18 · Root & Sudo Validation"

if [[ $EUID -ne 0 ]]; then
  fail "Script harus dijalankan sebagai root!"
  echo -e "       ${YELLOW}Solusi: ${WHITE}sudo su -${NC} lalu jalankan ulang."
  echo -e "\n${RED}[STOP] Tidak bisa lanjut tanpa akses root.${NC}"
  exit 1
fi
ok "Berjalan sebagai root (EUID=0)"

command -v sudo &>/dev/null && ok "sudo tersedia" || \
  warn "sudo tidak ditemukan (tidak masalah jika sudah root)"

# ════════════════════════════════════════════════════════════════
# 2. OS & VERSI
# ════════════════════════════════════════════════════════════════
section "2/18 · Deteksi OS & Versi"

OS_ID="unknown"; OS_VER="unknown"; OS_PRETTY="unknown"
if [[ ! -f /etc/os-release ]]; then
  fail "Tidak dapat mendeteksi OS — /etc/os-release tidak ada"
else
  # Gunakan subshell agar tidak mencemari env global
  eval "$(grep -E '^(ID|VERSION_ID|PRETTY_NAME)=' /etc/os-release \
         | sed 's/^/OS_/;s/ID=/ID=/;s/VERSION_ID=/VER=/;s/PRETTY_NAME=/PRETTY=/')" 2>/dev/null || true
  . /etc/os-release
  OS_ID="${ID:-unknown}"; OS_VER="${VERSION_ID:-unknown}"; OS_PRETTY="${PRETTY_NAME:-unknown}"

  case "$OS_ID" in
    ubuntu)
      case "$OS_VER" in
        20.04|22.04|24.04) ok "OS didukung: ${WHITE}$OS_PRETTY${NC}" ;;
        18.04) warn "Ubuntu 18.04 EOL — disarankan upgrade ke 20.04+" ;;
        *)     warn "Ubuntu $OS_VER belum diuji — lanjut dengan risiko sendiri" ;;
      esac ;;
    debian)
      case "$OS_VER" in
        11|12) ok "OS didukung: ${WHITE}$OS_PRETTY${NC}" ;;
        10)    warn "Debian 10 EOL — disarankan upgrade ke 11+" ;;
        *)     warn "Debian $OS_VER belum diuji" ;;
      esac ;;
    *)
      fail "OS tidak didukung: $OS_PRETTY (hanya Ubuntu 20/22/24 & Debian 11/12)"
      ;;
  esac
fi

# ════════════════════════════════════════════════════════════════
# 3. ARSITEKTUR CPU & VIRTUALISASI
# ════════════════════════════════════════════════════════════════
section "3/18 · Arsitektur CPU & Virtualisasi"

ARCH=$(uname -m)
case "$ARCH" in
  x86_64)  ok "Arsitektur: ${WHITE}x86_64 (amd64)${NC}" ;;
  aarch64) ok "Arsitektur: ${WHITE}aarch64 (arm64)${NC}" ;;
  armv7*)  warn "Arsitektur: ${WHITE}ARMv7${NC} — beberapa binary mungkin tidak tersedia" ;;
  *)       fail "Arsitektur tidak dikenal: $ARCH" ;;
esac

VIRT="unknown"
if command -v systemd-detect-virt &>/dev/null; then
  VIRT=$(systemd-detect-virt 2>/dev/null || echo "none")
elif grep -qi "hypervisor" /proc/cpuinfo 2>/dev/null; then
  VIRT="vm"
fi

case "$VIRT" in
  kvm|qemu)   ok "Virtualisasi: ${WHITE}KVM/QEMU${NC} — optimal" ;;
  xen)        ok "Virtualisasi: ${WHITE}Xen${NC}" ;;
  vmware)     ok "Virtualisasi: ${WHITE}VMware${NC}" ;;
  lxc*|openvz) warn "Virtualisasi: ${WHITE}$VIRT${NC} — TUN/TAP dan iptables mungkin terbatas" ;;
  none)       ok "Bare metal / tidak terdeteksi sebagai VM" ;;
  *)          info "Virtualisasi: ${WHITE}$VIRT${NC}" ;;
esac

if [[ -c /dev/net/tun ]]; then
  ok "TUN/TAP device tersedia (/dev/net/tun)"
else
  warn "TUN/TAP device tidak ada — OpenVPN tidak akan bisa berjalan"
  info "Solusi: aktifkan TUN di panel VPS provider Anda"
fi

# ════════════════════════════════════════════════════════════════
# 4. RAM, CPU, DISK
# ════════════════════════════════════════════════════════════════
section "4/18 · Hardware Resources (RAM, CPU, Disk)"

RAM_MB=$(awk '/MemTotal/ {printf "%d", $2/1024}' /proc/meminfo)
if [[ $RAM_MB -ge 512 ]]; then
  ok "RAM: ${WHITE}${RAM_MB} MB${NC} (minimum 512 MB terpenuhi)"
elif [[ $RAM_MB -ge 256 ]]; then
  warn "RAM: ${WHITE}${RAM_MB} MB${NC} — sangat minim, install mungkin lambat"
else
  fail "RAM hanya ${RAM_MB} MB — minimum 256 MB diperlukan"
fi

CPU_CORES=$(nproc 2>/dev/null || grep -c "^processor" /proc/cpuinfo || echo 1)
ok "CPU: ${WHITE}${CPU_CORES} core(s)${NC}"

DISK_FREE_MB=$(df -m / | awk 'NR==2 {print $4}')
if [[ $DISK_FREE_MB -ge 2048 ]]; then
  ok "Disk free: ${WHITE}${DISK_FREE_MB} MB${NC} (minimum 2 GB terpenuhi)"
elif [[ $DISK_FREE_MB -ge 1024 ]]; then
  warn "Disk free: ${WHITE}${DISK_FREE_MB} MB${NC} — agak sempit, pantau selama install"
else
  fail "Disk free hanya ${DISK_FREE_MB} MB — minimum 1 GB diperlukan"
fi

TMP_FREE_MB=$(df -m /tmp | awk 'NR==2 {print $4}')
if [[ $TMP_FREE_MB -ge 100 ]]; then
  ok "/tmp free: ${WHITE}${TMP_FREE_MB} MB${NC}"
else
  warn "/tmp free hanya ${TMP_FREE_MB} MB — mungkin bermasalah saat download"
fi

# ════════════════════════════════════════════════════════════════
# 5. KONEKTIVITAS INTERNET
# ════════════════════════════════════════════════════════════════
section "5/18 · Internet Connectivity"

INTERNET_OK=false
for _host in 8.8.8.8 1.1.1.1 208.67.222.222; do
  if timeout 5 ping -c 1 -W 3 "$_host" &>/dev/null; then
    INTERNET_OK=true
    ok "Internet: terhubung (ping ${_host} berhasil)"
    break
  fi
done
$INTERNET_OK || fail "Tidak ada koneksi internet — cek network VPS Anda"

DNS_OK=false
for _dom in google.com github.com; do
  if timeout 5 getent hosts "$_dom" &>/dev/null 2>&1 || \
     timeout 5 nslookup "$_dom" &>/dev/null 2>&1; then
    DNS_OK=true
    ok "DNS: resolve ${WHITE}${_dom}${NC} berhasil"
    break
  fi
done
if ! $DNS_OK; then
  fail "DNS tidak bekerja"
  autofix "Menambahkan nameserver 8.8.8.8 ke resolv.conf..."
  grep -q "nameserver 8.8.8.8" /etc/resolv.conf 2>/dev/null || \
    echo "nameserver 8.8.8.8" >> /etc/resolv.conf
fi

if http_check "https://github.com" 3 10 &>/dev/null; then
  ok "HTTPS ke github.com: ${WHITE}OK${NC}"
else
  warn "Tidak bisa akses github.com — download mungkin gagal"
fi

# Ambil IP publik VPS dengan retry
for _svc in "https://ipv4.icanhazip.com" "https://api.ipify.org" "https://ipinfo.io/ip"; do
  MY_IP=$(timeout 10 curl -sf --retry 2 --retry-delay 2 "$_svc" 2>/dev/null | tr -d '[:space:]') || true
  if [[ -n "$MY_IP" && "$MY_IP" =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
    ok "IP publik VPS: ${WHITE}${MY_IP}${NC}"
    break
  fi
done
[[ -z "$MY_IP" ]] && { fail "Tidak bisa deteksi IP publik VPS"; MY_IP="unknown"; }

# ════════════════════════════════════════════════════════════════
# 6. KONFLIK PORT
# ════════════════════════════════════════════════════════════════
section "6/18 · Port Conflict Detection"

_check_port() {
  local port=$1 svc=$2 sev=${3:-warn}
  local listening=false
  if ss -tlnp 2>/dev/null | grep -q ":${port} " || \
     ss -ulnp 2>/dev/null | grep -q ":${port} "; then
    listening=true
  fi
  if $listening; then
    local proc
    proc=$(ss -tlnp 2>/dev/null | grep ":${port} " | \
           grep -oP 'users:\(\(".*?"\)' | head -1 || echo "unknown")
    [[ "$sev" == "fail" ]] && \
      fail "Port ${WHITE}${port} (${svc})${NC} dipakai! [$proc]" || \
      warn "Port ${WHITE}${port} (${svc})${NC} dipakai [$proc]"
  else
    ok "Port ${WHITE}${port} (${svc})${NC}: bebas"
  fi
}

_check_port 80   "HTTP/Nginx"       fail
_check_port 443  "HTTPS/Nginx+Xray" fail
_check_port 22   "SSH default"      warn
_check_port 2082 "WS-OpenSSH"       warn
_check_port 8880 "WS-Dropbear"      warn
_check_port 700  "WS-Stunnel"       warn
_check_port 1194 "OpenVPN"          warn
_check_port 109  "Dropbear"         warn
_check_port 2222 "SSH SlowDNS"      warn
_check_port 5300 "SlowDNS UDP"      warn
_check_port 7100 "BadVPN UDPGW"     warn
_check_port 8388 "Shadowsocks"      warn
_check_port 3128 "Squid proxy"      warn
_check_port 53   "DNS/SlowDNS"      warn

# ════════════════════════════════════════════════════════════════
# 7. DEPENDENSI TOOL
# ════════════════════════════════════════════════════════════════
section "7/18 · Dependency & Tool Validation"

MISSING_PKGS=()
_check_tool() {
  local tool=$1 pkg=${2:-$1} crit=${3:-false}
  if command -v "$tool" &>/dev/null; then
    local ver
    ver=$(${tool} --version 2>&1 | head -1 | grep -oP '\d+\.\d+[\.\d]*' | head -1 || echo "")
    ok "${WHITE}${tool}${NC} tersedia${ver:+ (v${ver})}"
  else
    if $crit; then
      fail "${WHITE}${tool}${NC} tidak ditemukan (paket: ${pkg})"
    else
      warn "${WHITE}${tool}${NC} tidak ditemukan (paket: ${pkg})"
    fi
    MISSING_PKGS+=("$pkg")
  fi
}

_check_tool python3  python3          true
_check_tool curl     curl             true
_check_tool wget     wget             true
_check_tool openssl  openssl          true
_check_tool tar      tar              true
_check_tool unzip    unzip            false
_check_tool jq       jq               false
_check_tool crontab  cron             false
_check_tool socat    socat            false
_check_tool netstat  net-tools        false
_check_tool ss       iproute2         false
_check_tool iptables iptables         false
_check_tool lsof     lsof             false
_check_tool bc       bc               false
_check_tool nslookup dnsutils         false

# systemctl
if command -v systemctl &>/dev/null && systemctl --version &>/dev/null 2>&1; then
  ok "${WHITE}systemctl${NC} tersedia (systemd berjalan)"
else
  fail "${WHITE}systemctl${NC} tidak ada — systemd diperlukan"
fi

# Auto-install non-critical yang hilang
if [[ ${#MISSING_PKGS[@]} -gt 0 ]]; then
  SAFE_INSTALL=()
  for _p in "${MISSING_PKGS[@]}"; do
    [[ "$_p" =~ ^(python3|curl|openssl)$ ]] || SAFE_INSTALL+=("$_p")
  done
  if [[ ${#SAFE_INSTALL[@]} -gt 0 ]]; then
    autofix "Auto-install: ${SAFE_INSTALL[*]}"
    apt-get update -qq 2>/dev/null || true
    apt-get install -y -qq "${SAFE_INSTALL[@]}" 2>/dev/null && \
      ok "Auto-install selesai: ${SAFE_INSTALL[*]}" || \
      warn "Auto-install gagal — install manual: apt install ${SAFE_INSTALL[*]}"
  fi
fi

# ════════════════════════════════════════════════════════════════
# 8. APT HEALTH
# ════════════════════════════════════════════════════════════════
section "8/18 · Package Manager Health (apt)"

if ! command -v apt-get &>/dev/null; then
  fail "apt-get tidak ditemukan — bukan sistem Debian/Ubuntu"
else
  APT_ERR=$(apt-get update -qq 2>&1 | grep -iE "^E:|error|failed|unable" | head -3 || true)
  if [[ -z "$APT_ERR" ]]; then
    ok "apt update: ${WHITE}berjalan normal${NC}"
  else
    warn "apt update error: $APT_ERR"
    autofix "Perbaiki dpkg lock..."
    rm -f /var/lib/dpkg/lock-frontend /var/lib/dpkg/lock 2>/dev/null || true
    dpkg --configure -a 2>/dev/null || true
  fi

  if fuser /var/lib/dpkg/lock &>/dev/null 2>&1; then
    warn "apt sedang dipakai proses lain"
  else
    ok "apt lock: tidak terkunci"
  fi
fi

# ════════════════════════════════════════════════════════════════
# 9. FIREWALL
# ════════════════════════════════════════════════════════════════
section "9/18 · Firewall Compatibility"

if command -v iptables &>/dev/null && iptables -L -n &>/dev/null 2>&1; then
  IPRULES=$(iptables -L -n 2>/dev/null | grep -c "^ACCEPT\|^DROP\|^REJECT" || echo 0)
  ok "iptables: ${WHITE}aktif${NC} (${IPRULES} rules)"
else
  warn "iptables tidak tersedia atau tidak bisa list rules"
fi

if command -v ufw &>/dev/null; then
  UFW_ST=$(ufw status 2>/dev/null | head -1 || true)
  if echo "$UFW_ST" | grep -qi "active"; then
    warn "UFW aktif — mungkin konflik dengan iptables rules installer"
    info "Solusi jika ada masalah: ufw disable"
  else
    ok "UFW: ${WHITE}tidak aktif${NC}"
  fi
fi

# ════════════════════════════════════════════════════════════════
# 10. NTP / TIME SYNC
# ════════════════════════════════════════════════════════════════
section "10/18 · Time Sync & NTP"

NTP_SYNCED=false
if command -v timedatectl &>/dev/null; then
  if timedatectl show 2>/dev/null | grep -qiE "NTPSynchronized=yes|Synchronized=yes"; then
    NTP_SYNCED=true
    ok "NTP sinkron: ${WHITE}$(date '+%Y-%m-%d %H:%M:%S %Z')${NC}"
  fi
fi

if ! $NTP_SYNCED; then
  warn "NTP tidak tersinkron — SSL cert bisa gagal jika jam VPS salah"
  autofix "Aktifkan NTP sync..."
  if command -v timedatectl &>/dev/null; then
    timedatectl set-ntp true 2>/dev/null || true
    systemctl restart systemd-timesyncd 2>/dev/null || true
    ok "NTP diaktifkan via systemd-timesyncd"
  elif command -v ntpdate &>/dev/null; then
    ntpdate -u pool.ntp.org 2>/dev/null && ok "NTP sinkron via ntpdate" || \
      warn "ntpdate gagal"
  fi
fi

# ════════════════════════════════════════════════════════════════
# 11. DOMAIN, DNS & CLOUDFLARE VALIDATION
# ════════════════════════════════════════════════════════════════
section "11/18 · Domain, DNS & Cloudflare Validation"

# Baca domain yang sudah dikonfigurasi (jika ada)
CF_DOMAIN="${DOMAIN_ARG:-}"
if [[ -z "$CF_DOMAIN" && -f /etc/xray/domain ]]; then
  CF_DOMAIN=$(cat /etc/xray/domain 2>/dev/null || true)
fi

if [[ -z "$CF_DOMAIN" ]] || $SKIP_DNS; then
  info "Domain belum dikonfigurasi atau validasi DNS dilewati"
  info "Untuk validasi domain: bash preflight.sh --domain yourdomain.com"
else
  info "Validasi domain: ${WHITE}${CF_DOMAIN}${NC}"

  # ── A. Resolve domain ke IP ────────────────────────────────
  DOMAIN_IP=""
  # Coba getent dulu, fallback ke nslookup, fallback ke dig
  DOMAIN_IP=$(getent hosts "$CF_DOMAIN" 2>/dev/null | awk '{print $1}' | head -1 || true)
  if [[ -z "$DOMAIN_IP" ]]; then
    DOMAIN_IP=$(nslookup "$CF_DOMAIN" 2>/dev/null | \
                awk '/^Address: /{print $2}' | grep -v "#" | head -1 || true)
  fi
  if [[ -z "$DOMAIN_IP" ]]; then
    DOMAIN_IP=$(dig +short "$CF_DOMAIN" A 2>/dev/null | grep -oP '^\d+\.\d+\.\d+\.\d+$' | head -1 || true)
  fi

  if [[ -z "$DOMAIN_IP" ]]; then
    fail "DNS: ${WHITE}${CF_DOMAIN}${NC} tidak bisa di-resolve"
    info "Solusi: set A record domain ke ${MY_IP} dan tunggu propagasi DNS (5-60 menit)"
  else
    ok "DNS resolve: ${WHITE}${CF_DOMAIN}${NC} → ${DOMAIN_IP}"

    # ── B. Bandingkan IP domain vs IP VPS ─────────────────
    if [[ "$MY_IP" != "unknown" ]]; then
      if [[ "$DOMAIN_IP" == "$MY_IP" ]]; then
        ok "DNS pointing: ${WHITE}${CF_DOMAIN}${NC} (${DOMAIN_IP}) = IP VPS (${MY_IP}) ✓"
      else
        # Mungkin lewat Cloudflare proxy (orange cloud) — cek IP range CF
        # Cloudflare IP ranges yang umum
        CF_RANGES=(
          "104.16." "104.17." "104.18." "104.19." "104.20." "104.21."
          "172.64." "172.65." "172.66." "172.67." "172.68." "172.69."
          "172.70." "172.71." "188.114." "190.93." "197.234." "198.41."
          "162.158." "141.101." "108.162." "103.21." "103.22." "103.31."
        )
        IS_CF_IP=false
        for _range in "${CF_RANGES[@]}"; do
          if [[ "$DOMAIN_IP" == "${_range}"* ]]; then
            IS_CF_IP=true
            break
          fi
        done

        if $IS_CF_IP; then
          # ── C. Cloudflare Proxy (Orange Cloud) Detection ──
          if $SKIP_CF; then
            warn "Cloudflare orange cloud terdeteksi — validasi CF dilewati (--skip-cf)"
          else
            ok "Cloudflare proxy (orange cloud) terdeteksi: ${WHITE}${DOMAIN_IP}${NC}"
            info "Domain melewati Cloudflare CDN — IP asli tersembunyi"

            # Cek apakah CF meneruskan ke IP VPS via DNS-only check
            # Coba ambil real IP lewat endpoint yang tidak lewat CF proxy
            # (misalnya TTL Cloudflare biasanya 300 untuk orange-cloud)
            CF_TTL=$(nslookup "$CF_DOMAIN" 8.8.8.8 2>/dev/null | grep "TTL" | \
                     grep -oP 'ttl = \d+' | grep -oP '\d+' | head -1 || true)
            if [[ -z "$CF_TTL" ]]; then
              CF_TTL=$(dig "$CF_DOMAIN" +noall +answer 2>/dev/null | awk '{print $2}' | head -1 || true)
            fi

            if [[ -n "$CF_TTL" && "$CF_TTL" -le 300 ]]; then
              ok "CF TTL: ${WHITE}${CF_TTL}s${NC} — sesuai Cloudflare proxy"
            fi

            # Periksa header CF via HTTPS
            CF_HEADER=$(curl -sI --max-time 10 "https://${CF_DOMAIN}" 2>/dev/null | \
                        grep -i "cf-ray\|server: cloudflare" | head -1 || true)
            if [[ -n "$CF_HEADER" ]]; then
              ok "Cloudflare header terdeteksi: ${WHITE}OK${NC}"
            fi

            warn "Cloudflare proxy aktif — pastikan mode 'Full' atau 'Full (Strict)' di CF SSL"
            warn "Port 80/443 harus bisa diakses dari Cloudflare untuk SSL provisioning"
            info "Jika pakai Xray/Nginx di belakang CF, pastikan 'Authenticated Origin Pulls' dioff"
          fi
        else
          # IP domain bukan CF dan bukan IP VPS — ini masalah!
          echo ""
          echo -e "  ${RED}${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
          echo -e "  ${RED}${BOLD}  [CRITICAL] DOMAIN TIDAK MENGARAH KE VPS INI!${NC}"
          echo -e "  ${RED}${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
          echo -e ""
          echo -e "  ${WHITE}  Detected VPS IP  :${NC} ${GREEN}${MY_IP}${NC}"
          echo -e "  ${WHITE}  Resolved Domain IP:${NC} ${RED}${DOMAIN_IP}${NC}"
          echo -e ""
          echo -e "  ${YELLOW}  Domain: ${WHITE}${CF_DOMAIN}${NC}"
          echo -e "  ${YELLOW}  Penyebab kemungkinan:${NC}"
          echo -e "     ${YELLOW}• A record domain belum diset ke IP VPS${NC}"
          echo -e "     ${YELLOW}• DNS belum propagasi (tunggu 5-60 menit)${NC}"
          echo -e "     ${YELLOW}• Domain masih pointing ke server lain${NC}"
          echo -e ""
          echo -e "  ${WHITE}  Solusi:${NC}"
          echo -e "     ${CYAN}1. Buka panel DNS domain Anda${NC}"
          echo -e "     ${CYAN}2. Set A record: ${WHITE}${CF_DOMAIN}${CYAN} → ${WHITE}${MY_IP}${NC}"
          echo -e "     ${CYAN}3. Tunggu propagasi, lalu jalankan ulang preflight${NC}"
          echo -e ""
          fail "Domain ${CF_DOMAIN} (${DOMAIN_IP}) tidak pointing ke VPS ini (${MY_IP})"
        fi
      fi
    fi

    # ── D. SSL Readiness Sanity ────────────────────────────
    info "Cek SSL readiness untuk ${CF_DOMAIN}..."
    SSL_RESP=$(timeout 10 curl -sk --max-time 10 \
               "https://${CF_DOMAIN}" -o /dev/null -w "%{http_code}" 2>/dev/null || echo "000")
    if [[ "$SSL_RESP" =~ ^(200|301|302|400|404|502|503)$ ]]; then
      ok "Port 443 dapat diakses dari ${CF_DOMAIN}: HTTP ${SSL_RESP}"
    else
      # Coba port 80
      HTTP_RESP=$(timeout 10 curl -s --max-time 10 \
                  "http://${CF_DOMAIN}" -o /dev/null -w "%{http_code}" 2>/dev/null || echo "000")
      if [[ "$HTTP_RESP" =~ ^(200|301|302|400|404)$ ]]; then
        ok "Port 80 dapat diakses dari ${CF_DOMAIN}: HTTP ${HTTP_RESP}"
      else
        info "Port 80/443 belum aktif di ${CF_DOMAIN} (normal sebelum install Nginx)"
      fi
    fi
  fi
fi

# ════════════════════════════════════════════════════════════════
# 12. DETEKSI INSTALL YANG SUDAH ADA
# ════════════════════════════════════════════════════════════════
section "12/18 · Existing Installation Detection (Rerun Safety)"

EXISTING_INSTALL=false
_chk_exist() {
  local path=$1 desc=$2
  if [[ -e "$path" ]]; then
    warn "Sudah ada: ${WHITE}${desc}${NC} (${path})"
    EXISTING_INSTALL=true
  fi
}

_chk_exist /etc/xray/config.json       "Xray config"
_chk_exist /usr/bin/xray               "Xray binary"
_chk_exist /etc/nginx/conf.d/xray.conf "Nginx Xray config"
_chk_exist /etc/slowdns                "SlowDNS install dir"
_chk_exist /usr/local/bin/ws-openssh   "WS-OpenSSH proxy"
_chk_exist /usr/local/bin/ws-dropbear  "WS-Dropbear proxy"
_chk_exist /usr/sbin/dropbear          "Dropbear SSH"
_chk_exist /etc/openvpn                "OpenVPN config dir"
_chk_exist /root/log-install.txt       "Log install sebelumnya"

if $EXISTING_INSTALL; then
  warn "Install sebelumnya terdeteksi — reinstall akan OVERWRITE config & akun VPN!"
  info "Backup dulu: tar -czf /root/backup-vpn-\$(date +%Y%m%d).tar.gz /etc/xray /etc/nginx"
else
  ok "Tidak ada install sebelumnya — fresh install bersih"
fi

# ════════════════════════════════════════════════════════════════
# 13. PERMISSION & EXECUTABLE
# ════════════════════════════════════════════════════════════════
section "13/18 · Permission & Executable Validation"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
for _sc in setupku.sh preflight.sh slow.sh insshws.sh menu.sh; do
  _sp="${SCRIPT_DIR}/${_sc}"
  if [[ -f "$_sp" ]]; then
    if [[ -x "$_sp" ]]; then
      ok "${WHITE}${_sc}${NC}: executable"
    else
      autofix "chmod +x ${_sc}"
      chmod +x "$_sp" && ok "${WHITE}${_sc}${NC}: permission diperbaiki" || \
        warn "Tidak bisa chmod +x ${_sc}"
    fi
  fi
done

[[ -w /usr/local/bin ]] && ok "/usr/local/bin: ${WHITE}writable${NC}" || \
  fail "/usr/local/bin tidak bisa ditulis — install binary akan gagal"

[[ -w /etc/systemd/system ]] && ok "/etc/systemd/system: ${WHITE}writable${NC}" || \
  fail "/etc/systemd/system tidak bisa ditulis — service tidak bisa diinstall"

# ════════════════════════════════════════════════════════════════
# 14. FOLDER PREREQUISITE AUTO-CREATE
# ════════════════════════════════════════════════════════════════
section "14/18 · Folder Prerequisites"

PREREQ_DIRS=(
  "/etc/xray" "/var/log/xray" "/etc/slowdns"
  "/home/vps/public_html" "/var/www/html"
  "/root/akun/vless" "/root/akun/vmess"
  "/root/akun/trojan" "/root/akun/ssh"
  "/root/backup" "/var/lib/scrz-prem"
)

for _dir in "${PREREQ_DIRS[@]}"; do
  if [[ -d "$_dir" ]]; then
    ok "Dir: ${WHITE}${_dir}${NC} sudah ada"
  else
    autofix "Membuat: ${_dir}"
    mkdir -p "$_dir" && chmod 755 "$_dir" && \
      ok "Dir: ${WHITE}${_dir}${NC} berhasil dibuat" || \
      warn "Gagal membuat ${_dir}"
  fi
done

# ════════════════════════════════════════════════════════════════
# 15. BINARY & LIBRARY VALIDATION
# ════════════════════════════════════════════════════════════════
section "15/18 · Binary & Library Validation"

ldconfig -p 2>/dev/null | grep -q "libssl\|libcrypto" && \
  ok "OpenSSL library: ${WHITE}tersedia${NC}" || \
  warn "OpenSSL library tidak ditemukan — install: apt install libssl-dev"

if command -v python3 &>/dev/null; then
  FAILED_MODS=()
  for _mod in socket threading select sys time; do
    python3 -c "import ${_mod}" 2>/dev/null && \
      ok "Python3 module: ${WHITE}${_mod}${NC}" || \
      { fail "Python3 module ${WHITE}${_mod}${NC} tidak bisa diimport"; FAILED_MODS+=("$_mod"); }
  done
fi

# ════════════════════════════════════════════════════════════════
# 16. DOWNLOAD ENDPOINT REACHABILITY
# ════════════════════════════════════════════════════════════════
section "16/18 · Download Endpoint Reachability"

declare -A ENDPOINTS=(
  ["Repo utama (setupku.sh)"]="https://raw.githubusercontent.com/winsdevcltr09/autoInstall-premium/main/setupku.sh"
  ["Xray Core releases"]="https://github.com/XTLS/Xray-core/releases"
  ["acme.sh (SSL cert)"]="https://acme.sh"
  ["IP detection API"]="https://api.ipify.org"
  ["icanhazip"]="https://ipv4.icanhazip.com"
)

for _label in "${!ENDPOINTS[@]}"; do
  _url="${ENDPOINTS[$_label]}"
  _code=$(http_check "$_url" 2 10 || echo "000")
  if [[ "$_code" =~ ^(200|301|302|307|308)$ ]]; then
    ok "Endpoint ${WHITE}${_label}${NC}: HTTP ${_code}"
  else
    warn "Endpoint ${WHITE}${_label}${NC}: HTTP ${_code} — download mungkin lambat/gagal"
  fi
done

# ════════════════════════════════════════════════════════════════
# 17. SERVICE CONFLICT CHECK
# ════════════════════════════════════════════════════════════════
section "17/18 · Service Conflict Detection"

_chk_svc() {
  local svc=$1 desc=$2
  if systemctl is-active --quiet "$svc" 2>/dev/null; then
    warn "Service ${WHITE}${svc}${NC} (${desc}) sudah berjalan — mungkin konflik"
  else
    ok "Service ${WHITE}${svc}${NC}: tidak aktif (aman)"
  fi
}

_chk_svc nginx        "Web server (akan diinstall ulang)"
_chk_svc apache2      "Web server konflik"
_chk_svc openvpn      "OpenVPN (akan dikonfigurasi ulang)"
_chk_svc xray         "Xray (akan diinstall ulang)"

# Cek systemd-resolved di port 53
if systemctl is-active --quiet systemd-resolved 2>/dev/null; then
  if ss -ulnp 2>/dev/null | grep -q ":53 "; then
    warn "systemd-resolved memakai port 53 — bisa konflik dengan SlowDNS"
    info "Solusi: systemctl disable --now systemd-resolved"
  fi
fi

# ════════════════════════════════════════════════════════════════
# 18. VPS ENVIRONMENT SANITY
# ════════════════════════════════════════════════════════════════
section "18/18 · VPS Environment Sanity"

ok "Hostname: ${WHITE}$(hostname -f 2>/dev/null || hostname)${NC}"

[[ -d /proc/sys/net/ipv4 ]] && ok "/proc/sys/net/ipv4: ${WHITE}tersedia${NC}" || \
  warn "/proc/sys/net/ipv4 tidak ada — kernel mungkin terbatas (OpenVZ)"

# IP forwarding
IP_FWD=$(cat /proc/sys/net/ipv4/ip_forward 2>/dev/null || echo "0")
if [[ "$IP_FWD" == "1" ]]; then
  ok "IP forwarding: ${WHITE}aktif${NC}"
else
  autofix "Aktifkan IP forwarding..."
  echo 1 > /proc/sys/net/ipv4/ip_forward 2>/dev/null || true
  grep -q "net.ipv4.ip_forward" /etc/sysctl.conf 2>/dev/null || \
    echo "net.ipv4.ip_forward = 1" >> /etc/sysctl.conf
  sysctl -p -q 2>/dev/null || true
  ok "IP forwarding diaktifkan"
fi

# Cron
if systemctl is-active --quiet cron 2>/dev/null || \
   systemctl is-active --quiet crond 2>/dev/null; then
  ok "Cron service: ${WHITE}berjalan${NC}"
else
  autofix "Aktifkan cron..."
  systemctl enable cron 2>/dev/null || systemctl enable crond 2>/dev/null || true
  systemctl start cron 2>/dev/null || systemctl start crond 2>/dev/null || true
  ok "Cron diaktifkan"
fi

SWAP_MB=$(free -m | awk '/^Swap/ {print $2}')
if [[ $SWAP_MB -gt 0 ]]; then
  ok "Swap: ${WHITE}${SWAP_MB} MB aktif${NC}"
else
  info "Swap tidak ada — disarankan 512MB untuk VPS RAM < 1GB"
fi

# SELinux / AppArmor
if command -v getenforce &>/dev/null && [[ "$(getenforce 2>/dev/null || true)" == "Enforcing" ]]; then
  warn "SELinux Enforcing — bisa blokir layanan VPN"
fi
if command -v aa-status &>/dev/null && aa-status --enabled 2>/dev/null; then
  info "AppArmor aktif — pantau jika layanan diblokir"
fi

# ════════════════════════════════════════════════════════════════
# SUMMARY
# ════════════════════════════════════════════════════════════════
echo ""
echo -e "${SEP}"
echo -e "  ${BOLD}${WHITE}  RINGKASAN PREFLIGHT CHECK v2.0${NC}"
echo -e "${SEP}"
echo -e "  ${BOLD}OS         :${NC} ${OS_PRETTY}"
echo -e "  ${BOLD}Arch       :${NC} ${ARCH}"
echo -e "  ${BOLD}RAM        :${NC} ${RAM_MB} MB"
echo -e "  ${BOLD}Disk Free  :${NC} ${DISK_FREE_MB} MB"
echo -e "  ${BOLD}IP Publik  :${NC} ${MY_IP}"
echo -e "  ${BOLD}Domain     :${NC} ${CF_DOMAIN:-belum dikonfigurasi}"
echo ""

EXIT_CODE=0
if [[ $CRITICAL -eq 0 && $WARNINGS -eq 0 ]]; then
  echo -e "  ${GREEN}${BOLD}✔  SEMUA CHECK LULUS — VPS siap untuk install!${NC}"
  EXIT_CODE=0
elif [[ $CRITICAL -eq 0 ]]; then
  echo -e "  ${YELLOW}${BOLD}⚠  ${WARNINGS} WARNING — install bisa dilanjutkan${NC}"
  echo -e "  ${YELLOW}   Review warning di atas. Lanjut dengan: bash setupku.sh${NC}"
  EXIT_CODE=2
else
  echo -e "  ${RED}${BOLD}✘  ${CRITICAL} CRITICAL ERROR — INSTALL DIHENTIKAN!${NC}"
  [[ $WARNINGS -gt 0 ]] && echo -e "  ${YELLOW}   + ${WARNINGS} warning tambahan${NC}"
  echo -e ""
  echo -e "  ${RED}   Perbaiki semua CRITICAL ERROR di atas terlebih dahulu.${NC}"
  echo -e "  ${RED}   Jalankan ulang: bash preflight.sh --domain yourdomain.com${NC}"
  EXIT_CODE=1
fi

[[ $AUTOFIX -gt 0 ]] && echo -e "  ${MAGENTA}   ${AUTOFIX} item diperbaiki otomatis${NC}"
echo ""
echo -e "  ${CYAN}Log: ${WHITE}${LOG_FILE}${NC}"
echo -e "${SEP}"
echo ""

# Tulis JSON output jika diminta (untuk integrasi setupku.sh)
if [[ -n "$JSON_OUT" ]]; then
  cat > "$JSON_OUT" << JSONEOF
{
  "critical": ${CRITICAL},
  "warnings": ${WARNINGS},
  "autofix": ${AUTOFIX},
  "exit_code": ${EXIT_CODE},
  "os": "${OS_PRETTY}",
  "ip": "${MY_IP}",
  "domain": "${CF_DOMAIN:-}",
  "log": "${LOG_FILE}"
}
JSONEOF
fi

log "=== PREFLIGHT END: CRITICAL=${CRITICAL} WARNINGS=${WARNINGS} AUTOFIX=${AUTOFIX} EXIT=${EXIT_CODE} ==="
exit $EXIT_CODE
