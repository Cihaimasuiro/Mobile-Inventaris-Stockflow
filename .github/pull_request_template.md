## Deskripsi Perubahan (PR Description)
<!-- Jelaskan secara ringkas fitur atau perbaikan yang dikerjakan -->

## Jenis Perubahan (Type of Change)
- [ ] `feat`: Penambahan fitur baru sesuai PRD MVP Fase 1
- [ ] `fix`: Perbaikan bug atau penyesuaian fungsionalitas
- [ ] `refactor`: Refaktorisasi kode tanpa mengubah fungsionalitas
- [ ] `perf`: Peningkatan performa (kecepatan operasi lokal / pemindaian barcode)
- [ ] `chore`: Pemeliharaan dependensi / konfigurasi build
- [ ] `test`: Penambahan / pembaruan unit/widget test

## Target Branch
- [ ] Menuju `dev` (Default working branch untuk pengembangan harian)
- [ ] Menuju `main` (Rilis resmi produksi)

## Kesesuaian PRD MVP Fase 1 (PRD Alignment)
- [ ] Fitur berada dalam cakupan MVP Fase 1 (Autentikasi Owner, Master Produk + Scan Barcode, Transaksi Stock In/Out, Riwayat, Offline-first)
- [ ] **TIDAK** menambahkan fitur di luar MVP (tanpa Low Stock Alert, tanpa peran Staf, tanpa ekspor Excel, tanpa POS/thermal printer)
- [ ] Operasi data mendukung **Offline-First** (baca & simpan ke database lokal terlebih dahulu)
- [ ] Mematuhi aturan bisnis: pencegahan stok minus (`current_stock >= 0`), isolasi `business_id`, dan pengarsipan produk (bukan hard delete)

## Checklist Keamanan & Kualitas
- [ ] Kode sudah diuji secara lokal (unit/widget test atau pada emulator/device fisik)
- [ ] Tidak ada file rahasia (`.env`, `.jks`, `.keystore`) yang ter-commit
- [ ] Mengikuti panduan desain `AGENTS.md` (no visual slop, minimalis, dan sesuai Mockup PDF)
- [ ] CI Quality Gate berhasil dijalankan tanpa error

## Tautan Isu Terkait (Related Issues)
Closes #
