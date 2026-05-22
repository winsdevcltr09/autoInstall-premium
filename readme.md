<!-- ═══════════════════════════════════════════════════════════════════════════
     ██████╗ ███████╗██╗   ██╗ ██████╗██╗   ██╗██╗  ████████╗██╗   ██╗██████╗ ███████╗
     ██╔══██╗██╔════╝██║   ██║██╔════╝██║   ██║██║  ╚══██╔══╝██║   ██║██╔══██╗██╔════╝
     ██║  ██║█████╗  ██║   ██║██║     ██║   ██║██║     ██║   ██║   ██║██████╔╝█████╗
     ██║  ██║██╔══╝  ╚██╗ ██╔╝██║     ██║   ██║██║     ██║   ██║   ██║██╔══██╗██╔══╝
     ██████╔╝███████╗ ╚████╔╝ ╚██████╗╚██████╔╝███████╗██║   ╚██████╔╝██║  ██║███████╗
     ╚═════╝ ╚══════╝  ╚═══╝   ╚═════╝ ╚═════╝ ╚══════╝╚═╝    ╚═════╝ ╚═╝  ╚═╝╚══════╝
     ════════════════════════════════════════════════════════════════════════════════ -->

<div align="center">

<img src="https://readme-typing-svg.demolab.com?font=Share+Tech+Mono&size=28&duration=2800&pause=1200&color=9B59B6&center=true&vCenter=true&multiline=true&width=700&height=100&lines=%5B+DEVCULTURE+XII+STORE+%5D;%E2%96%88+AUTO+INSTALL+VPN+PREMIUM+%E2%96%88" alt="Typing SVG" />

<br/>

<img src="https://readme-typing-svg.demolab.com?font=Share+Tech+Mono&size=15&duration=3000&pause=800&color=7D3C98&center=true&vCenter=true&width=600&lines=Initializing+cyberpunk+VPN+system...;Loading+encrypted+modules...;All+protocols+online.+Welcome%2C+Operator." alt="Subtitle" />

<br/><br/>

<img src="https://img.shields.io/badge/VERSION-3.0.0%20LTS-9B59B6?style=for-the-badge&logo=github&logoColor=white&labelColor=0D0D0D" />
<img src="https://img.shields.io/badge/OS-Ubuntu%20%7C%20Debian-7D3C98?style=for-the-badge&logo=linux&logoColor=white&labelColor=0D0D0D" />
<img src="https://img.shields.io/badge/SHELL-BASH-6C3483?style=for-the-badge&logo=gnubash&logoColor=white&labelColor=0D0D0D" />
<img src="https://img.shields.io/badge/STATUS-ACTIVE-8E44AD?style=for-the-badge&logo=statuspage&logoColor=white&labelColor=0D0D0D" />

<br/><br/>

```
 ╔══════════════════════════════════════════════════════════════════╗
 ║  ░░░░░░░░░░░░  DEVCULTURE XII STORE — VPN PREMIUM  ░░░░░░░░░░  ║
 ║  ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓  ║
 ║  [ SSH-WS ]  [ VMESS ]  [ VLESS ]  [ TROJAN ]  [ SS-WS ]      ║
 ╚══════════════════════════════════════════════════════════════════╝
```

</div>

---

<div align="center">

## `⚡ INSTALASI SATU PERINTAH ⚡`

</div>

> **Persiapan wajib** — jalankan perintah berikut sebelum instalasi untuk memastikan server siap:

```bash
apt-get update && apt-get upgrade -y && apt dist-upgrade -y && update-grub && reboot
```

> ⚠️ Server akan **reboot**. Setelah menyala kembali, jalankan perintah instalasi di bawah ini.

<br/>

<div align="center">

### 🟣 `INSTALL OTOMATIS — SATU KLIK`

</div>

```bash
wget -O setup.sh https://raw.githubusercontent.com/winsdevcltr09/autoInstall-premium/main/setupku.sh && chmod +x setup.sh && ./setup.sh
```

<details>
<summary><b>📋 Penjelasan detail perintah di atas</b></summary>

<br/>

| Bagian | Fungsi |
|--------|--------|
| `wget -O setup.sh <url>` | Mengunduh file `setupku.sh` dari GitHub dan menyimpannya sebagai `setup.sh` di direktori aktif |
| `chmod +x setup.sh` | Memberikan izin eksekusi pada file yang baru diunduh |
| `./setup.sh` | Menjalankan installer utama secara langsung |

> Script akan otomatis mendeteksi OS, memasang dependensi, dan mengkonfigurasi semua protokol VPN yang dipilih.

</details>

---

<div align="center">

## `📡 PROTOKOL YANG TERSEDIA`

</div>

<table align="center">
<thead>
<tr>
<th>Protokol</th>
<th>Tipe</th>
<th>Port</th>
<th>Enkripsi</th>
</tr>
</thead>
<tbody>
<tr>
<td><b>🔵 SSH WebSocket</b></td>
<td>TLS &amp; Non-TLS</td>
<td>443 / 80</td>
<td>SSL/TLS</td>
</tr>
<tr>
<td><b>🔵 SSH Slow DNS</b></td>
<td>Multipath</td>
<td>DNS</td>
<td>Tunnel</td>
</tr>
<tr>
<td><b>🟣 Xray VMess WS</b></td>
<td>TLS &amp; Non-TLS</td>
<td>443 / 80</td>
<td>AES-128-GCM</td>
</tr>
<tr>
<td><b>🟣 Xray VLESS WS</b></td>
<td>TLS &amp; Non-TLS</td>
<td>443 / 80</td>
<td>None / XTLS</td>
</tr>
<tr>
<td><b>🔴 Xray Trojan WS</b></td>
<td>TLS &amp; Non-TLS</td>
<td>443 / 80</td>
<td>TLS</td>
</tr>
<tr>
<td><b>🔴 Xray Trojan TCP</b></td>
<td>XTLS / TLS</td>
<td>443</td>
<td>XTLS / TLS</td>
</tr>
<tr>
<td><b>⚫ Shadowsocks WS</b></td>
<td>WS / gRPC</td>
<td>443 / 80</td>
<td>ChaCha20</td>
</tr>
</tbody>
</table>

---

<div align="center">

## `🛠️ FITUR MANAJEMEN`

</div>

```
┌─────────────────────────────────────────────────────────────┐
│  ✅  Tambah / Hapus / Perpanjang akun semua protokol        │
│  ✅  Cek status akun & expired date                         │
│  ✅  Cek penggunaan bandwidth per user                      │
│  ✅  Monitor trafik real-time                               │
│  ✅  Restart semua layanan sekaligus                        │
│  ✅  Clear log otomatis                                     │
│  ✅  Backup & restore konfigurasi via GitHub                │
│  ✅  Generate SSL otomatis                                  │
│  ✅  Limit speed per user                                   │
│  ✅  Auto reboot terjadwal                                  │
│  ✅  Webmin panel management                                │
└─────────────────────────────────────────────────────────────┘
```

---

<div align="center">

## `📦 SISTEM YANG DIDUKUNG`

</div>

<div align="center">

| OS | Versi | Status |
|:--:|:-----:|:------:|
| Ubuntu | 20.04 LTS | ✅ Direkomendasikan |
| Ubuntu | 22.04 LTS | ✅ Didukung |
| Ubuntu | 24.04 LTS | ✅ Didukung |
| Ubuntu | 18.04 LTS | ⚠️ Terbatas |
| Debian | 10 / 11 / 12 | ✅ Didukung |

</div>

---

<div align="center">

## `📌 PANDUAN LENGKAP`

</div>

### Step 1 — Persiapkan Server

```bash
# Update & upgrade sistem
apt-get update && apt-get upgrade -y && apt dist-upgrade -y && update-grub && reboot
```

### Step 2 — Jalankan Installer

> Setelah server kembali online setelah reboot:

```bash
wget -O setup.sh https://raw.githubusercontent.com/winsdevcltr09/autoInstall-premium/main/setupku.sh && chmod +x setup.sh && ./setup.sh
```

### Step 3 — Ikuti Panduan di Layar

Script akan memandu kamu memilih:
- Domain / subdomain untuk SSL
- Protokol yang ingin diaktifkan
- Port yang digunakan

### Step 4 — Akses Menu Utama

Setelah instalasi selesai, jalankan menu utama dengan:

```bash
menu
```

---

<div align="center">

## `📞 KONTAK & SUPPORT`

<br/>

<a href="https://t.me/dcxii">
<img src="https://img.shields.io/badge/TELEGRAM-@dcxii-9B59B6?style=for-the-badge&logo=telegram&logoColor=white&labelColor=0D0D0D" />
</a>

<br/><br/>

<img src="https://readme-typing-svg.demolab.com?font=Share+Tech+Mono&size=13&duration=4000&pause=1000&color=6C3483&center=true&vCenter=true&width=500&lines=Script+by+DevCulture+XII+Store;Unauthorized+use+is+prohibited.;%C2%A9+2024+DevCulture+XII+Store" alt="Footer" />

</div>

---

<div align="center">
<sub>
<code>[ SYSTEM ONLINE ]</code> &nbsp;|&nbsp; <code>[ ALL PROTOCOLS ACTIVE ]</code> &nbsp;|&nbsp; <code>[ ENCRYPTION: ENABLED ]</code>
</sub>
</div>
