# StokFlow — Mobile Inventaris UMKM

[![CI Quality Gate](https://github.com/Cihaimasuiro/Mobile-Inventaris-Stockflow/actions/workflows/ci.yml/badge.svg)](https://github.com/Cihaimasuiro/Mobile-Inventaris-Stockflow/actions/workflows/ci.yml)

Aplikasi mobile operasional inventaris barang untuk pelaku UMKM berbasis **Flutter (Android & iOS)** dengan arsitektur **Offline-First**, pemindaian barcode kamera instan, dan integrasi backend **Stockflow REST API** ([Dokumentasi API](https://stokflow-be.vercel.app/docs#/)).

---

## 📚 Dokumen Spesifikasi & Desain
- [Product Requirements Document (PRD MVP Fase 1)](docs/prd_sistem_inventaris_umkm_mvp.md): Dokumen acuan spesifikasi alur produk, isolasi multi-business, skema tabel, dan aturan bisnis.
- [Mockup Visual High-Fidelity (PDF)](docs/Mockup%20Visual%20High-Fidelity%20StokFlow%20UMKM%20(MVP).pdf): Panduan antarmuka layar otentikasi, katalog produk, pemindai barcode kamera, dan form transaksi.

---

## 🎯 Ruang Lingkup MVP (Fase 1)

Mengikuti prinsip **YAGNI & Zero Over-Engineering**, pengembangan Fase 1 difokuskan pada kecepatan pencatatan transaksi toko/gudang:

| Modul | Termasuk di MVP (Fase 1) | Ditunda ke Fase Berikutnya |
|---|---|---|
| **Otentikasi & Akun** | Registrasi, Login & Logout Pemilik (`OWNER`) dengan deteksi antrean offline | Manajemen akun Staf (`STAFF`) & pembatasan peran *(Fase 2)* |
| **Master Produk** | Tambah, Edit, Arsipkan Produk, Barcode Scanner via kamera HP (`mobile_scanner`), Pencarian cepat lokal | Kategori produk *(Fase 2)*, Batch & Expired Date / FEFO *(Fase 3)* |
| **Transaksi Stok** | Barang Masuk (`STOCK_IN`) & Barang Keluar (`STOCK_OUT`), multi-item, validasi anti-stok-minus | *Stock Opname* terpandu *(Fase 3)*, Modul Kasir POS *(Fase 4)* |
| **Riwayat** | Riwayat transaksi berurutan waktu terbaru, filter `STOCK_IN` / `STOCK_OUT` | Ekspor laporan CSV / Excel *(Fase 2)*, Laba rugi kotor *(Fase 4)* |
| **Penyimpanan & Jaringan** | Offline-First (SQLite/Drift lokal < 0.5s), sinkronisasi otomatis latar belakang, UUID idempotent | Sinkronisasi multi-cabang / multi-gudang *(Fase 4)* |
| **Hardware / Aksesori** | Kamera internal HP (Lampu flash & auto-focus) | Printer thermal Bluetooth & cetak label barcode *(Fase 3)* |
| **Notifikasi** | Peringatan data belum tersinkron saat logout | Peringatan stok menipis (*Low Stock Alert*) *(Fase 3)* |

---

## 🛠️ Tech Stack & Dependensi Kunci

- **Platform**: Flutter (Android min SDK 21, iOS 13+)
- **Bahasa**: Dart
- **Database Lokal (Offline-First)**: `sqflite` / `drift` (SQLite engine)
- **Kamera & Pemindai Barcode**: `mobile_scanner` (dukungan EAN-13, UPC, QR Code)
- **Penyimpanan Kredensial**: `flutter_secure_storage` (Android Keystore / iOS Keychain)
- **HTTP Client**: `dio` dengan interceptor token JWT dan deteksi jaringan `connectivity_plus`
- **Backend API**: Stockflow REST API (`https://stokflow-be.vercel.app/api`)

---

## 🏛️ Arsitektur Proyek

Aplikasi disusun menggunakan **Pragmatic Layered Architecture**:

```text
lib/
├── core/
│   ├── constants/       # URL API, status sync, format kode transaksi
│   ├── network/         # HTTP client & connectivity handler
│   ├── storage/         # Database SQLite lokal & secure storage token
│   ├── theme/           # Desain UI minimalis (sesuai Mockup PDF)
│   └── utils/           # Format mata uang Rupiah, generator UUID v4
│
├── data/
│   ├── datasources/
│   │   ├── local/       # SQLite DAOs (Product, Transaction, SyncQueue)
│   │   └── remote/      # Stockflow REST API Service
│   ├── models/          # Model data dengan serialisasi JSON & SQLite
│   └── repositories/    # Implementasi repositori Offline-First
│
├── domain/
│   ├── entities/        # Entitas bisnis (Product, StockTransaction, Business, User)
│   └── repositories/    # Kontrak antarmuka repositori
│
└── presentation/
    ├── auth/            # Layar Login, Registrasi & Profil Bisnis
    ├── catalog/         # Layar Daftar Produk & Modal Scan Barcode
    ├── transactions/    # Form Transaksi Barang Masuk & Keluar
    ├── history/         # Layar Riwayat Transaksi & Filter
    └── shared/          # Komponen UI standar (button, input, badge status)
```

---

## ⚖️ Aturan Bisnis & Integritas Data

1. **Isolasi Multi-Business**: Setiap entitas data wajib memiliki `business_id`. Akses data antar-toko terisolasi secara ketat.
2. **Pencegahan Stok Minus**: Transaksi `STOCK_OUT` divalidasi ketat di perangkat lokal: `current_stock >= quantity`.
3. **Integritas Riwayat**: Produk yang telah memiliki riwayat transaksi tidak dapat dihapus secara permanen (*hard delete*), melainkan diubah statusnya menjadi `ARCHIVED`.
4. **Snapshot Harga Modal**: Setiap item transaksi menyimpan `unit_cost_snapshot` saat transaksi dibuat agar nilai buku historis tidak berubah bila harga modal master produk diperbarui di kemudian hari.
5. **Format Nomor Transaksi**: Format nomor transaksi otomatis mengikuti standar PRD: `[BUSINESS_CODE]-[TAHUN]-[NOMOR_URUT]`.

---

## 🚀 Alur Kerja Git & Percabangan (Branching Strategy)

Repository ini menerapkan arsitektur percabangan dua tingkat standar SIM-SARPRAS:

| Branch | Fungsi | Proteksi |
|---|---|---|
| `main` | Produksi & Rilis Resmi | **Protected** (Wajib PR, Review, & CI pass. Direct push dilarang). |
| `dev` | Cabang Kerja Aktif (*Default*) | **Default working branch** untuk pengerjaan harian. |
| `feature/*` | Cabang Fitur / Perbaikan | Dibuat dari `dev`, dimerge kembali ke `dev` via Pull Request. |

### Panduan Singkat Kontribusi:
1. Pastikan Anda berada di branch `dev` sebelum mulai:
   ```bash
   git checkout dev
   git pull origin dev
   ```
2. Buat cabang baru untuk fitur/perbaikan:
   ```bash
   git checkout -b feat/nama-fitur
   ```
3. Lakukan commit dengan format [Conventional Commits](https://www.conventionalcommits.org/):
   ```bash
   git commit -m "feat(catalog): implementasi scan barcode kamera dengan mobile_scanner"
   ```
4. Buka Pull Request menuju branch `dev`.
5. Rilis ke produksi dilakukan dengan membuat Pull Request dari `dev` ke `main`.

---

## 🔒 Konfigurasi Lingkungan

- Salin template konfigurasi:
  ```bash
  cp .env.example .env
  ```
- File `.env` dan berkas kredensial (`keystore`, sertifikat) dilarang keras di-commit ke repositori.
