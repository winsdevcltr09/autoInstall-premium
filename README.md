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

![Version](https://img.shields.io/badge/VERSI-3.1.0_LTS-9B59B6?style=flat-square&logo=github&logoColor=white&labelColor=0D0D0D)
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
- [Sistem Domain](#-sistem-domain-dual-mode)
- [Sistem yang Didukung](#-sistem-yang-didukung)
- [Rekomendasi VPS](#-rekomendasi-provider-vps)
- [Troubleshooting](#-troubleshooting)
- [Order Premium](#-order-premium-script)
- [Kontak](#-kontak--support)

---

## Tentang Project

**DEV CULTURE ELITE** adalah installer otomatis production-ready untuk infrastruktur VPN di VPS Ubuntu dan Debian. Satu perintah men-deploy stack VPN multi-protokol lengkap — **Xray VLESS/VMess/Trojan**, **SSH Websocket**, **Shadowsocks**, **SlowDNS**, **BadVPN**, dan **OpenVPN** — berikut konfigurasi domain, SSL otomatis, dan menu manajemen akun lengkap.

Dilengkapi **engine validasi preflight** yang memeriksa 18+ parameter sistem sebelum mengubah satu file pun. IP whitelist, auto-expire akun, dan Fail2ban sudah terintegrasi sejak awal.

> **Ini bukan script generik. Ini adalah otomasi infrastruktur yang dirancang untuk keandalan, keamanan, dan skalabilitas.**

---

## 🚀 Instalasi

> Jalankan sebagai **root** pada VPS yang baru dan bersih.

```bash
bash <(curl -Ls https://raw.githubusercontent.com/winsdevcltr09/autoInstall-premium/main/setupku.sh)
```

Installer akan secara otomatis:
- Mendeteksi OS dan memvalidasi environment
- Meminta input domain (pilih Mode Domain Owner atau Domain Pribadi)
- Menginstall semua dependensi dan protokol VPN
- Mengkonfigurasi SSL, nginx, dan seluruh layanan
- Menampilkan ringkasan hasil setelah selesai

Setelah instalasi, akses menu manajemen dengan perintah:

```bash
menu
```

<details>
<summary><b>Opsi instalasi lanjutan</b></summary>

<br/>

**Jika koneksi ke GitHub lambat, gunakan alternatif wget:**

```bash
wget -qO- https://raw.githubusercontent.com/winsdevcltr09/autoInstall-premium/main/setupku.sh | bash
```

**Flag tambahan (opsional):**

| Flag | Fungsi |
|:---|:---|
| `--domain vpn.namadomain.com` | Set domain langsung tanpa prompt interaktif |
| `--skip-preflight` | Lewati validasi preflight (hanya untuk debug) |

> ⚠️ Flag `--skip-preflight` tidak direkomendasikan untuk produksi.

</details>

---

## 🔄 Update

Perbarui semua script ke versi terbaru tanpa menghapus data akun:

```bash
updatsc
```

---

## 📡 Protokol yang Tersedia

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

## ⚙️ Fitur Manajemen

<div align="center">

| Kategori | Fitur |
|:---:|:---|
| **Akun** | Tambah, hapus, perpanjang masa aktif akun SSH / VMess / VLESS / Trojan / SS |
| **Monitoring** | Cek status akun, expired date, login aktif per protokol |
| **Preflight** | Validator 18 seksi otomatis sebelum install dimulai |
| **SSL Otomatis** | Generate & renew sertifikat SSL via Let's Encrypt (`acme.sh`) |
| **Domain** | Ganti domain kapan saja via perintah `addhost` — otomatis update DNS, SSL, nginx |
| **Cloudflare** | Deteksi orange-cloud, dynamic DNS otomatis via `cf.sh` |
| **IP Whitelist** | IP VPS harus terdaftar sebelum installer bisa berjalan |
| **Auto-Expire** | Akun expired dihapus otomatis setiap hari pukul 01:00 WIB |
| **Backup** | Backup konfigurasi manual sebelum reinstall |
| **Log** | Log install di `/root/log-install.txt`, preflight di `/tmp/preflight-*.log` |
| **Panel** | Akses menu utama lengkap via perintah `menu` |

</div>

---

## 🔒 Keamanan & Optimasi

- **Fail2ban** — aktif secara default, memblokir percobaan brute-force SSH
- **IP Whitelist** — IP VPS harus terdaftar sebelum installer bisa berjalan
- **Auto-Expire Cron** — akun expired dihapus otomatis setiap hari pukul 01:00 WIB
- **IPv6 Dinonaktifkan** — mengurangi attack surface via sysctl
- **TLS via acme.sh** — SSL Let's Encrypt auto-provisioned untuk semua protokol Xray
- **Isolasi akun** — data VPN disimpan di `/root/akun/` dengan `chmod 700`
- **iptables-persistent** — aturan firewall bertahan setelah reboot
- **Tidak ada credential hardcoded** — token Cloudflare disimpan di `/etc/xray/cf.conf`, tidak pernah tersimpan di kode

---

## 🌐 Sistem Domain (Dual Mode)

Script mendukung **dua mode konfigurasi domain** yang dipilih saat instalasi:

<div align="center">

| Mode | Keterangan | Cocok Untuk |
|:---:|:---|:---|
| **Mode 1** — Domain Owner | Subdomain dari domain owner script (`florezha.eu.org`) | Reseller / yang membeli script |
| **Mode 2** — Domain Pribadi | Domain milik sendiri + subdomain bebas | Pemilik domain sendiri |

</div>

### Mode 1 — Domain Owner

Tidak punya domain sendiri? Cukup pilih nama subdomain — domain utama sudah dikelola owner via Cloudflare.

```
Format : <subdomain>.florezha.eu.org
Contoh : sg1.florezha.eu.org / id01.florezha.eu.org
```

DNS Cloudflare didaftarkan otomatis. SSL di-generate otomatis.

### Mode 2 — Domain Pribadi

Punya domain sendiri? Pastikan A Record sudah pointing ke IP VPS sebelum install.

```
Format : <subdomain>.<domain_anda>
Contoh : sg1.myvpn.com / id01.vpn-ku.net
```

**Setup A Record:**
```
Nama  : sg1
Tipe  : A
Value : IP_VPS_ANDA
TTL   : 300
```

Tunggu propagasi DNS (5–60 menit), verifikasi dengan `nslookup sg1.namadomain.com`, lalu jalankan installer.

### Ganti Domain Setelah Install

```bash
addhost
```

Perintah `addhost` menangani seluruh proses secara otomatis: update DNS Cloudflare (Mode 1), update konfigurasi, generate ulang SSL, dan restart semua layanan.

### Konfigurasi Domain Tersimpan

| File | Format | Digunakan oleh |
|:---|:---|:---|
| `/etc/xray/domain` | `sg1.florezha.eu.org` | Xray, nginx, add-ws, add-vless, dll |
| `/var/lib/scrz-prem/ipvps.conf` | `IP=sg1.florezha.eu.org` | genssl, add-ws, add-tr, add-ssws |
| `/root/domain` | `sg1.florezha.eu.org` | addhost, backup |
| `/etc/xray/domain.conf` | Structured config | referensi terstruktur |

---

## 💻 Sistem yang Didukung

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

## 🖥️ Rekomendasi Provider VPS

<div align="center">

| Provider | Segmen | Keunggulan |
|:---:|:---:|:---|
| **DigitalOcean** | Menengah | Kompatibilitas Ubuntu andal, provisioning cepat |
| **Vultr** | Menengah | Data center global, virtualisasi KVM |
| **Linode / Akamai** | Menengah–Tinggi | Performa stabil, instance KVM |
| **Hetzner** | Performa Tinggi | Rasio harga-performa terbaik untuk VPN |
| **OVHcloud** | Enterprise | Infrastruktur Eropa, opsi bandwidth unmetered |
| **Contabo** | Budget | RAM/storage tinggi per harga |

</div>

**Spesifikasi Minimum:**

| Parameter | Minimum | Direkomendasikan |
|---|---|---|
| OS | Ubuntu 20.04 LTS | Ubuntu 22.04 / 24.04 LTS |
| RAM | 512 MB | 1 GB+ |
| CPU | 1 vCPU | 2 vCPU |
| Storage | 10 GB | 20 GB SSD |
| Virtualisasi | KVM (utama) | KVM — OpenVZ punya keterbatasan TUN/TAP |

---

## 🛠️ Troubleshooting

<details>
<summary><b>Domain tidak mengarah ke VPS</b></summary>

```bash
nslookup vpn.namadomain.com
# Pastikan A Record sudah pointing ke IP VPS
# Tunggu propagasi DNS 5–60 menit
```

Jika sudah propagasi tapi masih gagal, jalankan ulang:
```bash
addhost
```
</details>

<details>
<summary><b>SSL gagal di-generate</b></summary>

```bash
# Pastikan port 80 tidak diblokir provider VPS
ss -tlnp | grep ':80 '

# Jalankan generate SSL manual setelah DNS propagasi:
genssl
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

## 💎 Order Premium Script

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

## 📬 Kontak & Support

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
