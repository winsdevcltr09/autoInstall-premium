#!/bin/bash
# ================================================================
#   Script Update - DevCulture XII Store VPN Premium
#   Version : 3.0.0 LTS
#   GitHub  : github.com/winsdevcltr09/autoInstall-premium
#   Support : Ubuntu 18.04 / 20.04 / 22.04 | Debian 10 / 11
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

# ── Symbols ──────────────────────────────────────────────────────
OK="[${GREEN}  OK  ${NC}]"
ERR="[${RED} FAIL ${NC}]"
INFO="[${CYAN} INFO ${NC}]"
WARN="[${YELLOW} WARN ${NC}]"

# ── Config ───────────────────────────────────────────────────────
GITHUB_RAW="https://raw.githubusercontent.com/winsdevcltr09/autoInstall-premium/main"
SCRIPT_VERSION="3.0.0"
LOG_FILE="/root/update-log.txt"
TEMP_DIR="/tmp/dcxii-update"
ERRORS=0

# ── Helper Functions ─────────────────────────────────────────────
banner() {
    clear
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "     ${WHITE}${BOLD}   ____  _______  _____ ____    __  ___  ___ ${NC}"
    echo -e "     ${CYAN}  |  _ \\/ ___\\ \\/ /_ _|___ \\  \\ \\/ / ||_ _|${NC}"
    echo -e "     ${CYAN}  | | | | |    \\  / | |  __) |  \\  /   | || ${NC}"
    echo -e "     ${CYAN}  | |_| | |___ /  \\ | | / __/   /  \\   | | ${NC}"
    echo -e "     ${CYAN}  |____/ \\____/_/\\_\\___|_____| /_/\\_\\ |___|${NC}"
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "     ${WHITE}${BOLD}       DevCulture XII Store VPN Premium${NC}"
    echo -e "     ${CYAN}          Auto Update Script v${SCRIPT_VERSION}${NC}"
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
}

log() { echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" >> "$LOG_FILE"; }

check_root() {
    if [[ $EUID -ne 0 ]]; then
        echo -e "${ERR} Script harus dijalankan sebagai ${RED}root${NC}!"
        echo -e "     Gunakan: ${YELLOW}sudo bash update.sh${NC}"
        exit 1
    fi
}

check_os() {
    echo -e "${INFO} Mendeteksi sistem operasi..."
    if [[ -f /etc/os-release ]]; then
        . /etc/os-release
        OS_NAME=$ID
        OS_VERSION=$VERSION_ID
        OS_PRETTY=$PRETTY_NAME
    else
        echo -e "${ERR} Tidak dapat mendeteksi OS. File /etc/os-release tidak ditemukan."
        exit 1
    fi

    case "$OS_NAME" in
        ubuntu)
            case "$OS_VERSION" in
                18.04|20.04|22.04)
                    echo -e "${OK} OS Terdeteksi: ${GREEN}${OS_PRETTY}${NC}"
                    ;;
                *)
                    echo -e "${WARN} Ubuntu ${OS_VERSION} belum diuji penuh. Lanjut dengan risiko sendiri."
                    ;;
            esac
            ;;
        debian)
            case "$OS_VERSION" in
                10|11|12)
                    echo -e "${OK} OS Terdeteksi: ${GREEN}${OS_PRETTY}${NC}"
                    ;;
                *)
                    echo -e "${WARN} Debian ${OS_VERSION} belum diuji. Lanjut dengan risiko sendiri."
                    ;;
            esac
            ;;
        *)
            echo -e "${ERR} OS ${RED}${OS_NAME}${NC} tidak didukung!"
            echo -e "     OS yang didukung: Ubuntu 18.04/20.04/22.04 | Debian 10/11/12"
            exit 1
            ;;
    esac
    log "OS: ${OS_PRETTY}"
}

check_internet() {
    echo -e "${INFO} Memeriksa koneksi internet..."
    if ! ping -c 1 -W 3 8.8.8.8 &>/dev/null && ! ping -c 1 -W 3 1.1.1.1 &>/dev/null; then
        echo -e "${ERR} Tidak ada koneksi internet! Update dibatalkan."
        exit 1
    fi
    if ! curl -s --max-time 10 "https://raw.githubusercontent.com" &>/dev/null; then
        echo -e "${ERR} Tidak bisa mengakses GitHub. Periksa firewall/DNS."
        exit 1
    fi
    echo -e "${OK} Koneksi internet ${GREEN}OK${NC}"
}

check_version() {
    echo -e "${INFO} Memeriksa versi terbaru..."
    LATEST_VER=$(curl -sf --max-time 10 "${GITHUB_RAW}/versibasic.txt" 2>/dev/null | tr -d '[:space:]')
    CURRENT_VER=$(cat /root/versi 2>/dev/null | tr -d '[:space:]' || echo "unknown")

    if [[ -z "$LATEST_VER" ]]; then
        echo -e "${WARN} Tidak bisa mengambil versi terbaru. Melanjutkan update paksa..."
        LATEST_VER="$SCRIPT_VERSION"
    fi

    echo -e "     Versi Terpasang  : ${YELLOW}${CURRENT_VER}${NC}"
    echo -e "     Versi Terbaru    : ${GREEN}${LATEST_VER}${NC}"

    if [[ "$CURRENT_VER" == "$LATEST_VER" ]]; then
        echo -e "${INFO} Script sudah ${GREEN}versi terbaru${NC}. Update tetap dijalankan untuk memastikan."
    else
        echo -e "${INFO} Update tersedia: ${YELLOW}${CURRENT_VER}${NC} → ${GREEN}${LATEST_VER}${NC}"
    fi
    log "Update dari ${CURRENT_VER} ke ${LATEST_VER}"
}

# ── Download dengan verifikasi ────────────────────────────────────
# Usage: dl_script <url_path> <dest> <label>
dl_script() {
    local url_path="$1"
    local dest="$2"
    local label="$3"
    local tmp="${TEMP_DIR}/$(basename ${dest})"

    # Download ke temp dulu
    if wget -q --timeout=30 --tries=3 -O "$tmp" "${GITHUB_RAW}/${url_path}" 2>/dev/null; then
        # Verifikasi file tidak kosong dan bukan halaman 404
        if [[ -s "$tmp" ]] && ! grep -q "404: Not Found\|404 Not Found" "$tmp" 2>/dev/null; then
            mv "$tmp" "$dest"
            chmod +x "$dest" 2>/dev/null
            echo -e "  ${OK} ${label}"
            log "Updated: ${dest}"
            return 0
        else
            echo -e "  ${ERR} ${label} ${RED}(file kosong atau 404)${NC}"
            rm -f "$tmp"
            ((ERRORS++))
            log "FAILED (empty/404): ${url_path}"
            return 1
        fi
    else
        echo -e "  ${ERR} ${label} ${RED}(download gagal)${NC}"
        ((ERRORS++))
        log "FAILED (download): ${url_path}"
        return 1
    fi
}

# ── Update semua script ───────────────────────────────────────────
update_scripts() {
    echo ""
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "     ${WHITE}${BOLD} [1/5] Update Script Utama${NC}"
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

    dl_script "menu.sh"             "/usr/bin/menu"         "Menu Utama"
    dl_script "usernew.sh"          "/usr/bin/usernew"      "User New"
    dl_script "xp.sh"               "/usr/bin/xp"           "Auto Expire"
    dl_script "changer.sh"          "/usr/bin/changer"      "Port Changer"
    dl_script "addhost.sh"          "/usr/bin/addhost"      "Add Host"
    dl_script "genssl.sh"           "/usr/bin/genssl"       "Gen SSL"
    dl_script "cf.sh"               "/usr/bin/fix"          "Fix Pointing"
    dl_script "webmin.sh"           "/usr/bin/wbm"          "Webmin"
    dl_script "update.sh"           "/usr/bin/updatsc"      "Auto Update"

    echo ""
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "     ${WHITE}${BOLD} [2/5] Update Menu Protokol${NC}"
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

    dl_script "menu-vmess.sh"       "/usr/bin/menu-vmess"   "Menu VMess"
    dl_script "menu-ss.sh"          "/usr/bin/menu-ss"      "Menu Shadowsocks"
    dl_script "menu-trojan.sh"      "/usr/bin/menu-trojan"  "Menu Trojan"
    dl_script "menu-bckp-github.sh" "/usr/bin/menu-bckp"   "Menu Backup"
    dl_script "menu-backup.sh"      "/usr/bin/menu-backup"  "Menu Backup Alt"

    echo ""
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "     ${WHITE}${BOLD} [3/5] Update Script Akun${NC}"
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

    dl_script "add-ws.sh"           "/usr/bin/add-ws"       "Add VMess WS"
    dl_script "add-ssws.sh"         "/usr/bin/add-ssws"     "Add Shadowsocks WS"
    dl_script "add-vless.sh"        "/usr/bin/add-vless"    "Add Vless"
    dl_script "add-tr.sh"           "/usr/bin/add-tr"       "Add Trojan"
    dl_script "add-trgo.sh"         "/usr/bin/add-trgo"     "Add Trojan-Go"

    echo ""
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "     ${WHITE}${BOLD} [4/5] Update Script Sistem${NC}"
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

    dl_script "autoreboot.sh"       "/usr/bin/autoreboot"   "Auto Reboot"
    dl_script "restart.sh"          "/usr/bin/restart"      "Restart Service"
    dl_script "tendang.sh"          "/usr/bin/tendang"      "Kick User"
    dl_script "clearlog.sh"         "/usr/bin/clearlog"     "Clear Log"
    dl_script "running.sh"          "/usr/bin/running"      "Cek Running"
    dl_script "cek-trafik.sh"       "/usr/bin/cek-trafik"   "Cek Trafik"
    dl_script "speedtes_cli.py"     "/usr/bin/cek-speed"    "Speedtest"
    dl_script "cek-bandwidth.sh"    "/usr/bin/cek-bandwidth" "Cek Bandwidth"
    dl_script "ram.sh"              "/usr/bin/cek-ram"      "Cek RAM"
    dl_script "limit-speed.sh"      "/usr/bin/limit-speed"  "Limit Speed"
    dl_script "log.sh"              "/usr/bin/clog"         "Clear Log Cron"

    echo ""
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "     ${WHITE}${BOLD} [5/5] Update File Konfigurasi${NC}"
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

    dl_script "issue.net"           "/etc/issue.net"        "Banner Login"
    dl_script "versibasic.txt"      "/root/versi"           "Versi File"

    # Update versi tanpa chmod +x
    LATEST=$(curl -sf --max-time 10 "${GITHUB_RAW}/versibasic.txt" 2>/dev/null | tr -d '[:space:]')
    [[ -n "$LATEST" ]] && echo "$LATEST" > /root/versi
}

# ── Restart services ─────────────────────────────────────────────
restart_services() {
    echo ""
    echo -e "${INFO} Merestart layanan yang diperlukan..."
    local svcs=("ssh" "dropbear" "stunnel4" "nginx" "xray" "cron")
    for svc in "${svcs[@]}"; do
        if systemctl is-active --quiet "$svc" 2>/dev/null; then
            if systemctl restart "$svc" &>/dev/null; then
                echo -e "  ${OK} Restart ${svc}"
            else
                echo -e "  ${WARN} Gagal restart ${svc}"
            fi
        fi
    done
}

# ── Summary ───────────────────────────────────────────────────────
show_summary() {
    local end_time=$(date '+%Y-%m-%d %H:%M:%S')
    echo ""
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    if [[ $ERRORS -eq 0 ]]; then
        echo -e "     ${GREEN}${BOLD} ✓ UPDATE BERHASIL SEMPURNA${NC}"
        echo -e "     ${WHITE} Semua script telah diperbarui ke versi terbaru${NC}"
    else
        echo -e "     ${YELLOW}${BOLD} ⚠ UPDATE SELESAI DENGAN ${ERRORS} ERROR${NC}"
        echo -e "     ${WHITE} Periksa log: ${YELLOW}cat ${LOG_FILE}${NC}"
    fi
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "     ${CYAN}OS       :${NC} ${OS_PRETTY}"
    echo -e "     ${CYAN}Versi    :${NC} $(cat /root/versi 2>/dev/null || echo ${SCRIPT_VERSION})"
    echo -e "     ${CYAN}Waktu    :${NC} ${end_time}"
    echo -e "     ${CYAN}Log      :${NC} ${LOG_FILE}"
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "     ${WHITE}${BOLD} DevCulture XII Store VPN Premium${NC}"
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
    log "Update selesai. Errors: ${ERRORS}"
}

# ── Main Execution ────────────────────────────────────────────────
main() {
    # Buat log file
    mkdir -p "$(dirname $LOG_FILE)" "$TEMP_DIR"
    log "=== Mulai Update ==="

    banner
    check_root
    check_os
    check_internet
    check_version

    echo ""
    echo -e "${INFO} Mulai proses update... Harap tunggu."
    sleep 2

    update_scripts
    restart_services
    show_summary

    # Bersihkan temp
    rm -rf "$TEMP_DIR"
}

main
