# autoInstall-premium — DevCulture XII Store VPN Premium

Script installer otomatis untuk VPN server berbasis Xray, SSH Websocket, SlowDNS, BadVPN, OpenVPN, dan Shadowsocks. Dirancang untuk Ubuntu dan Debian VPS — production-ready dengan pre-flight validation bawaan.

---

## Requirements

| Komponen | Minimum |
|---|---|
| RAM | 512 MB (disarankan 1 GB) |
| Disk | 2 GB free space |
| Koneksi | Stabil, akses ke GitHub |
| Akses | Root / sudo |

### Tool yang diperlukan (auto-install jika belum ada)
`curl` `wget` `python3` `openssl` `unzip` `jq` `cron` `socat` `iptables` `systemd`

---

## Supported OS

| OS | Versi | Status |
|---|---|---|
| Ubuntu | 20.04 LTS (Focal) | ✅ Direkomendasikan |
| Ubuntu | 22.04 LTS (Jammy) | ✅ Didukung penuh |
| Ubuntu | 24.04 LTS (Noble) | ✅ Didukung penuh |
| Debian | 11 (Bullseye) | ✅ Didukung penuh |
| Debian | 12 (Bookworm) | ✅ Didukung penuh |
| Ubuntu | 18.04 | ⚠️ EOL — tidak direkomendasikan |
| Debian | 10 | ⚠️ EOL — tidak direkomendasikan |

> **Arsitektur:** x86_64 (amd64). ARM64 diuji terbatas.

---

## Domain & Cloudflare Setup

Sebelum install, domain harus sudah **pointing ke IP VPS**.

### Langkah setup domain

1. **Beli/siapkan domain** (Cloudflare, Namecheap, dll.)
2. **Set A Record:**
   - Name: `vpn.namadomain.com` (atau `@` untuk root)
   - Value: `IP_VPS_ANDA`
   - TTL: Auto
3. **Jika pakai Cloudflare:**
   - Mode DNS: **DNS Only** (abu-abu) — disarankan untuk install pertama
   - Atau **Proxied** (orange) — didukung tapi perlu setting SSL mode `Full`
4. **Tunggu propagasi DNS:** 5–60 menit
5. **Verifikasi:** `nslookup vpn.namadomain.com` harus mengembalikan IP VPS

### Cloudflare SSL Mode
Jika menggunakan Cloudflare proxy (orange cloud):
- SSL/TLS → **Full** atau **Full (Strict)**
- Port 80 dan 443 harus bisa diakses dari Cloudflare

---

## Preflight Validation

`preflight.sh` adalah validator fail-fast yang otomatis berjalan sebelum installer dimulai.

### Apa yang dicek preflight

| Seksi | Check |
|---|---|
| Root | EUID=0 |
| OS | Ubuntu/Debian versi yang didukung |
| Arsitektur | x86_64 / aarch64 |
| Virtualisasi | KVM, Xen, OpenVZ, LXC |
| RAM | Minimum 256 MB |
| Disk | Minimum 1 GB free |
| Internet | Ping + DNS resolve |
| Port conflicts | 20+ port dicek (80, 443, 22, 109, dll.) |
| Dependensi | python3, curl, wget, jq, openssl, dll. |
| apt health | Lock, repository, error |
| Firewall | iptables, UFW, nftables |
| NTP | Time sync — auto-fix jika tidak sinkron |
| Domain & DNS | A record, IP matching, Cloudflare detection |
| Existing install | Deteksi reinstall, warning backup |
| Permission | Executable, /usr/local/bin, systemd |
| Folder | Auto-create direktori yang diperlukan |
| Binary | Library OpenSSL, Python3 modules |
| Download endpoints | GitHub, acme.sh, IP API |
| Service conflicts | nginx, xray, openvpn |
| IP forwarding | Auto-aktifkan jika belum |
| Cron | Auto-aktifkan jika belum |

### Exit codes preflight
| Code | Arti |
|---|---|
| `0` | Semua OK — install bisa dilanjutkan |
| `1` | CRITICAL ERROR — install dihentikan |
| `2` | Warning saja — install bisa dilanjutkan |
| `99` | Internal error tak terduga |

---

## Installer Flow

```
bash setupku.sh [--skip-preflight] [--domain yourdomain.com]
        │
        ▼
┌──────────────────────────┐
│     PARSE ARGUMENTS      │
│  (--skip-preflight, dll) │
└─────────────┬────────────┘
              │
              ▼
┌──────────────────────────┐     SKIP_PREFLIGHT=true
│      RUN PREFLIGHT       │────────────────────────►
│      preflight.sh        │                        │
│  - 18 seksi validation   │                        │
│  - domain/CF check       │                        │
└─────────────┬────────────┘                        │
              │                                     │
       CRITICAL?                              ┌─────▼──────────────┐
          │                                   │  ⚠️  WARNING BESAR  │
         YES──────► STOP INSTALL              │  (tidak rekomendasi)│
          │                                   └─────┬──────────────┘
         NO                                         │
          │                                         │
          ▼                                         ▼
┌──────────────────────────────────────────────────────────┐
│                    INSTALLER UTAMA                        │
│  banner → check_root → check_os → check_internet         │
│  → check_izin → input_domain → install_deps              │
│  → system_config → install_services → install_menus      │
│  → setup_cron → setup_profile → show_summary             │
└──────────────────────────────────────────────────────────┘
```

---

## Installation

### Cara install (production — recommended)

```bash
# Download dan jalankan installer
bash <(curl -s https://raw.githubusercontent.com/winsdevcltr09/autoInstall-premium/main/setupku.sh)
```

### Dengan domain langsung (validasi Cloudflare otomatis)

```bash
bash <(curl -s https://raw.githubusercontent.com/winsdevcltr09/autoInstall-premium/main/setupku.sh) --domain vpn.namadomain.com
```

### Install manual (download dulu)

```bash
# Download
wget https://raw.githubusercontent.com/winsdevcltr09/autoInstall-premium/main/setupku.sh

# Jalankan
chmod +x setupku.sh
bash setupku.sh --domain vpn.namadomain.com
```

> **Catatan:** Script akan otomatis menjalankan `preflight.sh` terlebih dahulu. Jika ada critical error, install akan dihentikan sebelum ada perubahan ke sistem.

---

## Skip Preflight Mode

```bash
bash setupku.sh --skip-preflight
```

atau via download langsung:

```bash
bash <(curl -s https://raw.githubusercontent.com/winsdevcltr09/autoInstall-premium/main/setupku.sh) --skip-preflight
```

**⚠️ WARNING BESAR:**

```
════════════════════════════════════════════════════════════
⚠  PREFLIGHT VALIDATION DILEWATI
════════════════════════════════════════════════════════════
Mode ini TIDAK DIREKOMENDASIKAN untuk production VPS.

Risiko:
• Installer bisa gagal di tengah jalan
• System config bisa korup jika dependency kurang
• Domain belum pointing bisa menyebabkan SSL gagal
• Port conflict bisa bikin service tidak bisa start

Gunakan --skip-preflight HANYA jika:
✓ Anda sudah yakin environment VPS bersih
✓ Debug/test ulang setelah preflight sudah dijalankan manual
✓ Anda memahami konsekuensinya

Untuk jalankan preflight manual:
  bash preflight.sh --domain yourdomain.com
════════════════════════════════════════════════════════════
```

### Kapan aman pakai `--skip-preflight`

- Debugging/testing di lingkungan yang sudah diketahui bersih
- Rerun install setelah preflight sudah dijalankan manual dan lulus
- CI/CD environment terkontrol

### Kapan TIDAK boleh pakai `--skip-preflight`

- Install pertama di VPS baru
- VPS production yang belum pernah dicek
- Saat ada perubahan domain/DNS

---

## Menjalankan Preflight Manual

```bash
# Download preflight saja
wget https://raw.githubusercontent.com/winsdevcltr09/autoInstall-premium/main/preflight.sh
chmod +x preflight.sh

# Jalankan dengan validasi domain
bash preflight.sh --domain vpn.namadomain.com

# Skip validasi Cloudflare (jika tidak pakai CF)
bash preflight.sh --domain vpn.namadomain.com --skip-cf

# Skip semua DNS check
bash preflight.sh --skip-dns

# Lihat log lengkap
cat /tmp/preflight-*.log
```

---

## Troubleshooting

### Domain tidak mengarah ke VPS

```
[FAIL] Domain tidak mengarah ke VPS ini.
       Detected VPS IP  : 1.2.3.4
       Resolved Domain IP: 5.6.7.8
```

**Solusi:**
1. Login ke panel DNS domain Anda
2. Edit/tambah A record: `vpn.namadomain.com` → `1.2.3.4`
3. Jika pakai Cloudflare: pastikan mode DNS Only (abu-abu) dulu
4. Tunggu propagasi 5–60 menit
5. Jalankan ulang: `bash preflight.sh --domain vpn.namadomain.com`

### Port sudah dipakai

```
[FAIL] Port 80 (HTTP/Nginx) sudah dipakai!
```

**Solusi:**
```bash
# Cek proses yang memakai port 80
ss -tlnp | grep ":80 "
lsof -i :80

# Stop service yang konflik (contoh apache2)
systemctl stop apache2
systemctl disable apache2
```

### apt lock error

```
[WARN] apt update error: E: Could not get lock
```

**Solusi:**
```bash
# Paksa unlock (hati-hati jika ada proses update berjalan)
rm -f /var/lib/dpkg/lock-frontend /var/lib/dpkg/lock
dpkg --configure -a
apt-get update
```

### Python3 tidak ditemukan

```
[FAIL] python3 tidak ditemukan
```

**Solusi:**
```bash
apt-get update && apt-get install -y python3
```

### NTP tidak sinkron

```
[WARN] NTP tidak tersinkron
```

**Solusi:**
```bash
timedatectl set-ntp true
systemctl restart systemd-timesyncd
timedatectl status
```

### TUN/TAP tidak tersedia (OpenVZ)

Hubungi provider VPS untuk mengaktifkan TUN/TAP di panel kontrol VPS.

---

## FAQ

**Q: Apakah bisa install tanpa domain?**
A: Bisa, sistem akan menggunakan IP VPS sebagai fallback. Tapi fitur TLS (VMess/Vless/Trojan TLS) tidak akan berfungsi optimal tanpa SSL cert dari domain.

**Q: Apakah aman dijalankan berkali-kali (reinstall)?**
A: Preflight akan mendeteksi install sebelumnya dan menampilkan warning. Reinstall akan OVERWRITE konfigurasi dan akun VPN yang sudah ada. Backup dulu sebelum reinstall.

**Q: Cloudflare orange cloud (proxy) bisa dipakai?**
A: Bisa, tapi SSL mode harus diset ke "Full" atau "Full (Strict)" di Cloudflare dashboard. Preflight akan mendeteksi orange cloud dan menampilkan panduan.

**Q: Arsitektur ARM (VPS cloud provider seperti Ampere) didukung?**
A: Terbatas. Beberapa binary (BadVPN, Xray versi lama) tersedia untuk aarch64, tapi tidak semua diuji penuh.

**Q: Berapa lama proses install?**
A: Biasanya 10–25 menit tergantung kecepatan internet VPS dan paket yang didownload.

**Q: Apa yang dilakukan auto-fix di preflight?**
A: Autofix hanya untuk hal yang aman: aktifkan IP forwarding, aktifkan cron, buat direktori yang belum ada, install tool non-kritis yang hilang (jq, unzip, dll.), chmod +x script.

---

## Reinstall

Jika ingin install ulang dari awal:

```bash
# Backup konfigurasi penting
tar -czf /root/backup-vpn-$(date +%Y%m%d).tar.gz \
    /etc/xray /etc/nginx /etc/openvpn /root/akun 2>/dev/null

# Lihat backup
ls -lh /root/backup-vpn-*.tar.gz

# Jalankan installer ulang
bash <(curl -s https://raw.githubusercontent.com/winsdevcltr09/autoInstall-premium/main/setupku.sh) \
     --domain vpn.namadomain.com
```

> Preflight akan mendeteksi existing install dan menampilkan warning sebelum overwrite.

---

## Updating

```bash
# Update script dan binary
updatsc

# Atau download ulang installer
bash <(curl -s https://raw.githubusercontent.com/winsdevcltr09/autoInstall-premium/main/setupku.sh)
```

---

## Services & Ports

| Service | Port |
|---|---|
| OpenSSH | 22, 53, 2222, 2269 |
| SSH Websocket | 80, 8880, 8080 |
| SSH SSL Websocket | 443 |
| Stunnel5 | 222, 777 |
| Dropbear | 109, 143 |
| BadVPN UDP GW | 7100–7300 |
| Nginx | 80, 81, 443 |
| Xray VMess TLS | 443 |
| Xray VMess Non-TLS | 80 |
| Xray Vless TLS | 443 |
| Xray Trojan WS/gRPC | 443 |
| Shadowsocks WS/gRPC | 443 |
| SlowDNS | 53, 5300 |

---

## Security Notes

- Jangan pernah hardcode API key atau credential di script
- `cf.sh` (Cloudflare DNS updater) meminta CF credentials saat runtime — tidak disimpan di kode
- Token/password VPN disimpan di `/root/akun/` — pastikan permission 700
- Auto-expire akun berjalan tiap 01:00 WIB via cron
- Fail2ban aktif secara default untuk proteksi brute force SSH

---

## Support

- Telegram: [t.me/dcxii](https://t.me/dcxii)
- GitHub: [github.com/winsdevcltr09/autoInstall-premium](https://github.com/winsdevcltr09/autoInstall-premium)

---

*DevCulture XII Store VPN Premium v3.0.0 LTS*
