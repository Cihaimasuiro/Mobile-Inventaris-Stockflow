# PRD - [STOKFLOW / INVENTARIS UMKM]
**Versi:** MVP (Fase 1)  
**Platform:** Mobile App (Flutter — Android & iOS)  
**Model Produk:** Multi-business SaaS (Shared Database, Shared Schema)  
**Tagline:** Pencatatan dan Pengelolaan Stok Barang UMKM Secara Cepat & Offline-First  

---

## 1. Ringkasan Produk
Aplikasi ini adalah platform mobile untuk membantu pelaku Usaha Mikro, Kecil, dan Menengah (UMKM) mencatat dan mengelola pergerakan inventaris barang secara akurat, ringan, dan dapat digunakan dalam kondisi internet tidak stabil (*offline-first*).

**MVP berfokus pada:**
* Autentikasi pemilik usaha (`OWNER`) dan isolasi data antar-bisnis (`business_id`)
* Pencatatan master data produk & pemindaian *barcode* via kamera HP
* Pencatatan barang masuk (`STOCK_IN`) dan barang keluar (`STOCK_OUT`)
* Riwayat transaksi dan jumlah stok terkini (*real-time* secara lokal)
* Penyimpanan lokal (*offline-first*) dengan sinkronisasi otomatis ke *cloud*

*(Fitur multi-user/staf, ekspor laporan Excel, dan peringatan stok menipis belum termasuk di MVP agar pengembangan cepat dan terfokus).*

---

## 2. Latar Belakang
Pencatatan stok pada mayoritas UMKM masih dilakukan menggunakan buku tulis atau *spreadsheet* terpisah yang rentan salah hitung.

**Masalah yang sering terjadi:**
* Selisih antara stok fisik dengan catatan pembukuan.
* Pencatatan barang masuk dan keluar memakan waktu lama karena harus menulis manual.
* Sinyal internet di area gudang atau ruko sering tidak stabil sehingga aplikasi berbasis *cloud* murni gagal menyimpan transaksi.
* Data barang dan riwayat keluar-masuk mudah hilang atau tertukar.

Aplikasi ini menyelesaikan masalah tersebut melalui sistem pencatatan transaksi mobile yang sederhana, *offline-first*, dan mendukung *scan barcode* langsung dari kamera HP.

---

## 3. Visi Produk
Menjadi aplikasi mobile operasional inventaris paling ringan, cepat, dan andal bagi pelaku UMKM di Indonesia dalam mendigitalisasi pengelolaan stok harian.

## 4. Misi Produk
* Mendigitalisasi proses pencatatan barang masuk dan keluar secara instan.
* Memastikan operasional pencatatan tetap berjalan tanpa hambatan koneksi internet (*offline-first*).
* Mengurangi kesalahan pencatatan manual melalui pemindaian *barcode* kamera.
* Menyediakan fondasi arsitektur *multi-business* yang siap dikembangkan ke fitur operasional lanjutan.

---

## 5. Tujuan MVP

### Tujuan Utama
* Mempercepat waktu pencatatan transaksi stok menjadi kurang dari 15 detik per transaksi.
* Menjamin 0% kehilangan data transaksi saat perangkat berada dalam mode *offline*.
* Menyediakan informasi jumlah stok terkini secara akurat.
* Memastikan isolasi data antar-bisnis/toko (`business_id`) berjalan ketat.

### Tujuan Bisnis
* Memvalidasi alur pencatatan inti pada pengguna UMKM secara cepat.
* Menyediakan produk dasar yang siap diuji coba dan diadopsi oleh toko ritel, grosir, maupun F&B.
* Menyiapkan fondasi ekosistem digital UMKM yang terintegrasi.

---

## 6. Definisi Istilah

| Istilah | Definisi |
| :--- | :--- |
| **Business / Store** | Entitas usaha atau toko UMKM yang terdaftar pada platform |
| **Super Admin (`SUPER_ADMIN`)** | Pengelola platform secara keseluruhan |
| **Owner (`OWNER`)** | Pemilik usaha yang mengelola data produk dan mencatat transaksi pada tahap MVP |
| **Produk (`Product`)** | Data master barang dagangan yang memiliki SKU/Barcode, satuan, harga, dan jumlah stok |
| **Stock In** | Transaksi penambahan stok (pembelian dari pemasok atau retur pelanggan) |
| **Stock Out** | Transaksi pengurangan stok (barang terjual, barang rusak, atau pemakaian internal) |
| **Offline-First** | Arsitektur aplikasi yang menyimpan data ke database lokal perangkat terlebih dahulu sebelum disinkronkan ke server *cloud* |

---

## 7. Target Pengguna
Aplikasi ini dirancang untuk berbagai sektor UMKM:
* Toko kelontong & minimarket mandiri
* Toko pakaian, aksesoris, & distro
* Toko bangunan & elektronik
* Usaha kuliner / F&B (bahan baku)
* Agen distributor & grosir skala kecil-menengah

**Persona 1: Pemilik Usaha (`OWNER`)**  
Membutuhkan aplikasi mobile yang praktis untuk mencatat stok masuk/keluar sendiri dengan cepat, tanpa perlu koneksi internet yang selalu stabil.

**Persona 2: Super Admin (`SUPER_ADMIN`)**  
Membutuhkan kemampuan memantau status aktif akun bisnis dan kesehatan sinkronisasi platform.

---

## 8. Model Multi-Business
Aplikasi menggunakan pendekatan **Shared Database, Shared Schema**. Seluruh bisnis UMKM menggunakan tabel yang sama di server *cloud*, namun setiap data wajib memiliki `business_id`.

Setiap bisnis memiliki ruang data terisolasi untuk:
* Master data produk
* Riwayat transaksi `STOCK_IN` dan `STOCK_OUT`
* Akun pengguna (`OWNER`)

---

## 9. Ruang Lingkup MVP

### Termasuk dalam MVP
* Registrasi, login, dan logout (`OWNER`)
* Manajemen master data produk dasar (Tambah, Lihat, Edit, Hapus/Arsip)
* Pemindaian *barcode* via kamera HP (*mobile scanner*)
* Transaksi Barang Masuk (`STOCK_IN`)
* Transaksi Barang Keluar (`STOCK_OUT`)
* Pencarian produk (berdasarkan nama atau *barcode*)
* Riwayat transaksi dasar
* Penyimpanan lokal (*offline-first*) dan sinkronisasi otomatis ke *cloud*
* Isolasi data antar-bisnis (`business_id`)

### Tidak Termasuk dalam MVP
* **Peringatan stok menipis (*Low Stock Alert*)**
* **Manajemen multi-user / akun Staf (`STAFF`) & pembatasan hak akses**
* **Kategori produk & ekspor laporan CSV/Excel**
* *Stock Opname* terpandu dengan perhitungan selisih otomatis
* Multi-gudang atau multi-cabang
* Cetak label *barcode* & struk ke printer *thermal* Bluetooth
* Manajemen *Supplier* & pembuatan *Purchase Order* (PO)
* Pelacakan *batch* dan tanggal kedaluwarsa (*Expired Date* / FEFO)
* Modul kasir (POS) lengkap

---

## 10. Peran dan Hak Akses

### 10.1 Super Admin (`SUPER_ADMIN`)
* Melihat daftar bisnis terdaftar (`businesses`)
* Mengaktifkan atau menonaktifkan status layanan bisnis
* Tidak dapat mengakses rincian operasional bisnis tanpa otorisasi dukungan teknis

### 10.2 Owner (`OWNER`)
* Mengelola profil bisnis
* Menambah, mengedit, dan mengarsipkan master data produk
* Memindai *barcode* produk via kamera
* Mencatat transaksi `STOCK_IN` dan `STOCK_OUT`
* Melihat seluruh daftar stok dan riwayat transaksi bisnisnya

---

## 11. Alur Utama Produk

### 11.1 Registrasi & Setup Awal
```text
Owner mengunduh aplikasi Flutter
  ↓
Registrasi akun & membuat profil bisnis
  ↓
Menambahkan produk awal (manual atau scan barcode)
  ↓
Data tersimpan di database lokal & tersinkron ke cloud
```

### 11.2 Pencatatan Barang Masuk / Keluar
```text
Owner membuka menu Transaksi
  ↓
Memilih jenis transaksi (Barang Masuk / Barang Keluar)
  ↓
Memindai barcode produk via kamera atau mencari nama barang
  ↓
Memasukkan jumlah (quantity) dan catatan opsional
  ↓
Konfirmasi transaksi
  ↓
Stok lokal langsung terbarui & masuk antrean sinkronisasi cloud
```

---

## 12. Kebutuhan Fungsional

### 12.1 Autentikasi
* **FR-01:** Sistem menyediakan fitur registrasi dan login menggunakan Email atau Nomor HP beserta Password/PIN.
* **FR-02:** Sistem menyediakan fitur logout dengan peringatan jika masih terdapat data *offline* yang belum tersinkronisasi.
* **FR-03:** Sistem memvalidasi status aktif pengguna dan bisnis sebelum mengizinkan akses.

### 12.2 Master Data Produk
* **FR-04:** `OWNER` dapat menambahkan produk baru dengan atribut wajib: Nama Produk, Satuan (*pcs, dus, kg, pack*), Harga Jual, dan Stok Awal.
* **FR-05:** Atribut SKU/Barcode dan Harga Modal bersifat opsional saat input awal.
* **FR-06:** `OWNER` dapat memindai *barcode* (EAN-13, UPC, QR) menggunakan kamera perangkat untuk mengisi kolom kode barang secara otomatis.
* **FR-07:** Sistem mencegah duplikasi kode *barcode* dalam satu `business_id` yang sama.
* **FR-08:** `OWNER` dapat mengubah informasi produk atau mengarsipkan produk yang sudah tidak dijual.

### 12.3 Pencarian Produk
* **FR-09:** `OWNER` dapat mencari produk berdasarkan nama atau kode SKU/Barcode secara *case-insensitive*.
* **FR-10:** Pencarian membaca langsung dari database lokal perangkat sehingga hasil muncul instan tanpa koneksi internet.
* **FR-11:** `OWNER` dapat memindai *barcode* di kolom pencarian untuk langsung membuka detail produk atau menambahkannya ke transaksi.

### 12.4 Transaksi Stok (`STOCK_IN` & `STOCK_OUT`)
* **FR-12:** `OWNER` dapat mencatat transaksi Barang Masuk (`STOCK_IN`) untuk menambah jumlah stok produk.
* **FR-13:** `OWNER` dapat mencatat transaksi Barang Keluar (`STOCK_OUT`) untuk mengurangi jumlah stok produk.
* **FR-14:** Sistem memvalidasi agar jumlah `STOCK_OUT` tidak melebihi jumlah stok tersedia saat ini (*mencegah stok minus*).
* **FR-15:** `OWNER` dapat memasukkan satu atau lebih item produk sekaligus dalam satu nomor transaksi.
* **FR-16:** Sistem membuat nomor transaksi otomatis dengan format `[BUSINESS_CODE]-[TAHUN]-[NOMOR_URUT]`.
* **FR-17:** Setiap transaksi menyimpan waktu kejadian (`transaction_at`), jenis transaksi, catatan opsional, dan ID pengguna pencatat (`created_by`).

### 12.5 Offline-First & Sinkronisasi
* **FR-18:** Seluruh operasi baca/tulis master produk dan transaksi dijalankan terlebih dahulu pada database lokal Flutter (SQLite/Drift/Isar).
* **FR-19:** Setiap perubahan data lokal ditandai dengan status sinkronisasi (`PENDING`, `SYNCED`, `FAILED`).
* **FR-20:** Aplikasi secara otomatis mengirim antrean data `PENDING` ke server *cloud* saat koneksi internet terdeteksi stabil.

### 12.6 Riwayat Transaksi
* **FR-21:** `OWNER` dapat melihat daftar riwayat transaksi `STOCK_IN` dan `STOCK_OUT` berdasarkan urutan waktu terbaru.
* **FR-22:** `OWNER` dapat memfilter riwayat berdasarkan jenis transaksi (`STOCK_IN` atau `STOCK_OUT`).

---

## 13. Struktur Data

### 13.1 `businesses`
* `id` (UUID, Primary Key)
* `code` (String, Unique)
* `name` (String)
* `business_type` (String — ritel, fnb, grosir, dll.)
* `address` (Text, Nullable)
* `status` (Enum: `ACTIVE`, `INACTIVE`, `SUSPENDED`)
* `created_at`, `updated_at`

### 13.2 `users`
* `id` (UUID, Primary Key)
* `business_id` (UUID, Foreign Key -> `businesses.id`)
* `name` (String)
* `phone` (String, Nullable)
* `email` (String, Nullable)
* `password_hash` (String)
* `role` (Enum: `SUPER_ADMIN`, `OWNER`, `STAFF` — *MVP hanya memakai `OWNER` & `SUPER_ADMIN`*)
* `status` (Enum: `ACTIVE`, `INACTIVE`)
* `last_login_at` (Timestamp)
* `created_at`, `updated_at`

### 13.3 `products`
* `id` (UUID, Primary Key)
* `business_id` (UUID, Foreign Key -> `businesses.id`)
* `sku_barcode` (String, Nullable)
* `name` (String)
* `unit` (String — pcs, dus, kg, pack)
* `cost_price` (Decimal, Default: 0)
* `selling_price` (Decimal, Default: 0)
* `current_stock` (Integer, Default: 0)
* `status` (Enum: `ACTIVE`, `ARCHIVED`)
* `sync_status` (Enum: `PENDING`, `SYNCED`, `FAILED`)
* `created_at`, `updated_at`

### 13.4 `stock_transactions`
* `id` (UUID, Primary Key)
* `business_id` (UUID, Foreign Key -> `businesses.id`)
* `transaction_number` (String)
* `type` (Enum: `STOCK_IN`, `STOCK_OUT`)
* `notes` (Text, Nullable)
* `created_by` (UUID, Foreign Key -> `users.id`)
* `transaction_at` (Timestamp — waktu kejadian di perangkat)
* `sync_status` (Enum: `PENDING`, `SYNCED`, `FAILED`)
* `created_at`, `updated_at`

### 13.5 `stock_transaction_items`
* `id` (UUID, Primary Key)
* `business_id` (UUID, Foreign Key -> `businesses.id`)
* `transaction_id` (UUID, Foreign Key -> `stock_transactions.id`)
* `product_id` (UUID, Foreign Key -> `products.id`)
* `quantity` (Integer)
* `unit_cost_snapshot` (Decimal — harga modal saat transaksi terjadi)
* `created_at`

---

## 14. Status Data

### Status Sinkronisasi (`sync_status`)
* `PENDING` — Data baru dibuat/diubah di perangkat lokal dan menunggu koneksi internet untuk dikirim ke server.
* `SYNCED` — Data telah berhasil tersimpan di server *cloud*.
* `FAILED` — Terjadi kegagalan validasi saat sinkronisasi.

### Status Produk (`status`)
* `ACTIVE` — Produk aktif dan dapat dipilih dalam transaksi.
* `ARCHIVED` — Produk dinonaktifkan (tidak muncul di pilihan transaksi, namun tetap tersimpan untuk menjaga keutuhan riwayat masa lalu).

### Jenis Transaksi (`type`)
* `STOCK_IN` — Penambahan jumlah stok.
* `STOCK_OUT` — Pengurangan jumlah stok.

---

## 15. Prinsip Frontend
Frontend MVP harus berorientasi pada kecepatan pencatatan transaksi di toko/gudang.

**Halaman Utama:**
* Login & Registrasi
* Daftar Produk & Cek Stok (dengan tombol cepat *Scan Barcode*)
* Input Transaksi (`STOCK_IN` & `STOCK_OUT`)
* Riwayat Transaksi
* Profil Bisnis & Pengaturan Akun

---

## 16. Persyaratan Non-Fungsional

### Keamanan & Isolasi Data
* Password pengguna wajib di-*hash* menggunakan algoritma standar industri (Bcrypt/Argon2).
* Setiap permintaan API wajib menyertakan token autentikasi (JWT) yang memuat konteks `business_id`.
* Server backend wajib memvalidasi `business_id` dari token sesi, bukan dari parameter mentah yang dikirim klien.

### Performa
* Pencarian produk dan pemindaian *barcode* pada database lokal harus merespons dalam waktu **kurang dari 0,5 detik**.
* Aplikasi berjalan lancar pada perangkat Android kelas menengah (RAM minimal 3 GB).

### Konsistensi Data
* Pembaruan nilai `current_stock` pada tabel `products` dan pencatatan pada `stock_transaction_items` wajib dieksekusi dalam satu blok transaksi database atomik (*ACID*).
* Proses sinkronisasi dari klien ke server harus bersifat *idempotent* menggunakan UUID yang dibuat di perangkat agar tidak terjadi transaksi ganda saat jaringan tidak stabil.

---

## 17. Aturan Bisnis
1. Stok barang tidak boleh bernilai negatif (`current_stock >= 0`).
2. Produk yang sudah pernah digunakan dalam transaksi tidak boleh dihapus secara permanen (*hard delete*), melainkan diubah statusnya menjadi `ARCHIVED`.
3. Satu kode `sku_barcode` hanya boleh dimiliki oleh satu produk aktif dalam satu bisnis yang sama.
4. Perubahan harga modal pada master produk tidak boleh mengubah catatan nilai historis transaksi yang sudah terjadi sebelumnya (`unit_cost_snapshot`).
5. Bisnis dengan status `INACTIVE` atau `SUSPENDED` tidak dapat melakukan transaksi maupun sinkronisasi baru.

---

## 18. Metrik Keberhasilan

### Metrik Produk
* Rata-rata waktu pencatatan 1 transaksi (mulai dari buka menu hingga simpan) **kurang dari 15 detik**.
* Akurasi pembacaan *barcode* kamera di pencahayaan toko normal mencapai **minimal 95%**.
* Minimal 80% pengguna uji coba dapat menyelesaikan pencatatan produk dan transaksi pertama tanpa panduan manual.

### Metrik Operasional
* **0% kehilangan data** saat pengujian simulasi mode pesawat (*offline*) ke mode *online* sebanyak 100 transaksi beruntun.
* Tingkat keberhasilan sinkronisasi otomatis mencapai **99,5%**.
* **0 insiden** kebocoran data antar-bisnis (`business_id`).

---

## 19. Acceptance Criteria MVP

### Autentikasi & Bisnis
* `OWNER` dapat mendaftar, login, dan logout dengan aman.
* Data produk dan transaksi antar-bisnis tidak saling tercampur.

### Master Produk & Barcode
* `OWNER` dapat menambah produk baru menggunakan pemindai *barcode* kamera maupun input manual.
* Aplikasi menolak penyimpanan jika kode *barcode* sudah terdaftar pada bisnis yang sama.
* Pencarian produk berdasarkan nama atau *barcode* bekerja secara *case-insensitive* dan berjalan tanpa koneksi internet.

### Transaksi & Offline-First
* Transaksi `STOCK_IN` menambah `current_stock` secara akurat.
* Transaksi `STOCK_OUT` mengurangi `current_stock` dan menolak input jika jumlah keluar melebihi stok tersedia.
* Transaksi tetap dapat disimpan saat koneksi internet mati dan otomatis berubah status menjadi `SYNCED` setelah internet aktif kembali.

---

## 20. Risiko dan Mitigasi

| Risiko | Mitigasi |
| :--- | :--- |
| **Barcode rusak atau produk UMKM belum punya barcode** | Sediakan fitur pencarian nama produk yang cepat serta opsi input tanpa *barcode* (opsional). |
| **Kamera HP spesifikasi rendah lambat membaca barcode** | Gunakan library `mobile_scanner` dengan dukungan lampu *flash* kamera dan fokus otomatis. |
| **Duplikasi transaksi saat sinyal putus-nyambung** | Gunakan UUID *idempotent* yang dibuat di klien sehingga server mengabaikan pengiriman ulang yang sama. |
| **Data transaksi hilang jika HP rusak sebelum sinkron** | Tampilkan indikator jumlah data belum tersinkron dan berikan peringatan saat pengguna hendak logout. |

---

## 21. Roadmap Pengembangan

### Fase 1 — MVP (Fondasi & Pencatatan Inti)
* Autentikasi tunggal (`OWNER`) & isolasi multi-business
* Master data produk dasar & *Barcode Scanner* kamera
* Transaksi `STOCK_IN` & `STOCK_OUT`
* Riwayat transaksi dasar
* Penyimpanan *offline-first* & sinkronisasi otomatis ke *cloud*

### Fase 2 — Operasional Tim & Laporan
* Manajemen multi-user (`OWNER` & `STAFF`) dengan pembatasan akses harga modal
* Pengkategorian produk & filter lanjutan
* Dashboard ringkasan (Total SKU, Total Stok, Total Nilai Aset)
* Ekspor laporan stok & transaksi ke CSV/Excel
* Jejak audit aktivitas (`audit_logs`) & indikator status sinkronisasi detail

### Fase 3 — Otomatisasi & Kontrol Stok Lanjutan
* Peringatan stok menipis (*Low Stock Alert*) & batas minimum stok
* *Stock Opname* terpandu & penghitungan selisih otomatis
* Cetak label *barcode* & struk via printer *thermal* Bluetooth
* Manajemen *Supplier* & pembuatan *Purchase Order* (PO)
* Pelacakan *batch* dan tanggal kedaluwarsa (*Expired Date* / FEFO)

### Fase 4 — Ekspansi Bisnis & Ekosistem
* Multi-gudang & multi-cabang
* Transfer stok antar-cabang
* Modul kasir (POS) terintegrasi (Tunai & QRIS)
* Laporan laba-rugi kotor & analisis pergerakan barang (*fast-moving* vs *slow-moving*)

---

## 22. Keputusan Produk

| Keputusan | Status |
| :--- | :--- |
| **Platform Utama** | Mobile App (Android & iOS) menggunakan Flutter |
| **Arsitektur Data** | Offline-First (Local DB + Cloud Sync) |
| **Model SaaS** | Multi-business (Shared database, shared schema berbasis `business_id`) |
| **Fokus MVP** | Autentikasi Owner, Master Produk + Scan Barcode, `STOCK_IN`, `STOCK_OUT`, Riwayat, & Offline Sync |
| **Multi-User (`STAFF`) & Laporan Excel** | Di luar MVP (masuk Fase 2) |
| **Peringatan Stok Menipis** | Di luar MVP (masuk Fase 3) |
| **Multi-Cabang & POS** | Di luar MVP (masuk Fase 4) |

---

## 23. Ringkasan Produk
Dokumen PRD ini menjadi acuan utama pengembangan sistem inventaris UMKM tahap **MVP**. Dengan memfokuskan MVP pada kecepatan pencatatan transaksi, dukungan pemindaian *barcode* via kamera, serta keandalan mode *offline-first*, produk ini dapat segera dibangun dan diuji coba ke pelaku UMKM secara cepat sebelum diperluas ke fitur tim operasional, laporan, dan ekosistem multi-cabang pada fase berikutnya.