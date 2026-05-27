<div align="center">

<img src="https://raw.githubusercontent.com/winsdevcltr09/autoInstall-premium/main/assets/banner.png" alt="DEV CULTURE ELITE" width="100%" />

<br/>

<img src="https://readme-typing-svg.demolab.com?font=Share+Tech+Mono&size=22&duration=2800&pause=1000&color=9B59B6&center=true&vCenter=true&width=680&height=55&lines=DEV+CULTURE+ELITE+%E2%80%94+VPN+Premium;SSH+%7C+VMess+%7C+VLESS+%7C+Trojan+%7C+Shadowsocks;Premium+Script+%7C+Multi+Protokol+%7C+Full+Managed" alt="Typing" />

<img src="https://readme-typing-svg.demolab.com?font=Share+Tech+Mono&size=12&duration=3500&pause=900&color=6C3483&center=true&vCenter=true&width=580&lines=Initializing+encrypted+tunnel...;Loading+protocol+modules...;All+systems+operational.+Welcome%2C+Operator." alt="Subtitle" />

<br/>

![Stars](https://img.shields.io/github/stars/winsdevcltr09/autoInstall-premium?style=for-the-badge&logo=github&color=9B59B6&labelColor=0D0D0D&logoColor=white)
![Forks](https://img.shields.io/github/forks/winsdevcltr09/autoInstall-premium?style=for-the-badge&logo=github&color=7D3C98&labelColor=0D0D0D&logoColor=white)
![Last Commit](https://img.shields.io/github/last-commit/winsdevcltr09/autoInstall-premium?style=for-the-badge&logo=git&color=6C3483&labelColor=0D0D0D&logoColor=white)
![Repo Size](https://img.shields.io/github/repo-size/winsdevcltr09/autoInstall-premium?style=for-the-badge&logo=files&color=8E44AD&labelColor=0D0D0D&logoColor=white)

![Version](https://img.shields.io/badge/VERSI-3.0.0_LTS-9B59B6?style=flat-square&logo=github&logoColor=white&labelColor=0D0D0D)
![Ubuntu](https://img.shields.io/badge/Ubuntu-20.04_%7C_22.04_%7C_24.04-7D3C98?style=flat-square&logo=ubuntu&logoColor=white&labelColor=0D0D0D)
![Debian](https://img.shields.io/badge/Debian-11_%7C_12-6C3483?style=flat-square&logo=debian&logoColor=white&labelColor=0D0D0D)
![Shell](https://img.shields.io/badge/Shell-Bash-8E44AD?style=flat-square&logo=gnubash&logoColor=white&labelColor=0D0D0D)
![Arch](https://img.shields.io/badge/Arch-x86__64-9B59B6?style=flat-square&logo=linux&logoColor=white&labelColor=0D0D0D)
<img src="https://raw.githubusercontent.com/winsdevcltr09/autoInstall-premium/main/assets/online.svg" width="14" height="14" /> <img src="https://img.shields.io/badge/Status-ONLINE-27AE60?style=flat-square&labelColor=0D0D0D" />

</div>

<br/>

---

## Daftar Isi

- [Tentang Project](#tentang-project)
- [Instalasi](#-instalasi)
- [Update](#-update)
- [Protokol](#-protokol-yang-tersedia)
- [Fitur Manajemen](#-fitur-manajemen)
- [Keamanan & Optimasi](#-keamanan--optimasi)
- [Sistem yang Didukung](#-sistem-yang-didukung)
- [Rekomendasi VPS](#-rekomendasi-provider-vps)
- [Panduan Lengkap](#-panduan-instalasi-lengkap)
- [Troubleshooting](#-troubleshooting)
- [Order Premium](#-order-premium-script)
- [Kontak](#-kontak--support)

---

## Tentang Project

**DEV CULTURE ELITE** adalah installer otomatis production-ready untuk infrastruktur VPN di VPS Ubuntu dan Debian. Ditenagai arsitektur modular berpusat pada `setupku.sh`, ekosistem ini men-deploy dan mengelola stack VPN multi-protokol lengkap — dari **Xray VLESS/VMess/Trojan** hingga **SSH Websocket**, **Shadowsocks**, **SlowDNS**, **BadVPN**, dan **OpenVPN** — dalam satu perintah.

Dibangun untuk operator server kelas elite, installer ini hadir dengan **engine validasi preflight** yang memeriksa 18+ parameter sistem sebelum mengubah satu file pun. Menu manajemen pasca-install yang komprehensif menangani siklus hidup akun (buat, perpanjang, hapus, cek) di seluruh protokol yang didukung. IP whitelist, auto-expire, dan Fail2ban sudah terintegrasi sejak awal.

> **Ini bukan script generik. Ini adalah otomasi infrastruktur yang dirancang untuk keandalan, keamanan, dan skalabilitas.**

---

## Instalasi

> Jalankan sebagai **root** setelah server siap:

```bash
bash <(curl -s https://raw.githubusercontent.com/winsdevcltr09/autoInstall-premium/main/setupku.sh)
```

**Dengan domain langsung:**

```bash
bash <(curl -s https://raw.githubusercontent.com/winsdevcltr09/autoInstall-premium/main/setupku.sh) --domain vpn.namadomain.com
```

**Download manual:**

```bash
wget https://raw.githubusercontent.com/winsdevcltr09/autoInstall-premium/main/setupku.sh
chmod +x setupku.sh
bash setupku.sh --domain vpn.namadomain.com
```

<details>
<summary><b>Penjelasan detail perintah instalasi</b></summary>

<br/>

| Perintah | Fungsi |
|:---|:---|
| `bash <(curl -s ...)` | Download dan jalankan installer langsung |
| `--domain vpn.namadomain.com` | Set domain SSL tanpa prompt interaktif |
| `--skip-preflight` | Lewati validasi (hanya untuk debug/testing) |

> Script akan otomatis **mendeteksi OS**, memvalidasi environment, menginstall semua dependensi, mengkonfigurasi domain, SSL, dan seluruh protokol VPN.

</details>

---

---

## 🌐 Sistem Domain (Dual Mode)

Script ini mendukung **dua mode konfigurasi domain** yang dipilih secara interaktif selama instalasi. Pilih mode yang sesuai dengan kebutuhan Anda:

<div align="center">

| Mode | Keterangan | Cocok Untuk |
|:---:|:---|:---|
| **Mode 1** — Domain Owner | Subdomain dari domain owner script (`florezha.eu.org`) | Reseller / pengguna yang membeli script |
| **Mode 2** — Domain Pribadi | Domain milik Anda sendiri + subdomain bebas | Pemilik domain sendiri |

</div>

### Mode 1 — Domain Owner (Subdomain)

Gunakan mode ini jika Anda **tidak punya domain sendiri**. Anda cukup memilih nama subdomain — domain utama sudah dikelola oleh owner script via Cloudflare.

```
Format  : <subdomain>.florezha.eu.org
Contoh  : sg1.florezha.eu.org
          id01.florezha.eu.org
          vpn-sg01.florezha.eu.org
```

**Cara setup:**
1. Jalankan installer → pilih **`[1] Domain Owner`**
2. Masukkan nama subdomain (huruf kecil, angka, dash)
3. Script otomatis mendaftarkan DNS via `cf-subdomain`
4. SSL di-generate otomatis via `genssl`

> **Aturan subdomain:** minimal 2 karakter, hanya huruf kecil (`a-z`), angka (`0-9`), dan dash (`-`). Tidak boleh diawali atau diakhiri dengan dash.

### Mode 2 — Domain Pribadi

Gunakan mode ini jika Anda **punya domain sendiri**. Domain harus sudah pointing ke IP VPS sebelum menjalankan installer.

```
Format  : <subdomain>.<domain_anda>
Contoh  : sg1.myvpn.com
          server01.vpn-ku.net
          id01.example.co.id
```

**Cara setup:**
1. Tambahkan **A Record** di panel DNS domain Anda:
   ```
   Nama  : sg1 (atau subdomain pilihan Anda)
   Tipe  : A
   Value : IP_VPS_ANDA
   TTL   : 300 (atau auto)
   ```
2. Tunggu propagasi DNS (5–60 menit)
3. Verifikasi: `nslookup sg1.namadomain.com` → pastikan mengarah ke IP VPS
4. Jalankan installer → pilih **`[2] Domain Pribadi`**
5. Masukkan domain Anda → masukkan subdomain

### Konfigurasi Domain Tersimpan

Setelah setup, domain aktif tersimpan di beberapa lokasi berikut (semua konsisten):

| File | Format | Digunakan oleh |
|:---|:---|:---|
| `/etc/xray/domain` | `sg1.florezha.eu.org` | Xray, nginx-ssl, add-ws, add-vless, dll |
| `/var/lib/scrz-prem/ipvps.conf` | `IP=sg1.florezha.eu.org` | genssl, add-ws, add-tr, add-ssws |
| `/root/domain` | `sg1.florezha.eu.org` | addhost, backup |
| `/etc/xray/domain.conf` | Structured config | referensi terstruktur |

> **Ganti domain setelah install?** Jalankan perintah `addhost` dari menu, lalu jalankan `genssl` untuk memperbarui sertifikat SSL.

### Cloudflare — Konfigurasi Subdomain Owner

Jika menggunakan **Mode 1** (Domain Owner), setup DNS via Cloudflare dilakukan oleh script `cf-subdomain`. Kredensial Cloudflare disimpan di `/etc/xray/cf.conf` (dibuat otomatis, tidak tersimpan di kode).

```bash
# Buat subdomain baru (interaktif):
cf-subdomain

# Update DNS ke IP VPS terbaru (otomatis):
fix
```


## Update

> Jalankan untuk memperbarui script ke versi terbaru:

```bash
updatsc
```

> Script update memperbarui seluruh file menu, konfigurasi, dan komponen pendukung secara otomatis **tanpa menghapus data akun** yang sudah ada.

---

## Protokol yang Tersedia

<div align="center">

| # | Protokol | Mode | Port | Enkripsi |
|:---:|:---|:---:|:---:|:---:|
| 01 | SSH WebSocket | Non-TLS | 80, 8080, 8880 | Plain |
| 02 | SSH WebSocket | TLS | 443 | SSL/TLS |
| 03 | SSH Slow DNS | Multipath | 53, 5300 | Tunnel |
| 04 | BadVPN UDP Gateway | UDP | 7100–7300 | Tunnel |
| 05 | Dropbear | SSH fallback | 109, 143 | SSH |
| 06 | Stunnel5 | SSL Tunnel | 222, 777 | SSL |
| 07 | Xray VMess WebSocket | TLS / Non-TLS | 443 / 80 | AES-128-GCM |
| 08 | Xray VLESS WebSocket | TLS | 443 | XTLS |
| 09 | Xray Trojan WebSocket / gRPC | TLS | 443 | TLS |
| 10 | Shadowsocks WebSocket / gRPC | TLS | 443 | AES-256-GCM |
| 11 | Nginx Reverse Proxy | HTTP/S | 80, 81, 443 | TLS |

</div>

---

## Fitur Manajemen

<div align="center">

| Kategori | Fitur |
|:---:|:---|
| **Akun** | Tambah, hapus, perpanjang masa aktif akun SSH / VMess / VLESS / Trojan / SS |
| **Monitoring** | Cek status akun, expired date, login aktif per protokol |
| **Preflight** | Validator 18 seksi otomatis sebelum install dimulai |
| **SSL Otomatis** | Generate & renew sertifikat SSL via Let's Encrypt (`acme.sh`) |
| **Cloudflare** | Deteksi otomatis orange-cloud, panduan SSL mode, `cf.sh` dynamic DNS |
| **IP Whitelist** | IP VPS harus terdaftar sebelum installer bisa berjalan |
| **Auto-Expire** | Akun expired dihapus otomatis setiap hari pukul 01:00 WIB |
| **Backup** | Backup konfigurasi manual via `tar` sebelum reinstall |
| **Log** | Log install di `/root/log-install.txt`, preflight di `/tmp/preflight-*.log` |
| **Panel** | Akses menu utama lengkap via perintah `menu` |

</div>

---

## Keamanan & Optimasi

- **Fail2ban** — aktif secara default, memblokir percobaan brute-force SSH
- **IP Whitelist** — IP VPS harus terdaftar sebelum installer bisa berjalan
- **Auto-Expire Cron** — akun expired dihapus otomatis setiap hari pukul 01:00 WIB
- **IPv6 Dinonaktifkan** — mengurangi attack surface via sysctl
- **TLS via acme.sh** — SSL Let's Encrypt auto-provisioned untuk semua protokol Xray
- **Tidak ada credential yang tersimpan** — token Cloudflare diminta saat runtime, tidak pernah disimpan di kode
- **Isolasi akun** — data VPN disimpan di `/root/akun/` dengan `chmod 700`
- **iptables-persistent** — aturan firewall bertahan setelah reboot

---

## Sistem yang Didukung

<div align="center">

| Sistem Operasi | Versi | Keterangan |
|:---:|:---:|:---|
| **Ubuntu** | 20.04 LTS | Direkomendasikan — paling stabil |
| **Ubuntu** | 22.04 LTS | Didukung penuh |
| **Ubuntu** | 24.04 LTS | Didukung penuh |
| **Debian** | 11 (Bullseye) | Didukung penuh |
| **Debian** | 12 (Bookworm) | Didukung penuh |
| **Ubuntu** | 18.04 | ⚠️ EOL — tidak direkomendasikan |
| **Debian** | 10 | ⚠️ EOL — dukungan terbatas |

> [!NOTE]
> Hanya mendukung arsitektur **x86_64**. VPS berbasis **OpenVZ** memerlukan TUN/TAP aktif. Gunakan **KVM** untuk kompatibilitas penuh.

</div>

---

## Rekomendasi Provider VPS

<div align="center">

| Provider | Segmen | Keunggulan |
|:---:|:---:|:---|
| **DigitalOcean** | Menengah | Kompatibilitas Ubuntu andal, provisioning cepat, networking bersih |
| **Vultr** | Menengah | Data center global, virtualisasi KVM, instance high-frequency terjangkau |
| **Linode / Akamai** | Menengah–Tinggi | Performa stabil, instance KVM berkelas bare-metal |
| **Hetzner** | Performa Tinggi | Rasio harga-performa terbaik, ideal untuk node VPN traffic tinggi |
| **OVHcloud** | Enterprise | Infrastruktur Eropa, opsi bandwidth unmetered, bare metal tersedia |
| **Contabo** | Budget | RAM/storage tinggi per harga — terbaik untuk deployment resource-heavy |

</div>

### Spesifikasi VPS yang Direkomendasikan

| Parameter | Minimum | Direkomendasikan |
|---|---|---|
| OS | Ubuntu 20.04 LTS | Ubuntu 22.04 LTS atau 24.04 LTS |
| RAM | 512 MB | 1 GB+ |
| CPU | 1 vCPU | 2 vCPU |
| Storage | 10 GB | 20 GB SSD |
| Jaringan | Internet stabil, GitHub bisa diakses | 100 Mbps+, unmetered lebih baik |
| Virtualisasi | KVM (diutamakan), Xen | KVM — OpenVZ/LXC punya keterbatasan TUN/TAP |
| Arsitektur | x86\_64 (amd64) | x86\_64 — dukungan ARM64 terbatas |

---

## Panduan Instalasi Lengkap

### 1 — Persiapan Server

Login sebagai **root**, perbarui sistem:

```bash
apt update -y && apt upgrade -y
```

### 2 — Setup Domain

Pastikan domain sudah pointing ke IP VPS:

```
A Record: vpn.namadomain.com → IP_VPS_KAMU
```

Verifikasi:

```bash
nslookup vpn.namadomain.com
```

### 3 — Jalankan Installer

```bash
bash <(curl -s https://raw.githubusercontent.com/winsdevcltr09/autoInstall-premium/main/setupku.sh) --domain vpn.namadomain.com
```

### 4 — Akses Menu Utama

Setelah instalasi selesai:

```bash
menu
```

### 5 — Jalankan Preflight Manual (Opsional)

```bash
wget https://raw.githubusercontent.com/winsdevcltr09/autoInstall-premium/main/preflight.sh
chmod +x preflight.sh
bash preflight.sh --domain vpn.namadomain.com
```

### 6 — Backup Sebelum Reinstall

```bash
tar -czf /root/backup-vpn-$(date +%Y%m%d).tar.gz \
    /etc/xray /etc/nginx /etc/openvpn /root/akun
```

---

## Struktur Direktori

```
autoInstall-premium/
├── setupku.sh              — Entry point installer utama
├── preflight.sh            — Validator pra-install 18 seksi
├── autoreboot.sh           — Manajemen reboot terjadwal
├── add-ssws.sh             — Tambah akun SSH SSL WebSocket
├── add-ws.sh               — Tambah akun SSH WebSocket
├── add-tr.sh               — Tambah akun Trojan
├── add-trgo.sh             — Tambah akun Trojan gRPC
├── add-vless.sh            — Tambah akun VLESS
├── addhost.sh              — Konfigurasi domain/host
├── badvpn/                 — Binary UDP gateway BadVPN
├── Trojan/                 — Konfigurasi protokol Trojan
├── Menu Final/             — Menu manajemen pasca-install
│   ├── menu.sh             — Entry menu utama
│   ├── menussh.sh          — Manajemen akun SSH
│   ├── menuv.sh            — Menu VMess/VLESS
│   ├── menut.sh            — Menu Trojan
│   ├── menus.sh            — Menu Shadowsocks
│   ├── menul.sh            — Menu L2TP
│   ├── addv/s/t/l.sh       — Tambah akun per protokol
│   ├── cekv/s/t/l.sh       — Cek akun per protokol
│   ├── delv/s/t/l.sh       — Hapus akun per protokol
│   ├── renev/s/t/l.sh      — Perpanjang akun per protokol
│   ├── usern.sh            — Manajemen pengguna sistem
│   └── clog.sh             — Bersihkan log
└── assets/
    ├── banner.png
    ├── cyberpunk-banner.png
    └── screenshots/
        ├── preview-dashboard.png
        ├── preview-add.png
        └── preview-login.png
```

---

## Tampilan

<div align="center">

<table>
<tr>
<td align="center">
<img src="https://raw.githubusercontent.com/winsdevcltr09/autoInstall-premium/main/assets/screenshots/preview-dashboard.png" width="270" alt="Tampilan Dashboard"/>
<br/><sub>Dashboard Utama</sub>
</td>
<td align="center">
<img src="https://raw.githubusercontent.com/winsdevcltr09/autoInstall-premium/main/assets/screenshots/preview-add.png" width="270" alt="Tampilan Tambah Akun"/>
<br/><sub>Tambah Akun</sub>
</td>
<td align="center">
<img src="https://raw.githubusercontent.com/winsdevcltr09/autoInstall-premium/main/assets/screenshots/preview-login.png" width="270" alt="Tampilan Verifikasi"/>
<br/><sub>Verifikasi Lisensi</sub>
</td>
</tr>
</table>

</div>

---

## Troubleshooting

<details>
<summary><b>Domain tidak mengarah ke VPS</b></summary>

```bash
nslookup vpn.namadomain.com

# Edit A record di panel DNS kamu
# Name: vpn.namadomain.com → Value: IP_VPS_KAMU
# Tunggu propagasi 5–60 menit, lalu coba lagi
bash preflight.sh --domain vpn.namadomain.com
```
</details>

<details>
<summary><b>Port sudah dipakai</b></summary>

```bash
ss -tlnp | grep ':80 '
lsof -i :80

# Hentikan service yang konflik
systemctl stop apache2 && systemctl disable apache2
```
</details>

<details>
<summary><b>Error apt lock</b></summary>

```bash
rm -f /var/lib/dpkg/lock-frontend /var/lib/dpkg/lock
dpkg --configure -a
apt-get update
```
</details>

<details>
<summary><b>NTP tidak tersinkron</b></summary>

```bash
timedatectl set-ntp true
systemctl restart systemd-timesyncd
timedatectl status
```
</details>

<details>
<summary><b>TUN/TAP tidak tersedia (OpenVZ)</b></summary>

Hubungi provider VPS untuk mengaktifkan TUN/TAP dari panel kontrol. Diperlukan untuk beberapa protokol VPN.
</details>

---

## Order Premium Script

<div align="center">

---

### DUKUNGAN & BANTUAN DEPLOYMENT PREMIUM

*Elite Infrastructure Support &nbsp;·&nbsp; Layanan Otomasi VPS Private*

---

Butuh bantuan setup premium, deployment custom, optimasi VPS, atau dukungan instalasi private?

| Layanan | Deskripsi |
|:---:|:---|
| **Instalasi Script** | Install terpandu jarak jauh dengan verifikasi |
| **Bantuan Setup VPS** | Dari VPS baru hingga ekosistem VPN berjalan |
| **Konfigurasi Premium** | Tuning custom domain, Cloudflare, dan multi-protokol |
| **Dukungan Deployment** | Panduan deployment lengkap dan troubleshooting |
| **Optimasi Server** | Tuning performa, firewall, dan manajemen resource |
| **Bantuan Private** | Sesi support 1-on-1 dedicated |

<br/>

[![Telegram](https://img.shields.io/badge/Telegram-@dcxii09-9B59B6?style=for-the-badge&logo=telegram&logoColor=white&labelColor=0D0D0D)](https://t.me/dcxii09)
&nbsp;
[![WhatsApp](https://img.shields.io/badge/WhatsApp-08388014771-25D366?style=for-the-badge&logo=whatsapp&logoColor=white&labelColor=0D0D0D)](https://wa.me/6208388014771)

---

</div>

---

## Kontak & Support

<div align="center">

<br/>

[![Telegram](https://img.shields.io/badge/Telegram-@dcxii09-9B59B6?style=for-the-badge&logo=telegram&logoColor=white&labelColor=0D0D0D)](https://t.me/dcxii09)

<br/><br/>

<img src="https://readme-typing-svg.demolab.com?font=Share+Tech+Mono&size=12&duration=4000&pause=1000&color=5B2C6F&center=true&vCenter=true&width=580&lines=Script+by+DEV+CULTURE+ELITE;Dilarang+mendistribusikan+ulang+tanpa+izin.;Copyright+2024+DevCulture+Elite.+All+rights+reserved." alt="Footer" />

<br/>

<sub>
<img src="https://raw.githubusercontent.com/winsdevcltr09/autoInstall-premium/main/assets/online.svg" width="10" height="10" /> <code>SYSTEM ONLINE</code>
&nbsp;&nbsp;
<img src="https://raw.githubusercontent.com/winsdevcltr09/autoInstall-premium/main/assets/online.svg" width="10" height="10" /> <code>ALL PROTOCOLS ACTIVE</code>
&nbsp;&nbsp;
<img src="https://raw.githubusercontent.com/winsdevcltr09/autoInstall-premium/main/assets/online.svg" width="10" height="10" /> <code>ENCRYPTION ENABLED</code>
</sub>

</div>
