<!-- ═══════════════════════════════════════════════════════════════════
     DEVCULTURE XII STORE — AUTO INSTALL VPN PREMIUM
     ════════════════════════════════════════════════════════════════ -->

<div align="center">

<img src="https://readme-typing-svg.demolab.com?font=Share+Tech+Mono&size=30&duration=2800&pause=1200&color=9B59B6&center=true&vCenter=true&multiline=true&width=750&height=110&lines=%5B+DEVCULTURE+XII+STORE+%5D;%E2%96%88+AUTO+INSTALL+VPN+PREMIUM+%E2%96%88" alt="Typing SVG" />

<br/>

<img src="https://readme-typing-svg.demolab.com?font=Share+Tech+Mono&size=14&duration=3000&pause=800&color=7D3C98&center=true&vCenter=true&width=620&lines=Initializing+cyberpunk+VPN+system...;Loading+encrypted+modules...;SSH+%7C+VMess+%7C+VLESS+%7C+Trojan+%7C+Shadowsocks;All+protocols+online.+Welcome%2C+Operator." alt="Subtitle" />

<br/><br/>

![Version](https://img.shields.io/badge/VERSION-3.0.0%20LTS-9B59B6?style=for-the-badge&logo=github&logoColor=white&labelColor=0D0D0D)
![OS](https://img.shields.io/badge/OS-Ubuntu%20%7C%20Debian-7D3C98?style=for-the-badge&logo=linux&logoColor=white&labelColor=0D0D0D)
![Shell](https://img.shields.io/badge/SHELL-BASH-6C3483?style=for-the-badge&logo=gnubash&logoColor=white&labelColor=0D0D0D)
![Status](https://img.shields.io/badge/STATUS-ACTIVE-8E44AD?style=for-the-badge&logo=statuspage&logoColor=white&labelColor=0D0D0D)

<br/>

```
╔══════════════════════════════════════════════════════════════════╗
║  ░░░  DEVCULTURE XII STORE — VPN PREMIUM AUTO INSTALLER  ░░░   ║
║  ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓  ║
║  [ SSH-WS ]  [ VMESS ]  [ VLESS ]  [ TROJAN ]  [ SS-WS ]      ║
╚══════════════════════════════════════════════════════════════════╝
```

</div>

---

<div align="center">

## `⚡ INSTALASI SATU PERINTAH ⚡`

</div>

> **Persiapan wajib** — jalankan perintah berikut sebelum instalasi agar server dalam kondisi terbaru:

```bash
apt-get update && apt-get upgrade -y && apt dist-upgrade -y && update-grub && reboot
```

> ⚠️ Server akan **reboot**. Setelah menyala kembali, lanjutkan ke langkah instalasi.

<br/>

<div align="center">

### 🟣 INSTALL OTOMATIS — SATU PERINTAH

</div>

```bash
wget -O setup.sh https://raw.githubusercontent.com/winsdevcltr09/autoInstall-premium/main/setupku.sh && chmod +x setup.sh && ./setup.sh
```

<details>
<summary><b>📋 Penjelasan detail setiap bagian perintah</b></summary>

<br/>

| Bagian Perintah | Penjelasan |
|:---|:---|
| `wget -O setup.sh <url>` | Mengunduh file `setupku.sh` dari GitHub dan menyimpannya sebagai `setup.sh` di direktori aktif |
| `&&` | Operator berantai — perintah berikutnya hanya jalan jika perintah sebelumnya berhasil |
| `chmod +x setup.sh` | Memberikan izin eksekusi pada file installer yang baru diunduh |
| `./setup.sh` | Menjalankan installer secara langsung dari direktori aktif |

> Script secara otomatis mendeteksi OS, memasang semua dependensi yang diperlukan, dan mengkonfigurasi protokol VPN pilihan kamu.

</details>

---

<div align="center">

## `📡 PROTOKOL YANG TERSEDIA`

</div>

<div align="center">

| Protokol | Tipe Koneksi | Port | Enkripsi |
|:---:|:---:|:---:|:---:|
| **SSH WebSocket TLS** | TLS | 443 | SSL/TLS |
| **SSH WebSocket Non-TLS** | Non-TLS | 80 | Tunnel |
| **SSH Slow DNS** | Multipath | DNS | Tunnel |
| **SSH UDP** | Multipath | UDP | Tunnel |
| **Xray VMess WebSocket** | TLS & Non-TLS | 443 / 80 | AES-128-GCM |
| **Xray VLESS WebSocket** | TLS & Non-TLS | 443 / 80 | None / XTLS |
| **Xray Trojan WebSocket** | TLS & Non-TLS | 443 / 80 | TLS |
| **Xray Trojan TCP XTLS** | XTLS | 443 | XTLS |
| **Xray Trojan TCP TLS** | TLS | 443 | TLS |
| **Shadowsocks WS/gRPC** | WS / gRPC | 443 / 80 | ChaCha20 |

</div>

---

<div align="center">

## `🛠️ FITUR MANAJEMEN`

</div>

```
┌─────────────────────────────────────────────────────────────────┐
│                    PANEL MANAJEMEN VPN                          │
├─────────────────────────────────────────────────────────────────┤
│  ✅  Tambah / Hapus / Perpanjang akun semua protokol           │
│  ✅  Cek status akun & tanggal expired                         │
│  ✅  Monitor penggunaan bandwidth per user                     │
│  ✅  Monitor trafik real-time                                  │
│  ✅  Restart semua layanan VPN sekaligus                       │
│  ✅  Clear log server otomatis                                 │
│  ✅  Backup & restore konfigurasi via GitHub                   │
│  ✅  Generate sertifikat SSL otomatis                          │
│  ✅  Limit kecepatan per user                                  │
│  ✅  Auto reboot terjadwal                                     │
│  ✅  Manajemen RAM & CPU                                       │
│  ✅  Webmin panel management                                   │
└─────────────────────────────────────────────────────────────────┘
```

---

<div align="center">

## `📦 SISTEM YANG DIDUKUNG`

</div>

<div align="center">

| Sistem Operasi | Versi | Status |
|:---:|:---:|:---:|
| Ubuntu | 20.04 LTS (Focal) | ✅ **Direkomendasikan** |
| Ubuntu | 22.04 LTS (Jammy) | ✅ Didukung |
| Ubuntu | 24.04 LTS (Noble) | ✅ Didukung |
| Ubuntu | 18.04 LTS | ⚠️ Dukungan Terbatas |
| Debian | 10 / 11 / 12 | ✅ Didukung |

</div>

---

<div align="center">

## `📌 PANDUAN INSTALASI LENGKAP`

</div>

### ① Persiapkan Server

Login ke server sebagai `root`, lalu jalankan:

```bash
apt-get update && apt-get upgrade -y && apt dist-upgrade -y && update-grub && reboot
```

### ② Jalankan Installer

Setelah server kembali online:

```bash
wget -O setup.sh https://raw.githubusercontent.com/winsdevcltr09/autoInstall-premium/main/setupku.sh && chmod +x setup.sh && ./setup.sh
```

### ③ Ikuti Panduan di Layar

Script akan meminta:
- **Domain / subdomain** untuk sertifikat SSL
- **Protokol** yang ingin diaktifkan
- **Port** yang akan digunakan

### ④ Akses Menu Utama

Setelah instalasi selesai, akses menu dengan mengetik:

```bash
menu
```

---

<div align="center">

## `📞 KONTAK & SUPPORT`

<br/>

[![Telegram](https://img.shields.io/badge/TELEGRAM-@dcxii-9B59B6?style=for-the-badge&logo=telegram&logoColor=white&labelColor=0D0D0D)](https://t.me/dcxii)

<br/><br/>

<img src="https://readme-typing-svg.demolab.com?font=Share+Tech+Mono&size=13&duration=4000&pause=1000&color=6C3483&center=true&vCenter=true&width=520&lines=Script+by+DevCulture+XII+Store;Unauthorized+redistribution+is+prohibited.;%C2%A9+2024+DevCulture+XII+Store.+All+rights+reserved." alt="Footer typing" />

</div>

---

<div align="center">
<sub>
<code>[ SYSTEM ONLINE ]</code> &nbsp;&nbsp;|&nbsp;&nbsp; <code>[ ALL PROTOCOLS ACTIVE ]</code> &nbsp;&nbsp;|&nbsp;&nbsp; <code>[ ENCRYPTION: ENABLED ]</code>
</sub>
</div>
