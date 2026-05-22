<div align="center">

<img src="https://raw.githubusercontent.com/winsdevcltr09/autoInstall-premium/main/assets/banner.png" alt="DevCulture XII Store" width="100%" />

<br/>

<img src="https://readme-typing-svg.demolab.com?font=Share+Tech+Mono&size=24&duration=2800&pause=1000&color=9B59B6&center=true&vCenter=true&width=680&height=55&lines=DevCulture+XII+Store+%E2%80%94+VPN+Premium;SSH+%7C+VMess+%7C+VLESS+%7C+Trojan+%7C+Shadowsocks;Auto+Install+%7C+Multi+Protocol+%7C+Full+Managed" alt="Typing" />

<img src="https://readme-typing-svg.demolab.com?font=Share+Tech+Mono&size=12&duration=3500&pause=900&color=6C3483&center=true&vCenter=true&width=580&lines=Initializing+encrypted+tunnel...;Loading+protocol+modules...;All+systems+operational.+Welcome%2C+Operator." alt="Subtitle" />

<br/>

![Stars](https://img.shields.io/github/stars/winsdevcltr09/autoInstall-premium?style=for-the-badge&logo=github&color=9B59B6&labelColor=0D0D0D&logoColor=white)
![Forks](https://img.shields.io/github/forks/winsdevcltr09/autoInstall-premium?style=for-the-badge&logo=github&color=7D3C98&labelColor=0D0D0D&logoColor=white)
![Last Commit](https://img.shields.io/github/last-commit/winsdevcltr09/autoInstall-premium?style=for-the-badge&logo=git&color=6C3483&labelColor=0D0D0D&logoColor=white)
![Repo Size](https://img.shields.io/github/repo-size/winsdevcltr09/autoInstall-premium?style=for-the-badge&logo=files&color=8E44AD&labelColor=0D0D0D&logoColor=white)

![Version](https://img.shields.io/badge/VERSION-3.0.0_LTS-9B59B6?style=flat-square&logo=github&logoColor=white&labelColor=0D0D0D)
![Ubuntu](https://img.shields.io/badge/Ubuntu-20.04_%7C_22.04_%7C_24.04-7D3C98?style=flat-square&logo=ubuntu&logoColor=white&labelColor=0D0D0D)
![Debian](https://img.shields.io/badge/Debian-10_%7C_11_%7C_12-6C3483?style=flat-square&logo=debian&logoColor=white&labelColor=0D0D0D)
![Shell](https://img.shields.io/badge/Shell-Bash-8E44AD?style=flat-square&logo=gnubash&logoColor=white&labelColor=0D0D0D)
![Status](https://img.shields.io/badge/Status-Active-27AE60?style=flat-square&labelColor=0D0D0D)

</div>

<br/>

---

## Daftar Isi

- [Persiapan Server](#-persiapan-server)
- [Instalasi](#-instalasi)
- [Protokol](#-protokol-yang-tersedia)
- [Fitur Manajemen](#-fitur-manajemen)
- [Sistem yang Didukung](#-sistem-yang-didukung)
- [Panduan Lengkap](#-panduan-instalasi-lengkap)
- [Kontak](#-kontak--support)

---

## Persiapan Server

> Wajib dijalankan sebelum instalasi. Memperbarui seluruh paket sistem dan melakukan reboot.

```bash
apt-get update && apt-get upgrade -y && apt dist-upgrade -y && update-grub && reboot
```

> [!WARNING]
> Server akan **reboot** setelah perintah ini. Tunggu hingga server kembali online sebelum melanjutkan instalasi.

---

## Instalasi

> Setelah server kembali online, jalankan perintah berikut:

```bash
wget https://raw.githubusercontent.com/winsdevcltr09/autoInstall-premium/main/setupku.sh && chmod +x setupku.sh && ./setupku.sh
```

<details>
<summary><b>Penjelasan detail perintah instalasi</b></summary>

<br/>

| Perintah | Fungsi |
|:---|:---|
| `wget <url>` | Mengunduh file `setupku.sh` dari GitHub ke direktori aktif |
| `&&` | Menjalankan perintah berikutnya hanya jika perintah sebelumnya berhasil |
| `chmod +x setupku.sh` | Memberikan izin eksekusi pada file `setupku.sh` |
| `./setupku.sh` | Menjalankan installer |

> Script akan otomatis **mendeteksi OS**, menginstal semua dependensi, dan mengkonfigurasi protokol VPN sesuai pilihan kamu.

</details>

---

## Protokol yang Tersedia

<div align="center">

| # | Protokol | Mode | Port | Enkripsi |
|:---:|:---|:---:|:---:|:---:|
| 01 | SSH WebSocket | TLS | 443 | SSL/TLS |
| 02 | SSH WebSocket | Non-TLS | 80 | Plain |
| 03 | SSH Slow DNS | Multipath | DNS | Tunnel |
| 04 | SSH UDP | Multipath | Custom | Tunnel |
| 05 | Xray VMess WebSocket | TLS / Non-TLS | 443 / 80 | AES-128-GCM |
| 06 | Xray VLESS WebSocket | TLS / Non-TLS | 443 / 80 | XTLS / None |
| 07 | Xray Trojan WebSocket | TLS / Non-TLS | 443 / 80 | TLS |
| 08 | Xray Trojan TCP | XTLS | 443 | XTLS |
| 09 | Xray Trojan TCP | TLS | 443 | TLS |
| 10 | Shadowsocks | WS / gRPC | 443 / 80 | ChaCha20-Poly1305 |

</div>

---

## Fitur Manajemen

<div align="center">

| Kategori | Fitur |
|:---:|:---|
| **Akun** | Tambah, hapus, perpanjang masa aktif akun semua protokol |
| **Monitoring** | Cek status akun, expired date, dan penggunaan bandwidth per user |
| **Jaringan** | Monitor trafik real-time, limit kecepatan per user |
| **Sistem** | Restart layanan, clear log, jadwal auto reboot, monitor RAM & CPU |
| **Keamanan** | Generate sertifikat SSL otomatis via `genssl.sh` |
| **Backup** | Backup dan restore konfigurasi via GitHub (`menu-bckp-github.sh`) |
| **Panel** | Akses Webmin panel berbasis web (`webmin.sh`) |

</div>

---

## Sistem yang Didukung

<div align="center">

| Sistem Operasi | Versi | Keterangan |
|:---:|:---:|:---|
| **Ubuntu** | 20.04 LTS | Direkomendasikan — paling stabil |
| **Ubuntu** | 22.04 LTS | Didukung penuh |
| **Ubuntu** | 24.04 LTS | Didukung penuh |
| **Ubuntu** | 18.04 LTS | Dukungan terbatas |
| **Debian** | 10 / 11 / 12 | Didukung penuh |

</div>

---

## Panduan Instalasi Lengkap

### 1 — Perbarui dan Siapkan Server

Login sebagai **root**, lalu jalankan:

```bash
apt-get update && apt-get upgrade -y && apt dist-upgrade -y && update-grub && reboot
```

### 2 — Jalankan Installer Setelah Reboot

Setelah server kembali online:

```bash
wget https://raw.githubusercontent.com/winsdevcltr09/autoInstall-premium/main/setupku.sh && chmod +x setupku.sh && ./setupku.sh
```

### 3 — Ikuti Panduan di Layar

Installer akan meminta:

- **Domain / subdomain** — untuk sertifikat SSL otomatis
- **Protokol** — pilih protokol yang ingin diaktifkan
- **Port** — sesuaikan dengan kebutuhan

### 4 — Akses Menu Utama

Setelah instalasi selesai, ketik:

```bash
menu
```

---

## Kontak & Support

<div align="center">

<br/>

[![Telegram](https://img.shields.io/badge/Telegram-@dcxii-9B59B6?style=for-the-badge&logo=telegram&logoColor=white&labelColor=0D0D0D)](https://t.me/dcxii09)

<br/><br/>

<img src="https://readme-typing-svg.demolab.com?font=Share+Tech+Mono&size=12&duration=4000&pause=1000&color=5B2C6F&center=true&vCenter=true&width=560&lines=Script+by+DevCulture+XII+Store;Dilarang+mendistribusikan+ulang+tanpa+izin.;Copyright+2024+DevCulture+XII+Store.+All+rights+reserved." alt="Footer" />

<br/>

<sub><code>[ SYSTEM ONLINE ]</code> &nbsp;·&nbsp; <code>[ ALL PROTOCOLS ACTIVE ]</code> &nbsp;·&nbsp; <code>[ ENCRYPTION ENABLED ]</code></sub>

</div>
