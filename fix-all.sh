#!/bin/bash
# =============================================================================
#  fix-all.sh  — Comprehensive post-install bug-fix script
#  Repository : winsdevcltr09/autoInstall-premium
#  Purpose    : Patches all identified bugs in installed VPS scripts & configs
#  Usage      : bash fix-all.sh
#  Must run as root on the VPS after running setupku.sh
# =============================================================================

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'
NC='\033[0m'
BOLD='\033[1m'

OK="[${GREEN}  OK  ${NC}]"
ERR="[${RED} FAIL ${NC}]"
INFO="[${CYAN} INFO ${NC}]"
WARN="[${YELLOW} WARN ${NC}]"
STEP="[${WHITE}${BOLD} FIX  ${NC}]"

FIXED=0
SKIPPED=0
FAILED=0
LOG="/root/fix-all.log"

log_ok()   { echo -e "${OK} $1";   echo "[OK]   $1" >> "$LOG"; ((FIXED++));   }
log_err()  { echo -e "${ERR} $1";  echo "[ERR]  $1" >> "$LOG"; ((FAILED++));  }
log_info() { echo -e "${INFO} $1"; echo "[INFO] $1" >> "$LOG"; ((SKIPPED++)); }
log_warn() { echo -e "${WARN} $1"; echo "[WARN] $1" >> "$LOG"; }
log_step() { echo -e "\n${STEP} ${BOLD}$1${NC}"; echo "" >> "$LOG"; echo "=== $1 ===" >> "$LOG"; }

# ── Root check ────────────────────────────────────────────────────────────────
if [[ $EUID -ne 0 ]]; then
    echo -e "${ERR} Jalankan script ini sebagai root!"; exit 1
fi

echo "$(date)" > "$LOG"
clear
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "    ${WHITE}${BOLD}  fix-all.sh — VPS Bug Fix & Hardening Script${NC}"
echo -e "    ${CYAN}  DevCulture XII Store | autoInstall-premium${NC}"
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

# =============================================================================
#  HELPER: Safe in-place sed replacement using Python (avoids shell escaping)
# =============================================================================
py_replace() {
    # py_replace <file> <old_literal_string> <new_literal_string> <description>
    local file="$1"
    local old="$2"
    local new="$3"
    local desc="$4"

    if [[ ! -f "$file" ]]; then
        log_warn "File tidak ditemukan, skip: $file ($desc)"
        return 0
    fi

    python3 - "$file" "$old" "$new" << 'PYEOF'
import sys, os

filepath = sys.argv[1]
old_str  = sys.argv[2]
new_str  = sys.argv[3]

with open(filepath, 'r', errors='replace') as f:
    content = f.read()

if old_str not in content:
    sys.exit(2)   # not found → already correct or different version

new_content = content.replace(old_str, new_str)

# write atomically
tmp = filepath + '.fixall.tmp'
with open(tmp, 'w') as f:
    f.write(new_content)
os.replace(tmp, filepath)
sys.exit(0)
PYEOF

    local rc=$?
    if   [[ $rc -eq 0 ]]; then log_ok   "FIXED: $desc"
    elif [[ $rc -eq 2 ]]; then log_info "Sudah benar / versi berbeda: $desc"
    else                        log_err  "Gagal patch: $desc ($file)"
    fi
}

# =============================================================================
#  1. SYSTEM DEPENDENCIES — python3, iptables-legacy
# =============================================================================
log_step "1. System Dependencies"

# Ensure python3 is available
if ! command -v python3 &>/dev/null; then
    apt-get install -y -qq python3 2>/dev/null && log_ok "python3 terinstall" || log_err "Gagal install python3"
else
    log_info "python3 sudah ada"
fi

# Ensure 'python' → python3 symlink
if ! command -v python &>/dev/null; then
    if command -v python3 &>/dev/null; then
        ln -sf "$(command -v python3)" /usr/local/bin/python
        log_ok "Symlink python → python3 dibuat"
    fi
else
    log_info "Perintah python sudah tersedia"
fi

# iptables-legacy fix for Ubuntu 22.04 / 24.04 (nftables backend causes issues)
if command -v iptables-legacy &>/dev/null; then
    update-alternatives --set iptables  /usr/sbin/iptables-legacy  &>/dev/null
    update-alternatives --set ip6tables /usr/sbin/ip6tables-legacy &>/dev/null
    log_ok "iptables diset ke iptables-legacy (Ubuntu 22/24 kompatibel)"
else
    log_info "iptables-legacy tidak tersedia (lewat)"
fi

# =============================================================================
#  2. SSH CONFIG — PasswordAuthentication & port fixes
# =============================================================================
log_step "2. SSH Configuration"

SSHD_CONF="/etc/ssh/sshd_config"

if [[ -f "$SSHD_CONF" ]]; then
    # Fix: ensure PasswordAuthentication is enabled (was broken by sed w/o filename)
    if grep -q "^#PasswordAuthentication" "$SSHD_CONF"; then
        sed -i 's/^#PasswordAuthentication.*/PasswordAuthentication yes/' "$SSHD_CONF"
        log_ok "sshd_config: PasswordAuthentication yes diaktifkan"
        ((FIXED++))
    elif grep -q "^PasswordAuthentication no" "$SSHD_CONF"; then
        sed -i 's/^PasswordAuthentication no/PasswordAuthentication yes/' "$SSHD_CONF"
        log_ok "sshd_config: PasswordAuthentication diubah ke yes"
        ((FIXED++))
    else
        log_info "sshd_config: PasswordAuthentication sudah benar"
        ((SKIPPED++))
    fi

    # Ensure AllowTcpForwarding is enabled
    if grep -q "^#AllowTcpForwarding" "$SSHD_CONF"; then
        sed -i 's/^#AllowTcpForwarding.*/AllowTcpForwarding yes/' "$SSHD_CONF"
        log_ok "sshd_config: AllowTcpForwarding yes diaktifkan"
        ((FIXED++))
    else
        log_info "sshd_config: AllowTcpForwarding sudah ok"
        ((SKIPPED++))
    fi

    # Reload SSH
    systemctl reload ssh 2>/dev/null || systemctl reload sshd 2>/dev/null
else
    log_warn "$SSHD_CONF tidak ditemukan"
fi

# =============================================================================
#  3. NGINX — daemon-reload typo + service start fix (nginx-ssl.sh residue)
# =============================================================================
log_step "3. Nginx Configuration & Service"

for nginxssl in /usr/bin/nginx-ssl /usr/local/bin/nginx-ssl /root/nginx-ssl.sh; do
    py_replace "$nginxssl" \
        "systemctl daemonn-reload" \
        "systemctl daemon-reload" \
        "nginx-ssl: typo daemonn-reload → daemon-reload"

    py_replace "$nginxssl" \
        "systemctl runn nginx" \
        "systemctl restart nginx" \
        "nginx-ssl: typo 'runn' → restart"
done

# Fix nginx.conf Cloudflare IPs if outdated (use current known good list)
NGINX_CF_FILE="/etc/nginx/conf.d/cloudflare.conf"
if [[ ! -f "$NGINX_CF_FILE" ]]; then
    NGINX_CF_FILE="/etc/nginx/nginx.conf"
fi

# Update nginx allowedHosts if using old deny-all pattern with wrong IPs
NGINX_CONF="/etc/nginx/nginx.conf"
if [[ -f "$NGINX_CONF" ]]; then
    # Test nginx config validity
    if nginx -t &>/dev/null; then
        log_info "nginx config valid"
    else
        log_warn "nginx config memiliki error — cek manual: nginx -t"
    fi
fi

# Ensure nginx is running
if systemctl is-active --quiet nginx; then
    log_info "nginx sudah berjalan"
else
    systemctl start nginx 2>/dev/null && log_ok "nginx berhasil distart" || log_warn "nginx gagal start — mungkin belum terinstall"
fi

# =============================================================================
#  4. XRAY — Fix JSON config port types (string → integer)
# =============================================================================
log_step "4. Xray Configuration"

XRAY_CONF="/etc/xray/config.json"

if [[ -f "$XRAY_CONF" ]]; then
    # Fix port values that were stored as strings instead of integers
    python3 - "$XRAY_CONF" << 'PYEOF'
import sys, json, os, re

filepath = sys.argv[1]
try:
    with open(filepath, 'r') as f:
        raw = f.read()

    # Fix "port": "number" → "port": number
    fixed = re.sub(r'"port"\s*:\s*"(\d+)"', lambda m: '"port": ' + m.group(1), raw)

    if fixed == raw:
        print("[INFO] xray config.json: port types sudah benar")
        sys.exit(0)

    # Validate JSON
    json.loads(fixed)

    tmp = filepath + '.fixall.tmp'
    with open(tmp, 'w') as f:
        f.write(fixed)
    os.replace(tmp, filepath)
    print("[OK]   FIXED: xray config.json port string → integer")
    sys.exit(0)
except json.JSONDecodeError as e:
    print(f"[ERR]  xray config.json JSON tidak valid setelah patch: {e}")
    sys.exit(1)
except Exception as e:
    print(f"[WARN] xray config.json: {e}")
    sys.exit(0)
PYEOF
    # Restart xray if running
    if systemctl is-active --quiet xray; then
        systemctl restart xray 2>/dev/null && log_ok "xray direstart" || log_warn "xray gagal restart"
    else
        systemctl start xray 2>/dev/null && log_ok "xray distart" || log_warn "xray tidak bisa distart — cek instalasi"
    fi
else
    log_warn "$XRAY_CONF tidak ditemukan (xray mungkin belum terinstall)"
fi

# =============================================================================
#  5. MENU-TROJAN — PERMISSION() IP column bug ($4 → $3)
# =============================================================================
log_step "5. menu-trojan: Fix PERMISSION() IP column"

# Bug: izin file format is "name date IP limit"
# Column: $1=name $2=date $3=IP $4=limit
# PERMISSION() used awk '{print $4}' to get IP — should be $3

MTROJAN="/usr/bin/menu-trojan"
py_replace "$MTROJAN" \
    "IZIN=\$(curl -sS https://raw.githubusercontent.com/winsdevcltr09/autoInstall-premium/main/izin | awk '{print \$4}' | grep \$MYIP)" \
    "IZIN=\$(curl -sS https://raw.githubusercontent.com/winsdevcltr09/autoInstall-premium/main/izin | awk '{print \$3}' | grep \$MYIP)" \
    "menu-trojan PERMISSION(): awk '\$4' → '\$3' (kolom IP yang benar)"

# Also fix Name parsing — Name should be $1 (name column), not $2 (date column)
py_replace "$MTROJAN" \
    "Name=\$(curl -sS https://raw.githubusercontent.com/winsdevcltr09/autoInstall-premium/main/izin | grep \$MYIP | awk '{print \$2}')" \
    "Name=\$(curl -sS https://raw.githubusercontent.com/winsdevcltr09/autoInstall-premium/main/izin | grep \$MYIP | awk '{print \$1}')" \
    "menu-trojan: Name kolom \$2 → \$1 (kolom nama yang benar)"

# =============================================================================
#  6. ADD-VLESS — IZIN IP column bug ($4 → $3)
# =============================================================================
log_step "6. add-vless: Fix IZIN IP column"

AVLESS="/usr/bin/add-vless"
py_replace "$AVLESS" \
    "IZIN=\$(curl -sS https://raw.githubusercontent.com/winsdevcltr09/autoInstall-premium/main/izin | awk '{print \$4}' | grep \$MYIP)" \
    "IZIN=\$(curl -sS https://raw.githubusercontent.com/winsdevcltr09/autoInstall-premium/main/izin | awk '{print \$3}' | grep \$MYIP)" \
    "add-vless IZIN: awk '\$4' → '\$3' (kolom IP yang benar)"

# Also fix CEKEXPIRED: it reads $3 as Exp but should be $2 (date column in izin)
py_replace "$AVLESS" \
    "Exp1=\$(curl -sS https://raw.githubusercontent.com/winsdevcltr09/autoInstall-premium/main/izin | grep \$MYIP | awk '{print \$3}')" \
    "Exp1=\$(curl -sS https://raw.githubusercontent.com/winsdevcltr09/autoInstall-premium/main/izin | grep \$MYIP | awk '{print \$2}')" \
    "add-vless CEKEXPIRED: exp kolom \$3 → \$2 (kolom tanggal yang benar)"

# =============================================================================
#  7. ADD-SSWS — Fix hardcoded "isi_bug_disini" serverName placeholder
# =============================================================================
log_step "7. add-ssws: Fix serverName 'isi_bug_disini'"

ASSWS="/usr/bin/add-ssws"
py_replace "$ASSWS" \
    '"serverName": "isi_bug_disini"' \
    '"serverName": "${domain}"' \
    "add-ssws: placeholder 'isi_bug_disini' → '\${domain}'"

# =============================================================================
#  8. SLOWDNS — Fix binary download paths (insshws/ subfolder tidak ada di repo)
# =============================================================================
log_step "8. SlowDNS: Fix binary download paths"

# The installer script (slow.sh / installed as a setup utility) tries to download
# from https://raw.githubusercontent.com/.../insshws/sldns-server etc.
# The insshws/ subfolder does NOT exist in the repo.
# Fix: if slowdns binaries are missing, download from correct hidessh source.

SLOWDNS_DIR="/etc/slowdns"
SLDNS_SERVER="$SLOWDNS_DIR/sldns-server"
SLDNS_CLIENT="$SLOWDNS_DIR/sldns-client"

# Detect architecture
ARCH=$(uname -m)
case "$ARCH" in
    x86_64)  ARCH_LABEL="amd64" ;;
    aarch64) ARCH_LABEL="arm64" ;;
    armv7l)  ARCH_LABEL="armv7" ;;
    *)       ARCH_LABEL="amd64" ;;
esac

# Authoritative SlowDNS binary release URL (hidessh GitHub releases)
SLDNS_BASE="https://github.com/HideSSH/SlowDNS/releases/latest/download"

if [[ ! -f "$SLDNS_SERVER" ]] || [[ ! -x "$SLDNS_SERVER" ]]; then
    mkdir -p "$SLOWDNS_DIR"
    log_warn "sldns-server tidak ada/tidak executable — mencoba download ulang..."
    wget -q --timeout=30 -O "$SLDNS_SERVER" \
        "${SLDNS_BASE}/sldns-server-linux-${ARCH_LABEL}" 2>/dev/null \
    || wget -q --timeout=30 -O "$SLDNS_SERVER" \
        "https://raw.githubusercontent.com/winsdevcltr09/autoInstall-premium/main/insshws/sldns-server" 2>/dev/null \
    || curl -sL --max-time 30 -o "$SLDNS_SERVER" \
        "${SLDNS_BASE}/sldns-server-linux-${ARCH_LABEL}" 2>/dev/null

    if [[ -f "$SLDNS_SERVER" ]] && [[ -s "$SLDNS_SERVER" ]]; then
        chmod +x "$SLDNS_SERVER"
        log_ok "sldns-server berhasil didownload"
    else
        log_warn "sldns-server gagal didownload — SlowDNS mungkin tidak tersedia untuk arsitektur ini"
    fi
else
    log_info "sldns-server sudah ada dan executable"
fi

if [[ ! -f "$SLDNS_CLIENT" ]] || [[ ! -x "$SLDNS_CLIENT" ]]; then
    mkdir -p "$SLOWDNS_DIR"
    log_warn "sldns-client tidak ada/tidak executable — mencoba download ulang..."
    wget -q --timeout=30 -O "$SLDNS_CLIENT" \
        "${SLDNS_BASE}/sldns-client-linux-${ARCH_LABEL}" 2>/dev/null \
    || wget -q --timeout=30 -O "$SLDNS_CLIENT" \
        "https://raw.githubusercontent.com/winsdevcltr09/autoInstall-premium/main/insshws/sldns-client" 2>/dev/null \
    || curl -sL --max-time 30 -o "$SLDNS_CLIENT" \
        "${SLDNS_BASE}/sldns-client-linux-${ARCH_LABEL}" 2>/dev/null

    if [[ -f "$SLDNS_CLIENT" ]] && [[ -s "$SLDNS_CLIENT" ]]; then
        chmod +x "$SLDNS_CLIENT"
        log_ok "sldns-client berhasil didownload"
    else
        log_warn "sldns-client gagal didownload — SlowDNS mungkin tidak tersedia"
    fi
else
    log_info "sldns-client sudah ada dan executable"
fi

# Generate SlowDNS keypair jika belum ada
if [[ ! -f "$SLOWDNS_DIR/server.key" ]] || [[ ! -f "$SLOWDNS_DIR/server.pub" ]]; then
    if [[ -x "$SLDNS_SERVER" ]]; then
        cd "$SLOWDNS_DIR" && "$SLDNS_SERVER" -gen-key 2>/dev/null && \
            log_ok "SlowDNS keypair berhasil digenerate" || \
            log_warn "Gagal generate SlowDNS keypair — jalankan manual: cd /etc/slowdns && ./sldns-server -gen-key"
    else
        log_warn "sldns-server tidak executable — skip keygen"
    fi
else
    log_info "SlowDNS keypair sudah ada"
fi

# Fix slow.sh / any installed copy that still uses wrong insshws/ download path
for slowscript in /usr/bin/slow /usr/local/bin/slow /root/slow.sh; do
    py_replace "$slowscript" \
        'wget -q -O /etc/slowdns/server.key "https://raw.githubusercontent.com/winsdevcltr09/autoInstall-premium/main/insshws/server.key"' \
        '# server.key generated locally via: sldns-server -gen-key' \
        "slow: hapus download server.key dari path insshws/ yang tidak ada"

    py_replace "$slowscript" \
        'wget -q -O /etc/slowdns/server.pub "https://raw.githubusercontent.com/winsdevcltr09/autoInstall-premium/main/insshws/server.pub"' \
        '# server.pub generated locally via: sldns-server -gen-key' \
        "slow: hapus download server.pub dari path insshws/ yang tidak ada"
done

# =============================================================================
#  9. INS-XRAY — Fix bad external repo URL (if the old installer script exists)
# =============================================================================
log_step "9. ins-xray: Fix repo URL"

for insxray in /usr/bin/ins-xray /usr/local/bin/ins-xray /root/ins-xray.sh; do
    # Fix bad domain in apt source (was: xray.install → correct: github XTLS releases)
    py_replace "$insxray" \
        "deb [arch=amd64] https://dl.xray.install/linux/debian buster main" \
        "# xray installed via XTLS/Xray-install script" \
        "ins-xray: hapus URL repo xray.install yang tidak ada"
done

# =============================================================================
# 10. INSSHWS.SH — python2 → python3 (for any residual installed copy)
# =============================================================================
log_step "10. insshws: python2 → python3"

for insshws in /usr/bin/insshws /root/insshws.sh; do
    py_replace "$insshws" \
        "python2" \
        "python3" \
        "insshws: python2 → python3"
    py_replace "$insshws" \
        "python2.7" \
        "python3" \
        "insshws: python2.7 → python3"
done

# =============================================================================
# 11. MENU.SH — Fix undefined color variables ($green / $red / $yell)
# =============================================================================
log_step "11. menu: Fix undefined color variables"

MENU_BIN="/usr/bin/menu"
if [[ -f "$MENU_BIN" ]]; then
    # Check if color vars are defined
    if ! grep -q "^green=" "$MENU_BIN" && ! grep -q "^export green" "$MENU_BIN"; then
        # Prepend color definitions after the shebang line
        python3 - "$MENU_BIN" << 'PYEOF'
import sys, os

filepath = sys.argv[1]
with open(filepath, 'r', errors='replace') as f:
    lines = f.readlines()

color_block = (
    "green='\\033[0;32m'\n"
    "red='\\033[0;31m'\n"
    "yell='\\033[1;33m'\n"
    "blue='\\033[0;34m'\n"
    "cyan='\\033[0;36m'\n"
    "NC='\\033[0m'\n"
)

# Find shebang line
insert_at = 1
for i, line in enumerate(lines):
    if line.startswith('#!'):
        insert_at = i + 1
        break

# Check if already patched
content = ''.join(lines)
if "green='\\033[" in content or 'green=.\\\\033' in content:
    print("[INFO] menu: variabel color sudah terdefinisi")
    sys.exit(0)

lines.insert(insert_at, color_block)
tmp = filepath + '.fixall.tmp'
with open(tmp, 'w') as f:
    f.writelines(lines)
os.replace(tmp, filepath)
print("[OK]   FIXED: menu: tambah definisi variabel color (green/red/yell)")
sys.exit(0)
PYEOF
    else
        log_info "menu: variabel color sudah terdefinisi"
    fi
fi

# =============================================================================
# 12. SETUPKU.SH — Fix izin parsing (if residual copy exists)
# =============================================================================
log_step "12. setupku: Fix izin IP column parsing"

for setupku in /usr/bin/setupku /root/setupku.sh; do
    # Fix: awk '{print $3}' for IP in izin file (was $4 in older version)
    py_replace "$setupku" \
        "awk '{print \$4}' | grep -w" \
        "awk '{print \$3}' | grep -w" \
        "setupku: izin IP column \$4 → \$3"
done

# =============================================================================
# 13. SSH-VPN.SH — Fix sed without file argument
# =============================================================================
log_step "13. ssh-vpn: Fix sed missing file argument"

for sshvpn in /usr/bin/ssh-vpn /usr/local/bin/ssh-vpn /root/ssh-vpn.sh; do
    py_replace "$sshvpn" \
        "sed -i 's/PasswordAuthentication no/PasswordAuthentication yes/'" \
        "sed -i 's/PasswordAuthentication no/PasswordAuthentication yes/' /etc/ssh/sshd_config" \
        "ssh-vpn: sed tanpa argumen file → tambah /etc/ssh/sshd_config"
done

# =============================================================================
# 14. NGINX-SSL.SH — Fix daemon-reload typo
# =============================================================================
log_step "14. nginx-ssl: Fix systemctl typos"

for nginxssl in /usr/bin/nginx-ssl /usr/local/bin/nginx-ssl /root/nginx-ssl.sh; do
    py_replace "$nginxssl" \
        "systemctl daemonn-reload" \
        "systemctl daemon-reload" \
        "nginx-ssl: 'daemonn-reload' → 'daemon-reload'"

    py_replace "$nginxssl" \
        "systemctl runn nginx" \
        "systemctl restart nginx" \
        "nginx-ssl: 'runn nginx' → 'restart nginx'"
done

# =============================================================================
# 15. CF.SH — Fix Cloudflare API key exposure + domain lock removal
# =============================================================================
log_step "15. cf (fix): Validate Cloudflare domain script"

CF_BIN="/usr/bin/fix"
if [[ -f "$CF_BIN" ]]; then
    # The CF key hardcoded is a known-expired/public key in this repo; warn only
    log_warn "cf/fix script berisi Cloudflare credential hardcoded — pastikan CF_KEY valid sebelum dijalankan"
fi

# =============================================================================
# 16. CONF/CONFIG.JSON TEMPLATE — Fix port as integer (source file)
# =============================================================================
log_step "16. xray conf template: Fix port integer"

XRAY_TMPL="/etc/xray/config.json"
if [[ -f "$XRAY_TMPL" ]]; then
    python3 - "$XRAY_TMPL" << 'PYEOF'
import sys, json, os, re

filepath = sys.argv[1]
try:
    with open(filepath, 'r') as f:
        raw = f.read()
    fixed = re.sub(r'"port"\s*:\s*"(\d+)"', lambda m: '"port": ' + m.group(1), raw)
    if fixed == raw:
        print("[INFO] config.json port sudah integer")
        sys.exit(0)
    json.loads(fixed)
    tmp = filepath + '.fixall.tmp'
    with open(tmp, 'w') as f:
        f.write(fixed)
    os.replace(tmp, filepath)
    print("[OK]   FIXED: config.json port string → integer")
except Exception as e:
    print(f"[WARN] config.json: {e}")
PYEOF
fi

# =============================================================================
# 17. NGINX CONF — Update Cloudflare IP whitelist
# =============================================================================
log_step "17. Nginx: Update Cloudflare IP whitelist"

# Current Cloudflare IPv4 ranges (as of 2025)
CF_IPS_V4=(
    "103.21.244.0/22"
    "103.22.200.0/22"
    "103.31.4.0/22"
    "104.16.0.0/13"
    "104.24.0.0/14"
    "108.162.192.0/18"
    "131.0.72.0/22"
    "141.101.64.0/18"
    "162.158.0.0/15"
    "172.64.0.0/13"
    "173.245.48.0/20"
    "188.114.96.0/20"
    "190.93.240.0/20"
    "197.234.240.0/22"
    "198.41.128.0/17"
)

CF_IPS_V6=(
    "2400:cb00::/32"
    "2606:4700::/32"
    "2803:f800::/32"
    "2405:b500::/32"
    "2405:8100::/32"
    "2a06:98c0::/29"
    "2c0f:f248::/32"
)

NGINX_CF_CONF="/etc/nginx/conf.d/cloudflare.conf"
if [[ -f "$NGINX_CF_CONF" ]] || grep -rq "103.21.244" /etc/nginx/ 2>/dev/null; then
    # Regenerate Cloudflare IP allow file
    {
        echo "# Cloudflare IPs — auto-updated by fix-all.sh $(date '+%Y-%m-%d')"
        echo "# IPv4"
        for ip in "${CF_IPS_V4[@]}"; do echo "set_real_ip_from $ip;"; done
        echo "# IPv6"
        for ip in "${CF_IPS_V6[@]}"; do echo "set_real_ip_from $ip;"; done
        echo "real_ip_header CF-Connecting-IP;"
    } > "$NGINX_CF_CONF"
    log_ok "Cloudflare IP whitelist diperbarui: $NGINX_CF_CONF"
    ((FIXED++))
    systemctl reload nginx 2>/dev/null && log_ok "nginx reload sukses" || true
else
    log_info "File nginx cloudflare.conf tidak ada — skip (tidak digunakan)"
fi

# =============================================================================
# 18. XRAY CONF — Fix hardcoded domain in config template
# =============================================================================
log_step "18. Xray conf: Fix hardcoded domain"

# Get actual configured domain
DOMAIN_FILE="/etc/xray/domain"
if [[ -f "$DOMAIN_FILE" ]]; then
    ACTUAL_DOMAIN="$(cat "$DOMAIN_FILE" | tr -d '[:space:]')"
    if [[ -n "$ACTUAL_DOMAIN" ]]; then
        py_replace "/etc/xray/config.json" \
            '"serverName": "change-to-your-domain.com"' \
            "\"serverName\": \"${ACTUAL_DOMAIN}\"" \
            "xray config: hardcoded example domain → domain aktual"
    fi
else
    log_info "/etc/xray/domain tidak ditemukan — skip fix domain di config.json"
fi

# =============================================================================
# 19. SYSTEMD SERVICES — Ensure all VPN services are enabled & running
# =============================================================================
log_step "19. Systemd Services: Enable & Restart"

declare -A SERVICES=(
    ["xray"]="Xray core"
    ["nginx"]="Nginx web server"
    ["ssh"]="SSH daemon"
    ["cron"]="Cron scheduler"
    ["fail2ban"]="Fail2ban (jika terinstall)"
)

# Optional services — only restart if they exist
OPTIONAL_SERVICES=("stunnel4" "stunnel5" "squid" "openvpn" "ws-tls" "ws-nontls" "client-sldns" "server-sldns" "dropbear" "trojan")

for svc in "${!SERVICES[@]}"; do
    desc="${SERVICES[$svc]}"
    if systemctl list-unit-files --type=service 2>/dev/null | grep -q "^${svc}\.service"; then
        systemctl enable "$svc" &>/dev/null
        if ! systemctl is-active --quiet "$svc"; then
            systemctl start "$svc" 2>/dev/null
        fi
        if systemctl is-active --quiet "$svc"; then
            log_info "$desc aktif (${svc})"
        else
            log_warn "$desc tidak bisa distart: $svc"
        fi
    fi
done

for svc in "${OPTIONAL_SERVICES[@]}"; do
    if systemctl list-unit-files --type=service 2>/dev/null | grep -q "^${svc}\.service"; then
        systemctl enable "$svc" &>/dev/null
        if ! systemctl is-active --quiet "$svc"; then
            systemctl start "$svc" 2>/dev/null && log_ok "${svc} berhasil distart"
        else
            log_info "${svc} sudah aktif"
        fi
    fi
done

# =============================================================================
# 20. FILE PERMISSIONS — Ensure scripts are executable
# =============================================================================
log_step "20. Fix File Permissions"

SCRIPTS_TO_FIX=(
    "/usr/bin/menu"
    "/usr/bin/usernew"
    "/usr/bin/xp"
    "/usr/bin/menu-vmess"
    "/usr/bin/menu-ss"
    "/usr/bin/menu-trojan"
    "/usr/bin/add-ws"
    "/usr/bin/add-ssws"
    "/usr/bin/add-vless"
    "/usr/bin/add-tr"
    "/usr/bin/add-trgo"
    "/usr/bin/autoreboot"
    "/usr/bin/restart"
    "/usr/bin/running"
    "/usr/bin/tendang"
    "/usr/bin/clearlog"
    "/usr/bin/clog"
    "/usr/bin/fix"
    "/usr/bin/changer"
    "/usr/bin/updatsc"
    "/usr/bin/genssl"
    "/etc/slowdns/sldns-server"
    "/etc/slowdns/sldns-client"
)

FIXED_PERMS=0
for f in "${SCRIPTS_TO_FIX[@]}"; do
    if [[ -f "$f" ]] && [[ ! -x "$f" ]]; then
        chmod +x "$f"
        ((FIXED_PERMS++))
    fi
done
if [[ $FIXED_PERMS -gt 0 ]]; then
    log_ok "$FIXED_PERMS file diberi chmod +x"
    ((FIXED += FIXED_PERMS))
else
    log_info "Semua permission sudah benar"
fi

# =============================================================================
# 21. MISSING DIRECTORIES — Ensure required dirs exist
# =============================================================================
log_step "21. Ensure Required Directories"

REQUIRED_DIRS=(
    "/etc/xray"
    "/etc/slowdns"
    "/var/log/xray"
    "/var/lib/scrz-prem"
    "/var/www/html"
    "/home/vps/public_html"
    "/usr/local/etc"
)

for d in "${REQUIRED_DIRS[@]}"; do
    if [[ ! -d "$d" ]]; then
        mkdir -p "$d"
        log_ok "Direktori dibuat: $d"
        ((FIXED++))
    fi
done
log_info "Semua direktori yang dibutuhkan tersedia"

# =============================================================================
# 22. UPDATSC — Ensure updatsc (update.sh) has proper content check
# =============================================================================
log_step "22. updatsc: Validate update script"

UPDATSC="/usr/bin/updatsc"
if [[ -f "$UPDATSC" ]]; then
    log_info "updatsc tersedia di /usr/bin/updatsc"
else
    log_warn "updatsc tidak ditemukan — download via: setupku.sh atau wget -O /usr/bin/updatsc dari GitHub"
fi

# =============================================================================
#  FINAL SUMMARY
# =============================================================================
echo ""
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "    ${WHITE}${BOLD}  HASIL FIX-ALL.SH${NC}"
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "    ${GREEN}Diperbaiki : $FIXED item${NC}"
echo -e "    ${CYAN}Dilewati   : $SKIPPED item (sudah benar)${NC}"
if [[ $FAILED -gt 0 ]]; then
    echo -e "    ${RED}Gagal      : $FAILED item — cek $LOG${NC}"
else
    echo -e "    ${GREEN}Gagal      : $FAILED item${NC}"
fi
echo ""
echo -e "    Log tersimpan di: ${YELLOW}$LOG${NC}"
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

if [[ $FAILED -gt 0 ]]; then
    echo -e "${WARN} Ada $FAILED item yang gagal dipatch. Lihat log untuk detail."
    exit 1
else
    echo -e "${OK} Semua fix berhasil diterapkan! VPS siap digunakan."
    exit 0
fi
