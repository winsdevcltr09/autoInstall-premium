<div align="center">

<img src="https://raw.githubusercontent.com/winsdevcltr09/autoInstall-premium/main/assets/banner.png" alt="DevCulture XII Store Banner" width="100%"/>

<br/>

# ░▒▓ DEVCULTURE XII STORE ▓▒░
### ⚡ Premium VPN Auto-Installer — Powered by DevCulture XII

<br/>

![Version](https://img.shields.io/badge/VERSION-3.0.0%20LTS-blueviolet?style=for-the-badge&logo=github&logoColor=white)
![Ubuntu](https://img.shields.io/badge/UBUNTU-18.04%20|%2020.04%20|%2022.04%20|%2024.04-9B59B6?style=for-the-badge&logo=ubuntu&logoColor=white)
![Debian](https://img.shields.io/badge/DEBIAN-10%20|%2011%20|%2012-8E44AD?style=for-the-badge&logo=debian&logoColor=white)
![License](https://img.shields.io/badge/ACCESS-WHITELIST%20ONLY-FF0066?style=for-the-badge&logo=shield&logoColor=white)
![Telegram](https://img.shields.io/badge/TELEGRAM-t.me%2Fdcxii-7B2FBE?style=for-the-badge&logo=telegram&logoColor=white)

<br/>

> **Script VPN premium all-in-one dengan sistem lisensi IP Whitelist**
> Mendukung Ubuntu 18.04 / 20.04 / 22.04 / 24.04 LTS & Debian 10 / 11 / 12

</div>

---

## ▌PREVIEW TAMPILAN

<div align="center">
<table>
<tr>
<td align="center"><b>🔐 Secure Login Panel</b></td>
<td align="center"><b>📊 Dashboard Overview</b></td>
<td align="center"><b>⚙️ Provision License</b></td>
</tr>
<tr>
<td><img src="https://raw.githubusercontent.com/winsdevcltr09/autoInstall-premium/main/assets/screenshots/preview-login.png" alt="Login Panel" width="340"/></td>
<td><img src="https://raw.githubusercontent.com/winsdevcltr09/autoInstall-premium/main/assets/screenshots/preview-dashboard.png" alt="Dashboard" width="340"/></td>
<td><img src="https://raw.githubusercontent.com/winsdevcltr09/autoInstall-premium/main/assets/screenshots/preview-add.png" alt="Add License" width="340"/></td>
</tr>
</table>
</div>

---

## ▌INSTALASI SATU KLIK

> ⚠️ **PERHATIAN** — IP VPS kamu harus sudah terdaftar di whitelist admin sebelum instalasi.
> Hubungi kami di **[t.me/dcxii](https://t.me/dcxii)** untuk mendapatkan akses lisensi.

### 🚀 Perintah Install (Jalankan sebagai root)

```bash
bash <(curl -Ls https://raw.githubusercontent.com/winsdevcltr09/autoInstall-premium/main/setupku.sh)
```

### 📦 Alternatif (jika curl tidak tersedia)

```bash
wget -qO- https://raw.githubusercontent.com/winsdevcltr09/autoInstall-premium/main/setupku.sh | bash
```

### 🔑 Pastikan login sebagai root terlebih dahulu

```bash
# Login root
sudo -i

# Lalu jalankan perintah install di atas
bash <(curl -Ls https://raw.githubusercontent.com/winsdevcltr09/autoInstall-premium/main/setupku.sh)
```

---

## ▌PERSYARATAN SISTEM

<div align="center">

| Komponen | Minimum | Direkomendasikan |
|----------|---------|------------------|
| **OS** | Ubuntu 20.04 LTS | Ubuntu 22.04 / 24.04 LTS |
| **CPU** | 1 vCore | 2 vCore |
| **RAM** | 512 MB | 1 GB |
| **Storage** | 10 GB SSD | 20 GB SSD |
| **Koneksi** | 100 Mbps | 1 Gbps |
| **Akses** | Root / Sudo | Root wajib |
| **IP** | IPv4 Statis | IPv4 Statis |

</div>

---

## ▌FITUR LENGKAP

<table>
<tr>
<td valign="top" width="50%">

### 🌐 Protokol VPN
- ✅ **Xray** (VMess / VLESS / Trojan)
- ✅ **WebSocket** (WS + TLS)
- ✅ **gRPC** Transport
- ✅ **Shadowsocks** (SS)
- ✅ **SSH** (OpenSSH + Dropbear)
- ✅ **SSH WebSocket** (WS)
- ✅ **SSHWS** (Port 80/443)
- ✅ **OpenVPN** TCP + UDP
- ✅ **Trojan-Go** (WS / gRPC)
- ✅ **Hysteria2** (UDP)
- ✅ **TUIC v5** (QUIC)
- ✅ **SlowDNS**
- ✅ **BadVPN** (badvpn-udpgw)

</td>
<td valign="top" width="50%">

### 🛠️ Fitur Sistem
- ✅ **Auto SSL** — Let's Encrypt otomatis
- ✅ **Domain / IP** — Pilihan bebas
- ✅ **Multi-Port** — Tiap protokol port sendiri
- ✅ **Stunnel4** — SSL Tunneling
- ✅ **Squid Proxy** — Port 3128/8080
- ✅ **IP Whitelist** — Proteksi akses script
- ✅ **Anti-DDoS** — Fail2Ban + iptables
- ✅ **Auto Reboot** — Jadwal via cron
- ✅ **Monitor Trafik** — vnstat realtime
- ✅ **Panel Web** — License Manager
- ✅ **Manajemen Akun** — Tambah/hapus/cek
- ✅ **Backup & Restore** — Konfigurasi lengkap
- ✅ **Log Management** — Rotasi otomatis

</td>
</tr>
</table>

---

## ▌OS YANG DIDUKUNG

<div align="center">

| Sistem Operasi | Versi | Status |
|----------------|-------|--------|
| ![Ubuntu](https://img.shields.io/badge/-Ubuntu-E95420?style=flat-square&logo=ubuntu&logoColor=white) Ubuntu | 18.04 LTS (Bionic) | ⚠️ Terbatas |
| ![Ubuntu](https://img.shields.io/badge/-Ubuntu-E95420?style=flat-square&logo=ubuntu&logoColor=white) Ubuntu | 20.04 LTS (Focal) | ✅ Didukung |
| ![Ubuntu](https://img.shields.io/badge/-Ubuntu-E95420?style=flat-square&logo=ubuntu&logoColor=white) Ubuntu | 22.04 LTS (Jammy) | ✅ **Direkomendasikan** |
| ![Ubuntu](https://img.shields.io/badge/-Ubuntu-E95420?style=flat-square&logo=ubuntu&logoColor=white) Ubuntu | 24.04 LTS (Noble) | ✅ Didukung |
| ![Debian](https://img.shields.io/badge/-Debian-A81D33?style=flat-square&logo=debian&logoColor=white) Debian | 10 (Buster) | ✅ Didukung |
| ![Debian](https://img.shields.io/badge/-Debian-A81D33?style=flat-square&logo=debian&logoColor=white) Debian | 11 (Bullseye) | ✅ Didukung |
| ![Debian](https://img.shields.io/badge/-Debian-A81D33?style=flat-square&logo=debian&logoColor=white) Debian | 12 (Bookworm) | ✅ Didukung |

</div>

---

## ▌ALUR INSTALASI

```
╔══════════════════════════════════════════════════════╗
║           DEVCULTURE XII — INSTALL FLOW              ║
╠══════════════════════════════════════════════════════╣
║  [1] Cek Root Access       → Wajib root              ║
║  [2] Deteksi OS            → Ubuntu/Debian check     ║
║  [3] Cek Koneksi           → Ping 8.8.8.8            ║
║  [4] Validasi Lisensi      → Cek IP Whitelist        ║
║  [5] Input Domain/IP       → SSL atau IP langsung    ║
║  [6] Install Dependencies  → curl, wget, jq, dll     ║
║  [7] Konfigurasi Sistem    → timezone, sysctl        ║
║  [8] Install Xray Core     → VMess/VLESS/Trojan      ║
║  [9] Install SSH Services  → OpenSSH + Dropbear      ║
║ [10] Install OpenVPN       → TCP + UDP               ║
║ [11] Setup SSL (opsional)  → Certbot auto            ║
║ [12] Konfigurasi Firewall  → iptables rules          ║
║ [13] Setup Cron Jobs       → Auto-reboot dll         ║
║ [14] Finalisasi            → Tampilkan info akun     ║
╚══════════════════════════════════════════════════════╝
```

---

## ▌PORT YANG DIGUNAKAN

<div align="center">

| Protokol | Port | Keterangan |
|----------|------|------------|
| SSH OpenSSH | 22 | Default SSH |
| SSH Dropbear | 80, 143, 444 | Multi-port |
| SSH WebSocket | 2082, 2095 | WS over HTTP |
| SSHWS TLS | 2083, 2096 | WS over HTTPS |
| Xray VMess WS | 8080 | WebSocket |
| Xray VMess WS TLS | 8443 | WebSocket TLS |
| Xray VLESS WS | 8888 | WebSocket |
| Xray VLESS WS TLS | 8444 | WebSocket TLS |
| Trojan WS TLS | 2087 | WebSocket TLS |
| Shadowsocks | 1234 | SS Protocol |
| OpenVPN TCP | 1194 | VPN TCP |
| OpenVPN UDP | 2200 | VPN UDP |
| Squid Proxy | 3128, 8080 | HTTP Proxy |
| SlowDNS | 5300 | DNS Tunnel |
| Stunnel4 | 443, 777 | SSL Tunnel |
| BadVPN UDPGW | 7100-7300 | UDP Gateway |

</div>

---

## ▌CATATAN PENTING

```
⚠️  Pastikan port 80 dan 443 tidak diblokir oleh provider VPS kamu
⚠️  Gunakan VPS dengan IP STATIS — IP dinamis tidak didukung
⚠️  Disable AppArmor/SELinux sebelum install jika ada konflik
⚠️  Jangan install di VPS yang sudah ada panel lain (Nginx/Apache)
⚠️  Ubuntu 24.04: iptables-legacy diaktifkan otomatis oleh installer
```

---

## ▌TROUBLESHOOTING

<details>
<summary><b>❌ "IP tidak terdaftar" — Lisensi Tidak Valid</b></summary>

IP VPS kamu belum didaftarkan di whitelist admin.
Hubungi kami di **[t.me/dcxii](https://t.me/dcxii)** dengan menyebutkan:
- IP VPS kamu
- Username yang diinginkan
- Tanggal mulai berlangganan

</details>

<details>
<summary><b>❌ SSL/TLS gagal generate</b></summary>

Pastikan:
1. Domain sudah pointing ke IP VPS
2. Port 80 terbuka (untuk challenge Let's Encrypt)
3. Tunggu propagasi DNS 5-10 menit, lalu coba ulang

</details>

<details>
<summary><b>❌ Instalasi gagal di Ubuntu 24.04</b></summary>

Ubuntu 24.04 menggunakan nftables. Script ini sudah otomatis switch ke iptables-legacy.
Jika masih gagal, pastikan kernel up to date:
```bash
apt update && apt full-upgrade -y && reboot
```

</details>

---

## ▌LISENSI & KONTAK

<div align="center">

Script ini **hanya untuk pelanggan resmi DevCulture XII Store**.
Dilarang keras menyebarkan, memodifikasi, atau menjual ulang tanpa izin.

<br/>

[![Telegram](https://img.shields.io/badge/Telegram-DCXII%20Store-7B2FBE?style=for-the-badge&logo=telegram&logoColor=white)](https://t.me/dcxii)
[![GitHub](https://img.shields.io/badge/GitHub-winsdevcltr09-9B59B6?style=for-the-badge&logo=github&logoColor=white)](https://github.com/winsdevcltr09)

<br/>

```
╔═══════════════════════════════════════╗
║     © 2024-2025 DevCulture XII Store  ║
║     All Rights Reserved               ║
║     Telegram: t.me/dcxii              ║
╚═══════════════════════════════════════╝
```

</div>
