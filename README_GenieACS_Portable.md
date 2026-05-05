# GenieACS Portable Bundle (AIA Studio)

Dokumen ini menjelaskan cara pakai paket:

- `genieacs_portable_bundle_20260505_215404.zip`

## 1) Isi Paket

Setelah di-extract, struktur utamanya:

- `installer/install_one_click.sh` → installer otomatis
- `backup/genieacs_mongo.archive` → backup database MongoDB GenieACS
- `custom-ui/app-FOJWPRV7.js` → custom JS UI
- `custom-ui/app-LU66VFYW.css` → custom CSS UI
- `service/genieacs-*.service` → service systemd
- `service/genieacs.env` → environment GenieACS
- `docs/*` → informasi versi runtime

## 2) Kebutuhan Server

Disarankan server Ubuntu (20.04/22.04/24.04) dengan:

- Akses `sudo`
- Koneksi internet (untuk install package)
- Port yang dipakai GenieACS:
  - CWMP: `7547`
  - NBI: `7557`
  - FS: `7567`
  - UI: `3000`

## 3) Langkah Install (One Click)

1. Upload zip ke server
2. Extract:

```bash
unzip genieacs_portable_bundle_20260505_215404.zip
cd genieacs_portable_20260505_215404
```

3. Jalankan installer:

```bash
sudo bash installer/install_one_click.sh
```

Installer akan:

- Install Node.js (jika belum ada)
- Install MongoDB (jika belum ada)
- Install GenieACS global via npm
- Pasang file service systemd
- Pasang custom UI (JS/CSS)
- Buka port firewall UFW (7547/7557/7567/3000)
- Start service GenieACS

## 4) Restore Database (Opsional)

Kalau ingin sekaligus restore data lama:

```bash
sudo RESTORE_DB=1 bash installer/install_one_click.sh
```

## 5) Verifikasi Setelah Install

Cek service:

```bash
sudo systemctl status genieacs-cwmp genieacs-nbi genieacs-fs genieacs-ui
```

Harus `active (running)`.

Cek port listening:

```bash
ss -tulpen | egrep '7547|7557|7567|3000'
```

Akses UI:

- `http://IP_SERVER:3000`

## 6) Restart Service

Kalau perlu restart semua:

```bash
sudo systemctl restart genieacs-cwmp genieacs-nbi genieacs-fs genieacs-ui
```

## 7) Lokasi File Penting

- Env: `/opt/genieacs/genieacs.env`
- UI files: `/usr/lib/node_modules/genieacs/public/`
- Logs: `/var/log/genieacs/`
- Service: `/etc/systemd/system/genieacs-*.service`

## 8) Troubleshooting Singkat

### A) UI tidak berubah (masih style lama)

- Restart service UI:

```bash
sudo systemctl restart genieacs-ui
```

- Hard refresh browser: `Ctrl + F5`

### B) Service gagal start

Lihat log detail:

```bash
journalctl -u genieacs-ui -n 100 --no-pager
journalctl -u genieacs-cwmp -n 100 --no-pager
journalctl -u genieacs-nbi -n 100 --no-pager
journalctl -u genieacs-fs -n 100 --no-pager
```

### C) MongoDB belum jalan

```bash
sudo systemctl restart mongod
sudo systemctl status mongod
```

## 9) Catatan

Bundle ini membawa custom UI yang sudah dipakai sekarang. Jika ingin rollback, cukup ganti file JS/CSS di folder public GenieACS dengan backup sebelumnya.

---
Jika diperlukan, saya bisa buatkan versi installer berikutnya yang otomatis sekalian pasang Nginx + domain + SSL (Let's Encrypt).
