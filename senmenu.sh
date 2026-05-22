#!/bin/bash
# ================================================================
#   Script Menu Installer - DevCulture XII Store VPN Premium
#   Menginstall semua script manajemen ke /usr/bin
# ================================================================

GITHUB_RAW="https://raw.githubusercontent.com/winsdevcltr09/autoInstall-premium/main"
GREEN='\033[0;32m'
RED='\033[0;31m'
CYAN='\033[0;36m'
NC='\033[0m'
ERRORS=0

OK="[${GREEN}  OK  ${NC}]"
ERR="[${RED} FAIL ${NC}]"

# Install satu file dengan verifikasi
install_file() {
    local src="$1"
    local dest="$2"
    local label="$3"
    local is_exec="${4:-true}"

    if wget -q --timeout=30 --tries=3 -O "${dest}.tmp" "${GITHUB_RAW}/${src}" 2>/dev/null \
       && [[ -s "${dest}.tmp" ]] \
       && ! grep -q "404: Not Found" "${dest}.tmp" 2>/dev/null; then
        mv "${dest}.tmp" "$dest"
        [[ "$is_exec" == "true" ]] && chmod +x "$dest"
        echo -e "  ${OK} ${label}"
    else
        rm -f "${dest}.tmp"
        echo -e "  ${ERR} ${label} — gagal download"
        ((ERRORS++))
    fi
}

echo -e ""
echo -e "${CYAN}▶ Menginstall script menu...${NC}"

# ── Menu Utama ────────────────────────────────────────────────────
install_file "menu.sh"              "/usr/bin/menu"         "Menu Utama"
install_file "usernew.sh"           "/usr/bin/usernew"      "User Management"
install_file "xp.sh"                "/usr/bin/xp"           "Auto Expire Akun"
install_file "changer.sh"           "/usr/bin/changer"      "Port Changer"
install_file "addhost.sh"           "/usr/bin/addhost"      "Add Host/Domain"
install_file "genssl.sh"            "/usr/bin/genssl"       "Generate SSL"
install_file "cf.sh"                "/usr/bin/fix"          "Fix CF/Pointing"
install_file "webmin.sh"            "/usr/bin/wbm"          "Webmin"
install_file "update.sh"            "/usr/bin/updatsc"      "Auto Updater"

# ── Menu Protokol ─────────────────────────────────────────────────
install_file "menu-vmess.sh"        "/usr/bin/menu-vmess"   "Menu VMess"
install_file "menu-ss.sh"           "/usr/bin/menu-ss"      "Menu Shadowsocks"
install_file "menu-trojan.sh"       "/usr/bin/menu-trojan"  "Menu Trojan"
install_file "menu-bckp-github.sh"  "/usr/bin/menu-bckp"   "Menu Backup GitHub"
install_file "menu-backup.sh"       "/usr/bin/menu-backup"  "Menu Backup"

# ── Script Akun ───────────────────────────────────────────────────
install_file "add-ws.sh"            "/usr/bin/add-ws"       "Add VMess WS"
install_file "add-ssws.sh"          "/usr/bin/add-ssws"     "Add Shadowsocks WS"
install_file "add-vless.sh"         "/usr/bin/add-vless"    "Add Vless"
install_file "add-tr.sh"            "/usr/bin/add-tr"       "Add Trojan"
install_file "add-trgo.sh"          "/usr/bin/add-trgo"     "Add Trojan-Go"

# ── Script Sistem ─────────────────────────────────────────────────
install_file "autoreboot.sh"        "/usr/bin/autoreboot"   "Auto Reboot"
install_file "restart.sh"           "/usr/bin/restart"      "Restart Services"
install_file "tendang.sh"           "/usr/bin/tendang"      "Kick User"
install_file "clearlog.sh"          "/usr/bin/clearlog"     "Clear Log"
install_file "log.sh"               "/usr/bin/clog"         "Auto Clear Log"
install_file "running.sh"           "/usr/bin/running"      "Cek Running Services"
install_file "cek-trafik.sh"        "/usr/bin/cek-trafik"   "Cek Trafik"
install_file "speedtes_cli.py"      "/usr/bin/cek-speed"    "Speed Test"
install_file "cek-bandwidth.sh"     "/usr/bin/cek-bandwidth" "Cek Bandwidth"
install_file "ram.sh"               "/usr/bin/cek-ram"      "Cek RAM"
install_file "limit-speed.sh"       "/usr/bin/limit-speed"  "Limit Speed"

# ── File Konfigurasi ─────────────────────────────────────────────
install_file "issue.net"            "/etc/issue.net"        "Banner Login" "false"
install_file "versibasic.txt"       "/root/versi"           "File Versi" "false"

echo ""
if [[ $ERRORS -eq 0 ]]; then
    echo -e "  ${OK} Semua ${GREEN}script berhasil diinstall${NC}"
else
    echo -e "  [${RED} WARN ${NC}] Selesai dengan ${ERRORS} error"
fi
