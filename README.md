<div align="center">

<img src="https://raw.githubusercontent.com/winsdevcltr09/autoInstall-premium/main/assets/cyberpunk-banner.png" alt="DevCulture XII Store - VPN Premium" width="100%" />

<br/><br/>

<img src="https://readme-typing-svg.demolab.com?font=Share+Tech+Mono&size=28&duration=2500&pause=1000&color=9B59B6&center=true&vCenter=true&width=700&height=60&lines=DevCulture+XII+Store+%E2%80%94+VPN+Premium;Auto+Install+%7C+Multi+Protocol+%7C+Full+Managed" alt="Typing SVG" />

<br/>

<img src="https://readme-typing-svg.demolab.com?font=Share+Tech+Mono&size=13&duration=3500&pause=800&color=7D3C98&center=true&vCenter=true&width=620&lines=Initializing+encrypted+tunnel...;SSH+%7C+VMess+%7C+VLESS+%7C+Trojan+%7C+Shadowsocks+online.;All+systems+operational.+Welcome%2C+Operator." alt="Subtitle" />

<br/><br/>

![Version](https://img.shields.io/badge/VERSION-3.0.0%20LTS-9B59B6?style=for-the-badge&logo=github&logoColor=white&labelColor=0D0D0D)
![OS](https://img.shields.io/badge/OS-Ubuntu%20%7C%20Debian-7D3C98?style=for-the-badge&logo=linux&logoColor=white&labelColor=0D0D0D)
![Shell](https://img.shields.io/badge/SHELL-BASH-6C3483?style=for-the-badge&logo=gnubash&logoColor=white&labelColor=0D0D0D)
![Status](https://img.shields.io/badge/STATUS-ACTIVE-8E44AD?style=for-the-badge&logo=statuspage&logoColor=white&labelColor=0D0D0D)

</div>

---

<div align="center">

## INSTALASI SATU PERINTAH

</div>

> **Langkah 1 — Update server terlebih dahulu** (wajib sebelum instalasi):

```bash
apt-get update && apt-get upgrade -y && apt dist-upgrade -y && update-grub && reboot
```

> Server akan **reboot**. Setelah kembali online, lanjutkan ke langkah berikutnya.

<br/>

> **Langkah 2 — Jalankan installer** (salin dan tempel seluruh perintah di bawah, lalu tekan Enter):

```bash
wget -O setup.sh https://raw.githubusercontent.com/winsdevcltr09/autoInstall-premium/main/setupku.sh && chmod +x setup.sh && ./setup.sh
```

<details>
<summary><b>Penjelasan detail setiap bagian perintah instalasi</b></summary>

<br/>

| Bagian Perintah | Penjelasan |
|:---|:---|
| `wget -O setup.sh <url>` | Mengunduh file `setupku.sh` dari GitHub dan menyimpannya sebagai `setup.sh` di server |
| `&&` | Operator berantai — perintah berikutnya hanya berjalan jika perintah sebelumnya **berhasil** |
| `chmod +x setup.sh` | Memberikan izin eksekusi pada file yang baru diunduh agar bisa dijalankan oleh sistem |
| `./setup.sh` | Menjalankan installer langsung dari direktori aktif |

> Script akan otomatis **mendeteksi OS**, memasang dependensi yang diperlukan, dan mengkonfigurasi semua protokol VPN yang kamu pilih.

</details>

---

<div align="center">

## PROTOKOL YANG TERSEDIA

</div>

<div align="center">

| Protokol | Tipe | Port | Enkripsi |
|:---:|:---:|:---:|:---:|
| **SSH WebSocket TLS** | TLS | 443 | SSL/TLS |
| **SSH WebSocket Non-TLS** | Non-TLS | 80 | Tunnel |
| **SSH Slow DNS** | Multipath | DNS | Tunnel |
| **SSH UDP** | Multipath | UDP | Tunnel |
| **Xray VMess WebSocket** | TLS & Non-TLS | 443 / 80 | AES-128-GCM |
| **Xray VLESS WebSocket** | TLS & Non-TLS | 443 / 80 | XTLS / None |
| **Xray Trojan WebSocket** | TLS & Non-TLS | 443 / 80 | TLS |
| **Xray Trojan TCP XTLS** | XTLS | 443 | XTLS |
| **Xray Trojan TCP TLS** | TLS | 443 | TLS |
| **Shadowsocks WS/gRPC** | WS / gRPC | 443 / 80 | ChaCha20 |

</div>

---

<div align="center">

## FITUR MANAJEMEN

</div>

<div align="center">

| Fitur | Keterangan |
|:---|:---|
| Kelola Akun | Tambah, hapus, dan perpanjang akun semua protokol |
| Monitor Akun | Cek status akun dan tanggal expired |
| Bandwidth | Monitor penggunaan bandwidth per user |
| Trafik | Monitor trafik jaringan real-time |
| Restart Layanan | Restart semua layanan VPN sekaligus |
| Clear Log | Bersihkan log server secara otomatis |
| Backup & Restore | Backup dan restore konfigurasi via GitHub |
| SSL Generator | Generate sertifikat SSL otomatis |
| Limit Speed | Atur batas kecepatan per user |
| Auto Reboot | Jadwalkan reboot otomatis server |
| Webmin Panel | Akses panel manajemen berbasis web |

</div>

---

<div align="center">

## SISTEM YANG DIDUKUNG

</div>

<div align="center">

| Sistem Operasi | Versi | Status |
|:---:|:---:|:---:|
| Ubuntu | 20.04 LTS | **Direkomendasikan** |
| Ubuntu | 22.04 LTS | Didukung |
| Ubuntu | 24.04 LTS | Didukung |
| Ubuntu | 18.04 LTS | Dukungan Terbatas |
| Debian | 10 / 11 / 12 | Didukung |

</div>

---

<div align="center">

## PANDUAN STEP-BY-STEP

</div>

### Langkah 1 — Update dan Persiapkan Server

Login ke server sebagai **root**, lalu jalankan:

```bash
apt-get update && apt-get upgrade -y && apt dist-upgrade -y && update-grub && reboot
```

### Langkah 2 — Jalankan Installer Setelah Reboot

Tunggu server kembali online, lalu jalankan satu perintah ini:

```bash
wget -O setup.sh https://raw.githubusercontent.com/winsdevcltr09/autoInstall-premium/main/setupku.sh && chmod +x setup.sh && ./setup.sh
```

### Langkah 3 — Ikuti Panduan di Layar

Script akan meminta:
- **Domain atau subdomain** untuk sertifikat SSL
- **Protokol** yang ingin diaktifkan
- **Port** yang akan digunakan

### Langkah 4 — Akses Menu Utama

Setelah instalasi selesai, ketik perintah berikut untuk membuka menu pengelolaan:

```bash
menu
```

---

<div align="center">

## KONTAK DAN SUPPORT

<br/>

[![Telegram](https://img.shields.io/badge/TELEGRAM-@dcxii-9B59B6?style=for-the-badge&logo=telegram&logoColor=white&labelColor=0D0D0D)](https://t.me/dcxii)

<br/><br/>

<img src="https://readme-typing-svg.demolab.com?font=Share+Tech+Mono&size=13&duration=4000&pause=1000&color=6C3483&center=true&vCenter=true&width=540&lines=Script+by+DevCulture+XII+Store;Unauthorized+redistribution+is+prohibited.;Copyright+2024+DevCulture+XII+Store.+All+rights+reserved." alt="Footer" />

</div>

---

<div align="center">
<sub>
<code>[ SYSTEM ONLINE ]</code> &nbsp;|&nbsp; <code>[ ALL PROTOCOLS ACTIVE ]</code> &nbsp;|&nbsp; <code>[ ENCRYPTION: ENABLED ]</code>
</sub>
</div>
